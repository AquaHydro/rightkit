import RightKitCore
import SwiftUI

/// 首次启动的欢迎窗口，单页：Riko、说明、启用访达扩展、菜单栏开关。
struct WelcomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow
    let windows: WindowOpener

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 20) {
            CharacterAvatar(name: "WelcomeCharacter", size: 160)
            VStack(spacing: 8) {
                Text(L("欢迎使用 RightKit"))
                    .font(.largeTitle.weight(.semibold))
                Text(L("在访达里右键，就能新建文件、把项目复制或移动到常用位置、用指定应用打开，以及使用一组文件工具。"))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 380)
            }
            ExtensionStatusCard()
                .padding(12)
                .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
                .frame(width: 400)
            Toggle(L("显示菜单栏图标"), isOn: $model.settings.showMenuBarIcon)
                .toggleStyle(.checkbox)
            HStack(spacing: 12) {
                Button(L("稍后设置")) { finish(openSettings: false) }
                    .controlSize(.large)
                Button(L("开始使用")) { finish(openSettings: true) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .fixedSize()
    }

    private func finish(openSettings: Bool) {
        model.settings.welcomeShown = true
        dismissWindow(id: WindowID.welcome)
        if openSettings { windows.openSettings() }
    }
}
