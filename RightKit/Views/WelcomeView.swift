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
            // 立绘自带图标底色，裁成圆形。
            Image("WelcomeCharacter")
                .resizable()
                .frame(width: 160, height: 160)
                .background(Color.brandInk)
                .clipShape(.circle)
                // 圆形底部是白色外套，浅色窗口里靠发丝线画出边界。
                .overlay(Circle().strokeBorder(.separator))
                .accessibilityLabel(L("RightKit 角色"))
            VStack(spacing: 8) {
                Text(L("欢迎使用 RightKit"))
                    .font(.largeTitle.weight(.semibold))
                Text(L("在访达里右键，就能新建文件、把项目复制或移动到常用位置、用指定应用打开，以及使用一组文件工具。"))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 380)
            }
            WelcomeExtensionStep()
                .frame(width: 380)
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

/// F-005：欢迎窗口里的扩展状态。状态每 3 秒刷新，用户在系统设置里打开扩展后这里直接变绿。
private struct WelcomeExtensionStep: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let status = model.extensionStatus
        let needsSettings = status == .disabled || status == .backgroundBlocked
        HStack(spacing: 12) {
            Image(systemName: status.isHealthy ? "checkmark.circle.fill" : "puzzlepiece.extension")
                .font(.title2)
                .foregroundStyle(status.isHealthy ? Color.green : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.title).font(.headline)
                Text(caption(status))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            if needsSettings {
                Button(L("打开系统设置")) { FinderControl.openSettings(for: status) }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
        .animation(.default, value: status)
    }

    private func caption(_ status: ExtensionStatus) -> String {
        switch status {
        case .disabled: L("在“系统设置 → 通用 → 登录项与扩展”中打开 RightKit 的访达扩展，右键菜单才会出现。")
        case .backgroundBlocked: L("请在“系统设置 → 通用 → 登录项与扩展 → 允许在后台”中打开 RightKit。")
        case .notRunning: L("如果菜单项没有立即出现，请重启一次访达。")
        case .enabled: L("现在就可以在访达里右键试试。")
        }
    }
}

extension Color {
    /// 品牌炭灰，只用于图标和欢迎窗口的角色底（DESIGN.md `ink`）。
    static let brandInk = Color(red: 0x2A / 255, green: 0x2B / 255, blue: 0x31 / 255)
}
