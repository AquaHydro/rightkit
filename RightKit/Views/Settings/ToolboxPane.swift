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
                        HStack(spacing: 8) {
                            Image(systemName: entry.command.symbol)
                                .frame(width: 22)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text(entry.command.settingsTitle)
                        }
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
