import RightKitCore
import SwiftUI

/// DESIGN.md 菜单栏菜单：默认菜单样式，不做弹出面板。
struct MenuBarContent: View {
    @Environment(AppModel.self) private var model
    let windows: WindowOpener

    var body: some View {
        Text(model.extensionStatus.title)
        Divider()
        FeatureGroupToggles()
        Divider()
        Button(L("设置…")) { windows.openSettings() }
            .keyboardShortcut(",")
        Button(L("退出 RightKit")) { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
