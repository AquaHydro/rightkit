import RightKitCore
import SwiftUI

@main
struct RightKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("RightKit", id: WindowID.bridge) {
            WindowBridge(opener: delegate.windows)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)

        Window("RightKit", id: WindowID.settings) {
            SettingsView()
                .environment(delegate.model)
        }
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(.suppressed)

        MenuBarExtra(isInserted: Bindable(delegate.model).settings.showMenuBarIcon) {
            MenuBarContent(windows: delegate.windows)
                .environment(delegate.model)
        } label: {
            Image("MenuBarIcon")
                .accessibilityLabel("RightKit")
        }

        Window(L("欢迎使用 RightKit"), id: WindowID.welcome) {
            WelcomeView(windows: delegate.windows)
                .environment(delegate.model)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(.suppressed)

        WindowGroup(L("文件信息"), id: WindowID.hash, for: URL.self) { $url in
            if let url { HashView(url: url).navigationTitle(url.lastPathComponent) }
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(.suppressed)

        Window(L("二维码"), id: WindowID.qrCode) {
            QRCodeView().environment(delegate.qr)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(.suppressed)

        WindowGroup(L("进度"), id: WindowID.progress, for: UUID.self) { $id in
            if let id { ProgressWindowView(id: id).environment(delegate.progress) }
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(.suppressed)
    }
}
