import AppKit
import os
import RightKitCore
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger(subsystem: ServiceNames.appBundleID, category: "app")
    let model = AppModel()
    let windows = WindowOpener()
    lazy var progress = ProgressCenter(windows: windows)
    let qr = QRModel()
    private lazy var services = ServiceProvider(windows: windows, qr: qr)
    private lazy var router = CommandRouter(model: model, windows: windows, progress: progress)
    private var server: CommandServer?
    private var statusTimer: Timer?
    /// 由登录项或 agent 在后台拉起时不主动开窗口。
    private var launchedInBackground = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        let arguments = ProcessInfo.processInfo.arguments
        let event = NSAppleEventManager.shared().currentAppleEvent
        let asLoginItem = event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        launchedInBackground = asLoginItem || arguments.contains("--background")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppContext.delegate = self
        model.applyAll()
        NSApp.servicesProvider = services
        NSUpdateDynamicServices()
        registerAgent()
        let router = self.router
        let server = CommandServer { router.handle($0) }
        server.onCheckInChange = { [weak self] reachable in self?.model.refreshExtensionStatus(agentReachable: reachable) }
        server.start()
        self.server = server
        refreshStatus()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            MainActor.assumeIsolated { [weak self] in self?.refreshStatus() }
        }

        if ProcessInfo.processInfo.arguments.contains("--agent-unavailable") {
            UserDefaults.standard.set(SettingsTab.general.rawValue, forKey: "settingsTab")
            windows.openSettings()
        } else if !model.settings.welcomeShown {
            windows.open(id: WindowID.welcome)
        } else if !launchedInBackground {
            windows.openSettings()
        }
    }

    /// 用户再次从访达或启动台打开时直接打开设置。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windows.openSettings()
        return false
    }

    /// `rightkit://activate` 只用来让系统把主程序带到前台，不带任何命令。
    func application(_ application: NSApplication, open urls: [URL]) {
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func refreshStatus() {
        model.refreshExtensionStatus(agentReachable: server?.isCheckedIn ?? false)
    }

    /// agent 持有 XPC 服务名；已注册时不重复。
    private func registerAgent() {
        let service = SMAppService.agent(plistName: ServiceNames.agentPlist)
        guard service.status != .enabled else { return }
        do {
            try service.register()
        } catch {
            log.error("Agent registration failed: \(error.localizedDescription, privacy: .public), status \(service.status.rawValue)")
        }
    }
}

/// App Intents 在主程序进程里执行，通过这里拿到状态。
@MainActor
enum AppContext {
    static weak var delegate: AppDelegate?
}
