import RightKitCore
import SwiftUI

/// F-040：按访达菜单的五个分组分节，分组内拖动排序。
struct ToolboxPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Pane {
            ForEach(1...5, id: \.self) { group in
                Section {
                    ForEach($model.settings.toolbox.filter { $0.wrappedValue.command.group == group }) { $entry in
                        Toggle(isOn: $entry.enabled) {
                            RowLabel(title: entry.command.settingsTitle, symbol: entry.command.symbol, tint: entry.command.intentTint)
                        }
                    }
                    .onMove { move(in: group, from: $0, to: $1) }
                } header: {
                    Text(ToolboxCommand.groupTitle(group))
                } footer: {
                    if group == 5 {
                        HStack {
                            Text(L("拖动可在分组内调整顺序。"))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(L("恢复默认")) { model.settings.resetToolboxPage() }
                        }
                    }
                }
            }
        }
    }

    /// 只在一个分组内移动，整个列表按分组重排，访达菜单的分隔线因此和设置里的分节一致。
    private func move(in group: Int, from source: IndexSet, to destination: Int) {
        let toolbox = model.settings.toolbox
        var moved = toolbox.filter { $0.command.group == group }
        moved.move(fromOffsets: source, toOffset: destination)
        model.settings.toolbox = (1...5).flatMap { g in g == group ? moved : toolbox.filter { $0.command.group == g } }
    }
}

extension ToolboxCommand {
    static func groupTitle(_ group: Int) -> String {
        switch group {
        case 1: L("拷贝")
        case 2: L("文件")
        case 3: L("显示与隐藏")
        case 4: L("图片与图标")
        default: L("解散与删除")
        }
    }

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
