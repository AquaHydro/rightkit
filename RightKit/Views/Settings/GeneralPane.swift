import AppKit
import FinderSync
import RightKitCore
import ServiceManagement
import SwiftUI

struct GeneralPane: View {
    @Environment(AppModel.self) private var model
    @State private var confirmingRestart = false
    #if !APP_STORE
    /// F-081：只有官网版有，存在主程序自己的 UserDefaults 里。
    @AppStorage(UpdateChecker.autoCheckKey) private var autoCheckUpdates = true
    #endif

    var body: some View {
        @Bindable var model = model
        Pane {
            Section {
                ExtensionStatusCard(restart: { confirmingRestart = true })
            }

            MonitoredFoldersSection()

            Section(L("功能")) {
                FeatureGroupToggles(showsIcons: true)
                Toggle(isOn: $model.settings.confirmPermanentDelete) {
                    RowLabel(title: L("彻底删除前二次确认"), caption: L("受保护位置的拒绝提示不受这个开关影响。"),
                             symbol: "exclamationmark.triangle", tint: .intentDanger)
                }
            }

            Section(L("外观")) {
                Picker(selection: $model.settings.theme) {
                    Text(L("跟随系统")).tag(Theme.system)
                    Text(L("浅色")).tag(Theme.light)
                    Text(L("深色")).tag(Theme.dark)
                } label: {
                    RowLabel(title: L("主题"), symbol: "circle.lefthalf.filled", tint: .intentLook)
                }
                Picker(selection: $model.settings.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(verbatim: language.nativeName).tag(language)
                    }
                } label: {
                    RowLabel(title: L("语言"), symbol: "globe", tint: .intentGo)
                }
                Toggle(isOn: $model.settings.showMenuIcons) {
                    RowLabel(title: L("在菜单项中显示图标"), symbol: "photo", tint: .intentLook)
                }
            }

            Section(L("启动与菜单栏")) {
                Toggle(isOn: $model.settings.launchAtLogin) {
                    RowLabel(title: L("登录时启动"), caption: L("让 RightKit 随登录运行，右键操作即点即用。"),
                             symbol: "power", tint: .intentCreate)
                }
                Toggle(isOn: $model.settings.showMenuBarIcon) {
                    RowLabel(title: L("显示菜单栏图标"), symbol: "menubar.rectangle", tint: .intentInspect)
                }
                #if !APP_STORE
                Toggle(isOn: $autoCheckUpdates) {
                    RowLabel(title: L("自动检查更新"), caption: L("有新版本时提醒你，并打开下载页面。"),
                             symbol: "arrow.down.circle", tint: .intentGo)
                }
                #endif
            }
        }
        #if APP_STORE
        // 商店版不能用 Apple Events 让访达退出（审核 2.4.5(i) 不给临时例外），只说明手动重启的方法。
        .alert(L("重新启动访达"), isPresented: $confirmingRestart) {
            Button(L("好")) {}
        } message: {
            Text(L("按住 Option 键右键点按程序坞中的访达，选择“重新开启”。"))
        }
        #else
        .alert(L("重新启动访达？"), isPresented: $confirmingRestart) {
            Button(L("重新启动")) {
                Task {
                    let restarted = await FinderControl.restart()
                    guard !restarted else { return }
                    Alerts.show(L("无法重新启动访达。"),
                                informative: L("请在“系统设置 → 隐私与安全性 → 自动化”中允许 RightKit 控制访达，或按住 Option 键右键点按程序坞中的访达，选择“重新开启”。"))
                }
            }
            Button(L("取消"), role: .cancel) {}
        } message: {
            Text(L("访达会短暂关闭并重新打开。"))
        }
        #endif
    }
}

/// 五个功能组开关，设置页和菜单栏共用同一组值（F-005、F-006）。菜单栏菜单里不带图标块。
struct FeatureGroupToggles: View {
    @Environment(AppModel.self) private var model
    var showsIcons = false

    var body: some View {
        @Bindable var model = model
        toggle(L("新建文件"), "doc.badge.plus", .intentCreate, $model.settings.groups.newFile)
        toggle(L("剪切和粘贴"), "scissors", .intentSend, $model.settings.groups.cutPaste)
        toggle(L("复制到和移动到"), "arrow.forward.folder", .intentSend, $model.settings.groups.copyMove)
        toggle(L("常用目录"), "star", .intentGo, $model.settings.groups.favorites)
        toggle(L("在应用中打开"), "arrow.up.forward.app", .intentGo, $model.settings.groups.openIn)
    }

    @ViewBuilder
    private func toggle(_ title: String, _ symbol: String, _ tint: Color, _ isOn: Binding<Bool>) -> some View {
        if showsIcons {
            Toggle(isOn: isOn) { RowLabel(title: title, symbol: symbol, tint: tint) }
        } else {
            Toggle(title, isOn: isOn)
        }
    }
}

extension ExtensionStatus {
    var caption: String {
        switch self {
        case .disabled: L("在“系统设置 → 通用 → 登录项与扩展”中打开 RightKit 的访达扩展，右键菜单才会出现。")
        case .backgroundBlocked: L("请在“系统设置 → 通用 → 登录项与扩展 → 允许在后台”中打开 RightKit。")
        case .notRunning: L("重启一次访达，菜单就会出现。")
        case .enabled: L("一切就绪，去访达里右键试试。")
        }
    }

    /// Riko 的表情头像，见 docs/design/brand-character.md 第 6 条。
    var avatar: String {
        switch self {
        case .enabled: "StatusReady"
        case .notRunning: "StatusSleepy"
        case .disabled, .backgroundBlocked: "StatusPuzzled"
        }
    }

