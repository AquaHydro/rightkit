import AppKit
import RightKitCore

/// 从访达触发的命令没有父窗口，提示和确认都用独立的 `NSAlert`（DESIGN.md 确认对话框）。
@MainActor
enum Alerts {
    static func show(_ message: String, informative: String? = nil, style: NSAlert.Style = .warning) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = message
        alert.informativeText = informative ?? ""
        alert.addButton(withTitle: L("好"))
        run(alert)
    }

    static func showFailure(for action: CommandAction) {
        show(Messages.failure(for: action))
    }

    /// F-073：纯告知，不能继续。
    static func showProtectedLocation() {
        show(L("受保护的位置"), informative: L("系统目录与个人主目录无法通过 RightKit 删除。"))
    }

    /// F-051：没有默认按钮，Esc 取消。
    static func confirmPermanentDelete(_ items: [URL]) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = items.count == 1
            ? L("彻底删除“%@”？", FileManager.default.displayName(atPath: items[0].path(percentEncoded: false)))
            : L("彻底删除 %d 个项目？", items.count)
        alert.informativeText = L("此操作无法撤销。")
        let delete = alert.addButton(withTitle: L("彻底删除"))
        let cancel = alert.addButton(withTitle: L("取消"))
        delete.keyEquivalent = ""
        cancel.keyEquivalent = "\u{1b}"
        return run(alert) == .alertFirstButtonReturn
    }

    /// F-013：去掉首尾空白后为空时保持对话框。
    static func askFileName() -> String? {
        let alert = NSAlert()
        alert.messageText = L("新建文件")
        alert.informativeText = L("输入新文件的名称：")
        let field = NSTextField(string: L("未命名"))
        field.frame = NSRect(x: 0, y: 0, width: 260, height: 24)
        alert.accessoryView = field
        let create = alert.addButton(withTitle: L("创建"))
        alert.addButton(withTitle: L("取消"))
        alert.window.initialFirstResponder = field
        field.selectText(nil)

        let observer = NotificationCenter.default.addObserver(forName: NSControl.textDidChangeNotification, object: field, queue: .main) { _ in
            MainActor.assumeIsolated {
                create.isEnabled = !field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        guard run(alert) == .alertFirstButtonReturn else { return nil }
        return field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @discardableResult
    static func run(_ alert: NSAlert) -> NSApplication.ModalResponse {
        bringToFront()
        alert.window.level = .modalPanel
        return alert.runModal()
    }
}

extension Alerts {
    /// F-053：选择输出格式，默认上次的选择。
    static func chooseImageFormat(for images: [URL], initial: ImageFormat) -> ImageFormat? {
        let alert = NSAlert()
        alert.messageText = images.count == 1
            ? L("转换“%@”", images[0].lastPathComponent)
            : L("转换 %d 张图片", images.count)
        let formats = ImageFormat.allCases
        let control = NSSegmentedControl(labels: formats.map(\.title), trackingMode: .selectOne, target: nil, action: nil)
        control.selectedSegment = formats.firstIndex(of: initial) ?? 0
        control.sizeToFit()
        alert.accessoryView = control
        alert.addButton(withTitle: L("转换"))
        alert.addButton(withTitle: L("取消"))
        guard run(alert) == .alertFirstButtonReturn else { return nil }
        return formats[control.selectedSegment]
    }

    /// 从访达触发时访达仍是前台应用，协作式的 `activate()` 会被拒绝。
    static func bringToFront() {
        NSApp.activate()
    }

    /// 临时选择只供当前操作使用；加入设置列表时由 AppModel 保存长期授权（F-080）。
    static func chooseFolder(prompt: String, startingAt directory: URL? = nil) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = prompt
        panel.directoryURL = directory
        return runPanel(panel)
    }

    static func chooseImage() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.prompt = L("选择")
        return runPanel(panel)
    }

    private static func runPanel(_ panel: NSOpenPanel) -> URL? {
        bringToFront()
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url
    }

    /// F-080：要读写的项目不在任何已授权文件夹内。
    static func showUnauthorized(_ url: URL) {
        show(L("RightKit 无权访问“%@”。", FileManager.default.displayName(atPath: url.path(percentEncoded: false))),
             informative: L("请在设置里把它所在的文件夹加入监视目录；如果那个文件夹显示「需要重新授权。」，点「重新授权…」。"))
    }
}
