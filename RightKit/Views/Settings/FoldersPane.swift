import RightKitCore
import SwiftUI

/// F-030、F-031：常用目录和发送到是两套独立的列表。
struct FoldersPane: View {
    enum Kind { case favorites, sendTo }

    @Environment(AppModel.self) private var model
    let kind: Kind

    private var entries: Binding<[FolderEntry]> {
        @Bindable var model = model
        return kind == .favorites ? $model.settings.favorites : $model.settings.sendTo
    }

    var body: some View {
        Pane {
            Section {
                ForEach(entries) { $entry in
                    FolderRow(entry: entry, isOn: $entry.enabled) {
                        entries.wrappedValue.removeAll { $0.id == entry.id }
                    }
                }
                .onMove { entries.wrappedValue.move(fromOffsets: $0, toOffset: $1) }
                if entries.wrappedValue.isEmpty {
                    Text(L("还没有文件夹。")).foregroundStyle(.secondary)
                }
            } header: {
                Text(kind == .favorites ? L("常用目录") : L("发送到"))
            } footer: {
                HStack {
                    Text(kind == .favorites
                         ? L("在访达空白处右键，一键打开这些文件夹。")
                         : L("这些文件夹是「复制到」和「移动到」的目标。"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(L("添加文件夹…"), action: add)
                }
            }
        }
        .disabled(kind == .favorites ? !model.settings.groups.favorites : !model.settings.groups.copyMove)
    }

    private func add() {
        guard let url = Alerts.chooseFolder(prompt: L("添加")) else { return }
        let path = PathRules.standardized(url.path(percentEncoded: false))
        guard !entries.wrappedValue.contains(where: { PathRules.standardized($0.path) == path }) else { return }
        entries.wrappedValue.append(FolderStore.entry(for: url))
    }
}
