import RightKitCore
import SwiftUI

/// F-030、F-031：常用目录和发送到放在同一页，是两套独立的列表。
struct FoldersPane: View {
    var body: some View {
        Pane {
            FolderListSection(kind: .favorites)
            FolderListSection(kind: .sendTo)
        }
    }
}

private struct FolderListSection: View {
    enum Kind { case favorites, sendTo }

    @Environment(AppModel.self) private var model
    let kind: Kind

    private var list: WritableKeyPath<RightKitCore.Settings, [FolderEntry]> {
        kind == .favorites ? \.favorites : \.sendTo
    }

    private var entries: Binding<[FolderEntry]> {
        @Bindable var model = model
        return kind == .favorites ? $model.settings.favorites : $model.settings.sendTo
    }

    var body: some View {
        Section {
            ForEach(entries) { $entry in
                FolderRow(entry: entry, isOn: $entry.enabled, reauthorize: { reauthorize(entry) }) {
                    entries.wrappedValue.removeAll { $0.id == entry.id }
                }
            }
            .onMove { entries.wrappedValue.move(fromOffsets: $0, toOffset: $1) }
            if entries.wrappedValue.isEmpty {
                Text(L("还没有文件夹。")).foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text(kind == .favorites ? L("常用目录") : L("发送到"))
                Spacer()
                Button(L("添加文件夹…"), action: add)
            }
        } footer: {
            Text(kind == .favorites
                 ? L("在访达空白处右键，一键打开这些文件夹。")
                 : L("这些文件夹是「复制到」和「移动到」的目标。"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .disabled(kind == .favorites ? !model.settings.groups.favorites : !model.settings.groups.copyMove)
    }

    private func add() {
        guard let url = Alerts.chooseFolder(prompt: L("添加")) else { return }
        model.addFolder(url, to: list)
    }

    /// F-080：面板停在原来的位置，重新选中后替换这一行。
    private func reauthorize(_ entry: FolderEntry) {
        guard let url = Alerts.chooseFolder(prompt: L("授权"), startingAt: URL(filePath: entry.path, directoryHint: .isDirectory)) else { return }
        model.reauthorize(entry, in: list, with: url)
    }
}
