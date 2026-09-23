import AppKit
import os
import RightKitCore

/// 持有 `group.app.rightkit.mac.command`，把扩展的请求转交主程序（technical.md 通信）。
final class Agent: NSObject, NSXPCListenerDelegate, @unchecked Sendable {
    private let log = Logger(subsystem: ServiceNames.agentBundleID, category: "agent")
    // 以下状态只在 queue 上读写。
    private let queue = DispatchQueue(label: "app.rightkit.mac.agent")
    private var app: NSXPCConnection?
    private var waiters: [UUID: @Sendable (NSXPCConnection?) -> Void] = [:]
    private let team = CodeSigning.ownTeamIdentifier()

    /// 主程序在 `Contents/MacOS/RightKitAgent` 的上三级。
    private var appURL: URL {
        Bundle.main.executableURL!.resolvingSymlinksInPath()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        // 签名要求已由监听器检查过，这里只区分来者是扩展还是主程序。
        let role = CodeSigning.identifier(ofProcess: connection.processIdentifier)
        connection.exportedInterface = NSXPCInterface(with: AgentXPC.self)
        switch role {
        case ServiceNames.extensionBundleID: connection.exportedObject = ExtensionSide(agent: self)
        case ServiceNames.appBundleID: connection.exportedObject = AppSide(agent: self)
        default:
            log.error("Rejected connection from \(role ?? "unknown", privacy: .public)")
            return false
        }
        connection.resume()
        return true
    }

    fileprivate func checkIn(_ endpoint: NSXPCListenerEndpoint) -> Bool {
        guard let requirement = CodeSigning.requirement(identifiers: [ServiceNames.appBundleID], team: team) else { return false }
        nonisolated(unsafe) let connection = NSXPCConnection(listenerEndpoint: endpoint)
        connection.remoteObjectInterface = NSXPCInterface(with: AppXPC.self)
        connection.setCodeSigningRequirement(requirement)
        let id = ObjectIdentifier(connection)
        connection.invalidationHandler = { [self] in
            queue.async { if let app = self.app, ObjectIdentifier(app) == id { self.app = nil } }
        }
        connection.resume()
        queue.async {
            self.app?.invalidate()
            self.app = connection
            let waiting = self.waiters
            self.waiters.removeAll()
            waiting.values.forEach { $0(connection) }
        }
        log.info("Main app checked in")
        return true
    }

    fileprivate func submit(_ envelope: Data, reply: @escaping @Sendable (Bool) -> Void) {
        guard envelope.count <= CommandEnvelope.maxEncodedSize else { return reply(false) }
        withApp { connection in
            guard let connection else { return reply(false) }
            let proxy = connection.remoteObjectProxyWithErrorHandler { _ in reply(false) } as? AppXPC
            proxy?.handle(envelope, reply: reply)
        }
    }

    /// 主程序没运行时启动它，最多等 3 秒。
    private func withApp(_ body: @escaping @Sendable (NSXPCConnection?) -> Void) {
        queue.async {
            if let app = self.app { return body(app) }
            // 每个等待者只会被调用一次：签到或超时都会清空列表。
            let isFirstWaiter = self.waiters.isEmpty
            let id = UUID()
            self.waiters[id] = body
            if isFirstWaiter {
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = false
                configuration.arguments = ["--background"]
                NSWorkspace.shared.openApplication(at: self.appURL, configuration: configuration) { _, error in
                    if let error { self.log.error("Launch failed: \(error.localizedDescription, privacy: .public)") }
                }
            }
            self.queue.asyncAfter(deadline: .now() + 3) {
                guard let waiting = self.waiters.removeValue(forKey: id) else { return }
                self.log.error("Main app did not check in within 3 s")
                waiting(nil)
            }
        }
    }
}

private final class ExtensionSide: NSObject, AgentXPC {
    let agent: Agent
    init(agent: Agent) { self.agent = agent }
    func submit(_ envelope: Data, reply: @escaping @Sendable (Bool) -> Void) { agent.submit(envelope, reply: reply) }
    func checkIn(_ endpoint: NSXPCListenerEndpoint, reply: @escaping @Sendable (Bool) -> Void) { reply(false) }
}

private final class AppSide: NSObject, AgentXPC {
    let agent: Agent
    init(agent: Agent) { self.agent = agent }
    func submit(_ envelope: Data, reply: @escaping @Sendable (Bool) -> Void) { reply(false) }
    func checkIn(_ endpoint: NSXPCListenerEndpoint, reply: @escaping @Sendable (Bool) -> Void) { reply(agent.checkIn(endpoint)) }
}

let agent = Agent()
let listener = NSXPCListener(machServiceName: ServiceNames.command)
guard let requirement = CodeSigning.requirement(identifiers: [ServiceNames.extensionBundleID, ServiceNames.appBundleID]) else {
    Logger(subsystem: ServiceNames.agentBundleID, category: "agent").fault("Agent is not signed by a team; refusing to listen")
    exit(1)
}
listener.setConnectionCodeSigningRequirement(requirement)
listener.delegate = agent
listener.resume()
RunLoop.main.run()
