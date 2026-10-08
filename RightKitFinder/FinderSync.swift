import AppKit
import FinderSync
import os
import RightKitCore

/// 只读当次的菜单快照、组装菜单、把点击交给主程序（technical.md 扩展）。
/// 访达在主线程调用这些方法；设置通知也回到主线程处理。
final class FinderSync: FIFinderSync, @unchecked Sendable {
    private let log = Logger(subsystem: ServiceNames.extensionBundleID, category: "menu")
    private let performance = Logger(subsystem: ServiceNames.extensionBundleID, category: "menu-performance")
    private let renderer = MenuRenderer()
    private lazy var pending = PendingPasteState(url: SharedStore.pendingURL)
    private var menuCount = 0
    private var settings = Settings()
    /// 最近一次菜单的命令和目标快照。访达会复制菜单项，只有 tag 能可靠带回来。
    private var commands: [Command] = []
    private var snapshot: (folder: URL?, items: [URL]) = (nil, [])
    private var prewarm: DispatchWorkItem?

    override init() {
        let start = ProcessInfo.processInfo.systemUptime
        super.init()
        SharedStore.writeHeartbeat()
        // 文件选择面板也会启动扩展实例并写心跳，面板的宿主退出后这个 pid 就失效了。
        // 还活着的实例发现心跳失效就接上，访达里的实例因此不会被误报为未运行（F-001）。
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            if !SharedStore.heartbeatIsAlive() { SharedStore.writeHeartbeat() }
        }
        reloadSettings()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), observer, { _, observer, _, _, _ in
            guard let observer else { return }
            let finderSync = Unmanaged<FinderSync>.fromOpaque(observer).takeUnretainedValue()
            DispatchQueue.main.async { finderSync.reloadSettings() }
        }, ServiceNames.settingsChanged as CFString, nil, .deliverImmediately)
        log.info("Extension started, pid \(ProcessInfo.processInfo.processIdentifier)")
        performance.notice("init_ms=\((ProcessInfo.processInfo.systemUptime - start) * 1000) roots=\(self.settings.activeMonitoredPaths.count)")
    }

    private func reloadSettings() {
        // 读不到设置时按全新安装处理：还没有授权任何文件夹，不注册监视目录（F-080）。
        if case .loaded(let loaded) = SharedStore.loadSettings(backupOnFailure: false) {
            settings = loaded
        } else {
            settings = Settings()
        }
        L10n.setLanguage(settings.language)
        // 不注册 `/`；不存在或需要重新授权的目录不注册。
        let urls = settings.activeMonitoredPaths
            .filter { $0 != "/" && FileManager.default.fileExists(atPath: $0) }
            .map { URL(filePath: $0, directoryHint: .isDirectory) }
        FIFinderSyncController.default().directoryURLs = Set(urls)
        log.notice("Monitoring \(urls.map(\.path).joined(separator: ", "), privacy: .public)")
        schedulePrewarm()
    }

    /// 扩展启动或设置变化后，空闲时在后台搭一遍菜单并丢弃，让系统提前载入图标服务和图标，
    /// 首次右键不再承担这部分开销。用独立的呈现器，不与菜单回调共享缓存。
    private func schedulePrewarm() {
        prewarm?.cancel()
        let settings = settings
        let work = DispatchWorkItem { [performance] in
            guard let root = settings.activeMonitoredPaths.first(where: { $0 != "/" }) else { return }
            let start = ProcessInfo.processInfo.systemUptime
            let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
            let file = SelectedItem(path: (root as NSString).appendingPathComponent("RightKit.txt"), isDirectory: false)
            let renderer = MenuRenderer()
            for input in [MenuInput(location: .items, folder: root, items: [file]), MenuInput(location: .container, folder: root)] {
                _ = renderer.render(MenuBuilder.build(input, settings: settings, environment: Self.environment),
                                    target: nil, action: nil, isDark: isDark)
            }
            performance.notice("prewarm_ms=\((ProcessInfo.processInfo.systemUptime - start) * 1000)")
        }
        prewarm = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    // MARK: 工具栏（F-008）

    override var toolbarItemName: String { "RightKit" }
    override var toolbarItemToolTip: String { "RightKit" }
    override var toolbarItemImage: NSImage {
        NSImage(named: "MenuBarIcon") ?? NSImage(systemSymbolName: "contextualmenu.and.cursorarrow", accessibilityDescription: "RightKit")!
    }

    // MARK: 菜单

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let controller = FIFinderSyncController.default()
        let location: MenuLocation
        switch menuKind {
        case .toolbarItemMenu: location = .toolbar
        case .contextualMenuForContainer: location = .container
        case .contextualMenuForItems, .contextualMenuForSidebar: location = .items
        @unknown default: return nil
        }
        let start = ProcessInfo.processInfo.systemUptime
        menuCount += 1
        // F-008：工具栏完全跳过 Finder 选择、文件元数据和待粘贴列表。
        let folder = location == .toolbar ? nil : controller.targetedURL()
        let items = location == .items ? (controller.selectedItemURLs() ?? []) : []
        snapshot = (folder, items)
        var keys: Set<URLResourceKey> = [.isDirectoryKey]
        if settings.toolbox.contains(where: { $0.enabled && $0.command == .toggleHidden }) { keys.insert(.isHiddenKey) }
        if settings.toolbox.contains(where: { $0.enabled && $0.command == .toggleExtension }) { keys.insert(.hasHiddenExtensionKey) }
        let selected = items.map { Self.selectedItem($0, keys: keys) }
        let metadataEnd = ProcessInfo.processInfo.systemUptime
        // 只有可能显示粘贴的上下文才查询。版本未变时仅做一次 stat，不读 JSON。
        let canPaste = location != .toolbar && settings.groups.cutPaste
            && (selected.isEmpty || (selected.count == 1 && selected[0].isFolder))
        let input = MenuInput(
            location: location,
            folder: folder?.path(percentEncoded: false) ?? "/",
            items: selected,
            hasPendingPaste: canPaste && pending.hasItems()
        )
        let pendingEnd = ProcessInfo.processInfo.systemUptime
        let nodes = MenuBuilder.build(input, settings: settings, environment: Self.environment)
        let rulesEnd = ProcessInfo.processInfo.systemUptime
        commands = []
        var menu: NSMenu?
        if !nodes.isEmpty {
            let result = renderer.render(nodes, target: self, action: #selector(runCommand(_:)),
                                         isDark: UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark")
            commands = result.commands
            menu = result.menu
        }
        let end = ProcessInfo.processInfo.systemUptime
        log.notice("menu kind=\(menuKind.rawValue) folder=\(input.folder, privacy: .public) items=\(items.count) -> \(Self.describe(nodes), privacy: .public)")
        performance.notice("menu first=\(self.menuCount == 1) kind=\(menuKind.rawValue) items=\(items.count) metadata_ms=\((metadataEnd - start) * 1000) pending_ms=\((pendingEnd - metadataEnd) * 1000) rules_ms=\((rulesEnd - pendingEnd) * 1000) presentation_ms=\((end - rulesEnd) * 1000) total_ms=\((end - start) * 1000)")
        return menu
    }

    /// 菜单回调日志：子菜单写成“标题[子项|子项]”，分隔线写成“—”。
    static func describe(_ nodes: [MenuNode]) -> String {
        nodes.map { node in
            if node.content == .separator { return "—" }
            return node.children.isEmpty ? node.title : "\(node.title)[\(describe(node.children))]"
        }.joined(separator: "|")
    }

    @objc private func runCommand(_ sender: NSMenuItem) {
        guard commands.indices.contains(sender.tag) else { return }
        let envelope = CommandEnvelope(command: commands[sender.tag], folder: snapshot.folder, items: snapshot.items)
        log.notice("perform \(envelope.command.action.rawValue, privacy: .public)")
        if envelope.command.presentsUI(settings: settings) { CommandSender.bringMainAppForward() }
        CommandSender.send(envelope)
    }

    private static let environment = MenuEnvironment(
        folderExists: { FileManager.default.fileExists(atPath: $0) },
        displayName: { FileManager.default.displayName(atPath: $0) },
        isAppInstalled: { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) != nil }
    )

    /// 只读元数据，不打开文件。读不到时按 URL 的目录标记处理。
    private static func selectedItem(_ url: URL, keys: Set<URLResourceKey>) -> SelectedItem {
        let values = try? url.resourceValues(forKeys: keys)
        return SelectedItem(
            path: url.path(percentEncoded: false),
            isDirectory: values?.isDirectory ?? url.hasDirectoryPath,
            isHidden: values?.isHidden ?? url.lastPathComponent.hasPrefix("."),
            isExtensionHidden: values?.hasHiddenExtension ?? false
        )
    }
}

