import AppKit
import FinderSync
import os
import RightKitCore
import UniformTypeIdentifiers

/// 只读当次的菜单快照、组装菜单、把点击交给主程序（technical.md 扩展）。
/// 访达在主线程调用这些方法；设置通知也回到主线程处理。
final class FinderSync: FIFinderSync, @unchecked Sendable {
    private let log = Logger(subsystem: ServiceNames.extensionBundleID, category: "menu")
    private var settings = Settings()
    /// 最近一次菜单的命令和目标快照。访达会复制菜单项，只有 tag 能可靠带回来。
    private var commands: [Command] = []
    private var snapshot: (folder: URL?, items: [URL]) = (nil, [])

    override init() {
        super.init()
        SharedStore.writeHeartbeat()
        reloadSettings()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), observer, { _, observer, _, _, _ in
            guard let observer else { return }
            let finderSync = Unmanaged<FinderSync>.fromOpaque(observer).takeUnretainedValue()
            DispatchQueue.main.async { finderSync.reloadSettings() }
        }, ServiceNames.settingsChanged as CFString, nil, .deliverImmediately)
        log.info("Extension started, pid \(ProcessInfo.processInfo.processIdentifier)")
    }

    private func reloadSettings() {
        if case .loaded(let loaded) = SharedStore.loadSettings(backupOnFailure: false) {
            settings = loaded
        } else {
            settings = Settings.makeDefault(home: Self.home) { FileManager.default.fileExists(atPath: $0) }
        }
        L10n.setLanguage(settings.language)
        // 不注册 `/`；不存在的目录不注册。
        let urls = settings.monitoredFolders
            .map(\.path)
            .filter { $0 != "/" && FileManager.default.fileExists(atPath: $0) }
            .map { URL(filePath: $0, directoryHint: .isDirectory) }
        FIFinderSyncController.default().directoryURLs = Set(urls)
        log.notice("Monitoring \(urls.map(\.path).joined(separator: ", "), privacy: .public)")
    }

    /// 沙盒里 `NSHomeDirectory()` 是容器目录，要取真实主目录。
    static let home: String = {
        guard let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir else { return NSHomeDirectory() }
        return String(cString: dir)
    }()

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
        let folder = controller.targetedURL()
        let items = location == .items ? (controller.selectedItemURLs() ?? []) : []
        snapshot = (location == .toolbar ? nil : folder, items)

        let input = MenuInput(
            location: location,
            folder: folder?.path(percentEncoded: false) ?? "/",
            items: items.map(Self.selectedItem),
            hasPendingPaste: !SharedStore.loadPending().isEmpty
        )
        let nodes = MenuBuilder.build(input, settings: settings, environment: Self.environment)
        commands = []
        log.notice("menu kind=\(menuKind.rawValue) folder=\(input.folder, privacy: .public) items=\(items.count) -> \(Self.describe(nodes), privacy: .public)")
        guard !nodes.isEmpty else { return nil }
        let menu = NSMenu(title: "")
        nodes.forEach { menu.addItem(makeItem($0)) }
        return menu
    }

    /// 菜单回调日志：子菜单写成“标题[子项|子项]”，分隔线写成“—”。
    static func describe(_ nodes: [MenuNode]) -> String {
        nodes.map { node in
            if node.content == .separator { return "—" }
            return node.children.isEmpty ? node.title : "\(node.title)[\(describe(node.children))]"
        }.joined(separator: "|")
    }

    private func makeItem(_ node: MenuNode) -> NSMenuItem {
        if node.content == .separator { return .separator() }
        let item = NSMenuItem(title: node.title, action: nil, keyEquivalent: "")
        switch node.icon {
        case .symbol(let name): item.image = NSImage(systemSymbolName: name, accessibilityDescription: nil).map(Self.menuSymbol)
        case .app(let bundleID):
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                item.image = Self.menuSized(NSWorkspace.shared.icon(forFile: url.path))
            }
        case .fileType(let ext):
            item.image = Self.menuSized(NSWorkspace.shared.icon(for: UTType(filenameExtension: ext) ?? .data))
        case .file(let path):
            item.image = Self.menuSized(NSWorkspace.shared.icon(forFile: path))
        case nil: break
        }
        switch node.content {
        case .command(let command):
            item.action = #selector(runCommand(_:))
            item.target = self
            item.tag = commands.count
            commands.append(command)
        case .submenu(let children):
            let submenu = NSMenu(title: node.title)
            children.forEach { submenu.addItem(makeItem($0)) }
            item.submenu = submenu
        case .separator: break
        }
        return item
    }

    /// 访达收到的 SF Symbol 会被压成不带模板标记的黑色位图，深色模式下看不清。
    /// 这里先按当前系统外观涂成菜单文字色，再标记为模板：访达认模板时由它着色（含高亮行），不认时颜色也已经对了。
    /// 外观读全局 `AppleInterfaceStyle`，扩展进程自己的 `effectiveAppearance` 可能停在启动时的外观。
    private static func menuSymbol(_ symbol: NSImage) -> NSImage {
        let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        let size = symbol.size
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return symbol }
        rep.size = size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let rect = NSRect(origin: .zero, size: size)
        symbol.draw(in: rect)
        NSColor(white: isDark ? 1 : 0, alpha: 0.85).set()
        rect.fill(using: .sourceAtop)
        NSGraphicsContext.restoreGraphicsState()
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        image.isTemplate = true
        return image
    }

    /// 彩色图标统一缩到菜单的 16 pt，和 SF Symbol 对齐。
    private static func menuSized(_ icon: NSImage) -> NSImage {
        icon.size = NSSize(width: 16, height: 16)
        return icon
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
    private static func selectedItem(_ url: URL) -> SelectedItem {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey, .hasHiddenExtensionKey])
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
        guard let url = URL(string: "rightkit://activate") else { return }
        NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration())
    }

    /// 扩展在 `RightKit.app/Contents/PlugIns/RightKitFinder.appex`。
    static func openMainApp() {
        let appURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = ["--agent-unavailable"]
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
    }
}
