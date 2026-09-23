import RightKitCore
import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general, newFile, openIn, favorites, sendTo, toolbox, about
}

/// DESIGN.md 设置窗口：标准 Settings 场景，每个分栏一个 Tab，重新打开时回到上次的分栏。
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("settingsTab") private var tab = SettingsTab.general

    var body: some View {
        TabView(selection: $tab) {
            Tab(L("通用"), systemImage: "gearshape", value: .general) { GeneralPane() }
            Tab(L("新建文件"), systemImage: "doc.badge.plus", value: .newFile) { NewFilePane() }
            Tab(L("在应用中打开"), systemImage: "arrow.up.forward.app", value: .openIn) { OpenInPane() }
            Tab(L("常用目录"), systemImage: "star", value: .favorites) { FoldersPane(kind: .favorites) }
            Tab(L("发送到"), systemImage: "paperplane", value: .sendTo) { FoldersPane(kind: .sendTo) }
            Tab(L("工具箱"), systemImage: "wrench.and.screwdriver", value: .toolbox) { ToolboxPane() }
            Tab(L("关于"), systemImage: "info.circle", value: .about) { AboutPane() }
        }
        // 切换语言后整棵视图用新文案重建。
        .id(model.settings.language)
    }
}

/// 每个分栏共用的外形：分组表单，宽度固定，高度随内容。
struct Pane<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Form { content }
            .formStyle(.grouped)
            .frame(width: 540)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// 行首的文件夹或应用图标。
struct FileIcon: View {
    let path: String

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
            .resizable()
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
    }
}

/// 列表行末尾的移除按钮。
struct RemoveButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "minus.circle")
        }
        .buttonStyle(.borderless)
        .help(L("移除"))
        .accessibilityLabel(L("移除"))
    }
}
