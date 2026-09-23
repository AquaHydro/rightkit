import FinderSync
import RightKitCore
import ServiceManagement
import SwiftUI

struct GeneralPane: View {
    @Environment(AppModel.self) private var model
    @State private var confirmingRestart = false

    var body: some View {
        @Bindable var model = model
        Pane {
            Section {
                ExtensionStatusRow(confirmingRestart: $confirmingRestart)
            }

            Section {
                Picker(L("主题"), selection: $model.settings.theme) {
                    Text(L("跟随系统")).tag(Theme.system)
                    Text(L("浅色")).tag(Theme.light)
                    Text(L("深色")).tag(Theme.dark)
                }
                .pickerStyle(.segmented)
                Picker(L("语言"), selection: $model.settings.language) {
                    Text(L("跟随系统")).tag(AppLanguage.system)
                    Text("English").tag(AppLanguage.english)
                    Text("简体中文").tag(AppLanguage.simplifiedChinese)
                }
                .pickerStyle(.segmented)
                Toggle(isOn: $model.settings.launchAtLogin) {
                    Text(L("登录时启动"))
                    Text(L("让 RightKit 随登录运行，右键操作即点即用。"))
                }
                Toggle(L("显示菜单栏图标"), isOn: $model.settings.showMenuBarIcon)
                Toggle(L("在菜单项中显示图标"), isOn: $model.settings.showMenuIcons)
            }

            Section(L("功能")) {
                FeatureGroupToggles()
                Toggle(isOn: $model.settings.confirmPermanentDelete) {
                    Text(L("彻底删除前二次确认"))
                    Text(L("受保护位置的拒绝提示不受这个开关影响。"))
                }
            }

            MonitoredFoldersSection()
        }
        .alert(L("重新启动访达？"), isPresented: $confirmingRestart) {
            Button(L("重新启动")) { FinderControl.restart() }
            Button(L("取消"), role: .cancel) {}
        } message: {
            Text(L("访达会短暂关闭并重新打开。"))
        }
    }
}

/// 五个功能组开关，设置页和菜单栏共用同一组值（F-005、F-006）。
struct FeatureGroupToggles: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Toggle(L("新建文件"), isOn: $model.settings.groups.newFile)
        Toggle(L("剪切和粘贴"), isOn: $model.settings.groups.cutPaste)
        Toggle(L("复制到和移动到"), isOn: $model.settings.groups.copyMove)
        Toggle(L("常用目录"), isOn: $model.settings.groups.favorites)
        Toggle(L("在应用中打开"), isOn: $model.settings.groups.openIn)
    }
}

/// F-001：状态点旁边一定有文字，一个区块最多一个突出按钮。
struct ExtensionStatusRow: View {
    @Environment(AppModel.self) private var model
    @Binding var confirmingRestart: Bool

    var body: some View {
        let status = model.extensionStatus
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(status.isHealthy ? Color.green : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                        .accessibilityHidden(true)
                    Text(status.title).bold()
                }
                Text(status == .backgroundBlocked
                     ? L("请在“系统设置 → 通用 → 登录项与扩展 → 允许在后台”中打开 RightKit。")
                     : L("如果菜单项没有立即出现，请重启一次访达。"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            if status == .disabled || status == .backgroundBlocked {
                Button(L("打开系统设置")) { FinderControl.openSettings(for: status) }
                    .buttonStyle(.borderedProminent)
            } else {
                Button(L("重启访达")) { confirmingRestart = true }
            }
        }
        .animation(.default, value: status)
    }
}

enum FinderControl {
    static func openSettings(for status: ExtensionStatus) {
        if status == .backgroundBlocked {
            SMAppService.openSystemSettingsLoginItems()
        } else {
            FIFinderSyncController.showExtensionManagementInterface()
        }
    }

    /// 结束访达进程，由系统把它重新打开。
    static func restart() {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").forEach { $0.forceTerminate() }
    }
}

/// F-009：监视目录。
struct MonitoredFoldersSection: View {
    @Environment(AppModel.self) private var model
    @State private var rejected: String?

    var body: some View {
        Section {
            ForEach(model.settings.monitoredFolders) { entry in
                FolderRow(entry: entry, showsToggle: false) {
                    model.settings.monitoredFolders.removeAll { $0.id == entry.id }
                }
            }
            if model.settings.monitoredFolders.isEmpty {
                Text(L("没有监视目录，访达菜单不会出现。")).foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text(L("监视目录"))
                Spacer()
                Button(L("添加文件夹…"), action: add)
            }
        } footer: {
            Text(L("RightKit 仅在这些文件夹及其子文件夹的访达菜单中显示。"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .alert(L("无法监视这个文件夹"), isPresented: Binding(get: { rejected != nil }, set: { if !$0 { rejected = nil } })) {
            Button(L("好")) {}
        } message: {
            Text(L("不能添加根目录、系统目录，或个人主目录的上级目录。"))
        }
    }

    private func add() {
        guard let url = Alerts.chooseFolder(prompt: L("添加")) else { return }
        let path = url.path(percentEncoded: false)
        guard PathRules.canMonitor(path, home: FolderStore.home) else { return rejected = path }
        guard !model.settings.monitoredFolders.contains(where: { PathRules.standardized($0.path) == PathRules.standardized(path) }) else { return }
        model.settings.monitoredFolders.append(FolderStore.entry(for: url))
    }
}

/// 文件夹列表的一行：图标、显示名、路径，失效时显示提示。
struct FolderRow: View {
    let entry: FolderEntry
    var showsToggle = true
    var isOn: Binding<Bool>?
    let remove: () -> Void

    var body: some View {
        let refreshed = FolderStore.refreshed(entry)
        let exists = FolderStore.exists(refreshed)
        HStack(spacing: 8) {
            if let isOn, showsToggle {
                Toggle(isOn: isOn) { EmptyView() }.labelsHidden()
            }
            if exists {
                FileIcon(path: refreshed.path)
            } else {
                Image(systemName: "questionmark.folder")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(exists ? FolderStore.displayName(refreshed) : (refreshed.path as NSString).lastPathComponent)
                Text(exists ? refreshed.path : L("该文件夹已不存在。"))
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            Spacer()
            RemoveButton(action: remove)
        }
    }
}
