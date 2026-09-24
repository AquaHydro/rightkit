import RightKitCore
import SwiftUI

/// F-040。
struct ToolboxPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Pane {
            Section {
                ForEach($model.settings.toolbox) { $entry in
                    Toggle(isOn: $entry.enabled) {
                        RowLabel(title: entry.command.settingsTitle, symbol: entry.command.symbol, tint: entry.command.intentTint)
                    }
                }
                .onMove { model.settings.toolbox.move(fromOffsets: $0, toOffset: $1) }
            } header: {
                Text(L("工具箱"))
            } footer: {
                HStack {
                    Text(L("拖动可调整顺序。解散文件夹和彻底删除始终在菜单最后。"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(L("恢复默认")) { model.settings.resetToolboxPage() }
                }
            }
        }
    }
}

extension ToolboxCommand {
    /// 意图分类见 docs/design/menu-system.html。
    var intentTint: Color {
        switch self {
        case .copyPath, .copyName: .intentCopy
        case .newFolderFromName, .convertImage, .macIconset, .iosIconset: .intentCreate
        case .aliasToDesktop, .airDrop: .intentSend
        case .grantWrite, .hash, .toggleHidden, .toggleExtension: .intentInspect
        case .setWallpaper, .setFolderIcon: .intentLook
        case .dissolveFolder, .deletePermanently: .intentDanger
        }
    }
}
