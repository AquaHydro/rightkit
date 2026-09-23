import Foundation
import os
import RightKitCore

/// 主程序的匿名 XPC 监听。启动后把 endpoint 交给 agent，只接受 agent 的连接。
final class CommandServer: NSObject, NSXPCListenerDelegate, AppXPC, @unchecked Sendable {
    private let log = Logger(subsystem: ServiceNames.appBundleID, category: "xpc")
    private let listener = NSXPCListener.anonymous()
    private let lock = NSLock()
    private var agent: NSXPCConnection?
    private var deduplicator = RequestDeduplicator()
    private let onRequest: @MainActor @Sendable (ValidatedRequest) -> Void

    /// agent 是否已收下 endpoint。
    @MainActor private(set) var isCheckedIn = false
    @MainActor var onCheckInChange: ((Bool) -> Void)?

    init(onRequest: @escaping @MainActor @Sendable (ValidatedRequest) -> Void) {
        self.onRequest = onRequest
        super.init()
    }

    func start() {
        guard let requirement = CodeSigning.requirement(identifiers: [ServiceNames.agentBundleID]) else {
            log.fault("Not signed by a team; command server disabled")
            return
        }
        listener.setConnectionCodeSigningRequirement(requirement)
        listener.delegate = self
        listener.resume()
        checkIn()
    }

    /// 连接 agent 并签到。agent 被 launchd 按需拉起；断开后稍后重试。
    func checkIn() {
        let connection = NSXPCConnection(machServiceName: ServiceNames.command)
        connection.remoteObjectInterface = NSXPCInterface(with: AgentXPC.self)
        if let requirement = CodeSigning.requirement(identifiers: [ServiceNames.agentBundleID]) {
            connection.setCodeSigningRequirement(requirement)
        }
        connection.invalidationHandler = { [weak self] in
            self?.log.error("Agent connection invalidated")
            self?.setCheckedIn(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self?.checkIn() }
        }
        connection.interruptionHandler = { [weak self] in
            // agent 重启过，需要重新交出 endpoint。
            self?.setCheckedIn(false)
            self?.sendEndpoint(over: connection)
        }
        connection.resume()
        lock.withLock {
            agent?.invalidationHandler = nil
            agent?.invalidate()
            agent = connection
        }
        sendEndpoint(over: connection)
    }

    private func sendEndpoint(over connection: NSXPCConnection) {
        let proxy = connection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.log.error("Check-in failed: \(error.localizedDescription, privacy: .public)")
        } as? AgentXPC
        proxy?.checkIn(listener.endpoint) { [weak self] accepted in
            self?.log.info("Checked in with agent: \(accepted)")
            self?.setCheckedIn(accepted)
        }
    }

    private func setCheckedIn(_ value: Bool) {
        Task { @MainActor in
            isCheckedIn = value
            onCheckInChange?(value)
        }
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: AppXPC.self)
        connection.exportedObject = self
        connection.resume()
        return true
    }

    func handle(_ envelope: Data, reply: @escaping @Sendable (Bool) -> Void) {
        let request: ValidatedRequest
        do {
            request = try CommandEnvelope.validate(envelope)
        } catch {
            log.error("Rejected request: \(String(describing: error), privacy: .public)")
            reply(false)
            // 能认出动作时，显示该动作自己的失败提示。
            if let action = try? JSONDecoder().decode(CommandEnvelope.self, from: envelope).command.action {
                Task { @MainActor in Alerts.showFailure(for: action) }
            }
            return
        }
        guard lock.withLock({ deduplicator.accept(request.id) }) else {
            log.info("Duplicate request \(request.id, privacy: .public) ignored")
            return reply(true)
        }
        reply(true)
        let onRequest = self.onRequest
        Task { @MainActor in onRequest(request) }
    }
}