/// 把请求交给 agent。agent 不可用时直接打开主程序，由它显示后台服务状态。
enum CommandSender {
    private static let log = Logger(subsystem: ServiceNames.extensionBundleID, category: "xpc")

    static func send(_ envelope: CommandEnvelope) {
        guard let data = try? envelope.encoded() else { return }
        nonisolated(unsafe) let connection = NSXPCConnection(machServiceName: ServiceNames.command)
        connection.remoteObjectInterface = NSXPCInterface(with: AgentXPC.self)
        connection.resume()
        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            log.error("Agent unavailable: \(error.localizedDescription, privacy: .public)")
            connection.invalidate()
            openMainApp()
        } as? AgentXPC
        proxy?.submit(data) { accepted in
            if !accepted { log.error("Request \(envelope.requestID, privacy: .public) was not accepted") }
            connection.invalidate()
        }
    }

    /// 协作式激活下，主程序自己调用 `activate()` 会被拒绝；由扩展经 LaunchServices 打开专用网址来激活它。
    static func bringMainAppForward() {
        NSApp.yieldActivation(toApplicationWithBundleIdentifier: ServiceNames.appBundleID)
        openMainApp(.activate)
    }

    /// 沙盒会丢掉启动参数，所以用网址告诉主程序要打开「通用」页。
    static func openMainApp() {
        openMainApp(.agentUnavailable)
    }

    /// 指定打开扩展所在的主程序包（`RightKit.app/Contents/PlugIns/RightKitFinder.appex`），不交给 LaunchServices 挑选同 scheme 的其他副本。
    private static func openMainApp(_ action: AppURLAction) {
        guard let url = ServiceNames.current.url(for: action) else { return }
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
    }
}