    var needsSystemSettings: Bool { self == .disabled || self == .backgroundBlocked }
}

/// F-001：扩展状态卡片，设置「通用」页和欢迎窗口共用。
/// 头像只是辅助，状态永远有文字；一个区块最多一个突出按钮。
struct ExtensionStatusCard: View {
    @Environment(AppModel.self) private var model
    /// 为 nil 时不提供重启访达（欢迎窗口），系统设置按钮也改为普通样式，突出样式留给「开始使用」。
    var restart: (() -> Void)?

    var body: some View {
        let status = model.extensionStatus
        HStack(spacing: 12) {
            CharacterAvatar(name: status.avatar, size: 56)
                .id(status.avatar)
                .transition(.opacity)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.title).font(.headline)
                Text(status.caption)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            if status.needsSystemSettings {
                if restart == nil {
                    Button(L("打开系统设置")) { FinderControl.openSettings(for: status) }
                } else {
                    Button(L("打开系统设置")) { FinderControl.openSettings(for: status) }
                        .buttonStyle(.borderedProminent)
                }
            } else if let restart {
                Button(L("重启访达"), action: restart)
            }
        }
        // Status may stay unchanged while the language changes in another window.
        .id(model.settings.language)
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

    #if !APP_STORE
    private static let finderID = "com.apple.finder"

    /// F-001：请访达正常退出，等它退出后重新打开。退出靠 Apple Event，需要只针对访达的临时例外；
    /// 沙盒会拦截 `forceTerminate()` 的信号。用户拒绝自动化授权或访达没有退出时返回 false。
    @MainActor
    static func restart() async -> Bool {
        guard let finder = NSRunningApplication.runningApplications(withBundleIdentifier: finderID).first else {
            return await launchFinder()
        }
        // 先问清自动化授权。第一次会弹系统询问，阻塞到用户回答，所以放到后台。
        let permission = await Task.detached { () -> OSStatus in
            let target = NSAppleEventDescriptor(bundleIdentifier: finderID)
            guard let address = target.aeDesc else { return OSStatus(errAEEventNotPermitted) }
            return AEDeterminePermissionToAutomateTarget(address, AEEventClass(kCoreEventClass), AEEventID(kAEQuitApplication), true)
        }.value
        guard permission == OSStatus(noErr) else { return false }
        guard finder.terminate() else { return false }
        for _ in 0..<50 where !finder.isTerminated {
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard finder.isTerminated else { return false }
        return await launchFinder()
    }

    @MainActor
    private static func launchFinder() async -> Bool {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: finderID) else { return false }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        return (try? await NSWorkspace.shared.openApplication(at: url, configuration: configuration)) != nil
    }
    #endif
}

/// F-009：监视目录。
struct MonitoredFoldersSection: View {
    @Environment(AppModel.self) private var model
    @State private var rejected: String?

    var body: some View {
        Section {
            ForEach(model.settings.monitoredFolders) { entry in
                FolderRow(entry: entry, showsToggle: false, reauthorize: { reauthorize(entry) }) {
                    model.settings.monitoredFolders.removeAll { $0.id == entry.id }
                }
            }
            if model.settings.monitoredFolders.isEmpty {
                HStack(spacing: 16) {
                    Image("EmptyFolders").accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("没有监视目录，访达菜单不会出现。")).font(.headline)
                        Button(L("添加文件夹…"), action: add)
                    }
                }
                .padding(.vertical, 4)
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
        model.addMonitoredFolder(url)
    }

    /// F-080：面板停在原来的位置，重新选中后替换这一行。
    private func reauthorize(_ entry: FolderEntry) {
        guard let url = Alerts.chooseFolder(prompt: L("授权"), startingAt: URL(filePath: entry.path, directoryHint: .isDirectory)) else { return }
        let path = url.path(percentEncoded: false)
        guard PathRules.canMonitor(path, home: FolderStore.home) else { return rejected = path }
        model.reauthorize(entry, in: \.monitoredFolders, with: url)
    }
}

/// 文件夹列表的一行：图标、显示名、路径，失效或需要重新授权时显示提示。
struct FolderRow: View {
    let entry: FolderEntry
    var showsToggle = true
    var isOn: Binding<Bool>?
    /// F-080：需要重新授权时显示「重新授权…」。
    var reauthorize: (() -> Void)?
    let remove: () -> Void

    var body: some View {
        let refreshed = FolderStore.refreshed(entry)
        let state = FolderStore.state(refreshed)
        let exists = state == .available
        let needsAuthorization = state == .needsAuthorization
        let title = exists ? FolderStore.displayName(refreshed) : (refreshed.path as NSString).lastPathComponent
        HStack(spacing: 12) {
            if let isOn, showsToggle {
                Toggle(isOn: isOn) { EmptyView() }
                    .labelsHidden()
                    .accessibilityLabel(title)
            }
            if exists, !needsAuthorization {
                FileIcon(path: refreshed.path)
            } else {
                RowIcon(symbol: "questionmark.folder", tint: .intentInspect)
            }
            RowLabel(title: title,
                     caption: needsAuthorization ? L("需要重新授权。") : !exists ? L("该文件夹已不存在。") : refreshed.path,
                     monospacedCaption: exists && !needsAuthorization)
                .textSelection(.enabled)
            Spacer()
            if needsAuthorization, let reauthorize {
                Button(L("重新授权…"), action: reauthorize)
            }
            RemoveButton(itemName: title, action: remove)
        }
    }
}
