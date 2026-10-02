import AppKit
import RightKitCore

/// F-070、F-071 系统服务。输入是字符串，不改用户的文件和剪贴板。
@MainActor
final class ServiceProvider: NSObject {
    private let windows: WindowOpener
    private let qr: QRModel

    init(windows: WindowOpener, qr: QRModel) {
        self.windows = windows
        self.qr = qr
    }

    @objc func translateWithGoogle(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        translate(pasteboard, with: .google)
    }

    @objc func translateWithBaidu(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        translate(pasteboard, with: .baidu)
    }

    @objc func makeQRCode(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        qr.text = pasteboard.string(forType: .string) ?? ""
        windows.open(id: WindowID.qrCode)
    }

    private func translate(_ pasteboard: NSPasteboard, with service: TranslationService) {
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        Translator.open(text, with: service)
    }
}

enum Translator {
    /// 目标语言跟随应用语言，源语言自动检测。
    @MainActor
    static func open(_ text: String, with service: TranslationService) {
        do {
            let url = try service.url(for: text, language: L10n.language)
            if !NSWorkspace.shared.open(url) { Alerts.show(L("无法打开翻译页面。")) }
        } catch {
            Alerts.show(L("文本过长，无法打开翻译页面。"))
        }
    }
}
