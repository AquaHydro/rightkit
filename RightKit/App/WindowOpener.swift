import AppKit
import SwiftUI

/// SwiftUI 的 `openWindow` 只能从视图环境里拿到。
/// 应用启动时放一个看不见的桥接窗口，取到后供 AppKit 一侧（XPC、菜单栏、重新打开）调用。
@MainActor @Observable
final class WindowOpener {
    fileprivate var openWindowAction: OpenWindowAction?
    private var pending: [() -> Void] = []

    func openSettings() {
        open(id: WindowID.settings)
    }

    func open(id: String) {
        perform { [weak self] in
            NSApp.activate()
            self?.openWindowAction?(id: id)
        }
    }

    func open<Value: Codable & Hashable>(id: String, value: Value) {
        perform { [weak self] in
            NSApp.activate()
            self?.openWindowAction?(id: id, value: value)
        }
    }

    private func perform(_ body: @escaping () -> Void) {
        if openWindowAction == nil { pending.append(body) } else { body() }
    }

    fileprivate func bridgeReady() {
        let queued = pending
        pending.removeAll()
        queued.forEach { $0() }
    }
}

struct WindowBridge: View {
    let opener: WindowOpener
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onAppear {
                opener.openWindowAction = openWindow
                // 桥接窗口本身不显示。
                DispatchQueue.main.async {
                    for window in NSApp.windows where window.identifier?.rawValue.contains(WindowID.bridge) == true {
                        window.orderOut(nil)
                    }
                    opener.bridgeReady()
                }
            }
    }
}

enum WindowID {
    static let bridge = "rightkit-bridge"
    static let settings = "settings"
    static let welcome = "welcome"
    static let hash = "hash"
    static let qrCode = "qrcode"
    static let progress = "progress"
}
