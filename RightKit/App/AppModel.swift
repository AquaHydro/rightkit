import AppKit
import FinderSync
import Observation
import os
import RightKitCore
import ServiceManagement

/// 扩展状态（F-001），按判断顺序排列。
enum ExtensionStatus: Equatable {
    case disabled, backgroundBlocked, notRunning, enabled

    var title: String {
        switch self {
        case .disabled: L("访达扩展未启用")
        case .backgroundBlocked: L("后台服务已关闭")
        case .notRunning: L("访达扩展未运行")
        case .enabled: L("访达扩展已启用")
        }
    }

    var isHealthy: Bool { self == .enabled }
}

/// 主程序的状态中心：持有设置并负责持久化和系统副作用。
@MainActor @Observable
final class AppModel {
    private let log = Logger(subsystem: ServiceNames.appBundleID, category: "model")
    /// 自动化测试用：不注册登录项。
    static let skipsLoginItem = ProcessInfo.processInfo.environment["RIGHTKIT_SKIP_LOGIN_ITEM"] == "1"

    var settings: Settings {
        didSet {
            guard settings != oldValue else { return }
            persist()
            if settings.language != oldValue.language { L10n.setLanguage(settings.language) }
            if settings.theme != oldValue.theme { applyTheme() }
            if settings.launchAtLogin != oldValue.launchAtLogin { applyLoginItem() }
        }
    }

    private(set) var extensionStatus = ExtensionStatus.notRunning
    private(set) var pendingPaste: [String] = SharedStore.loadPending()
    /// 读到无法识别的设置文件后备份的位置，用来提示一次。
    private(set) var unreadableBackup: URL?

    init() {
        switch SharedStore.loadSettings(backupOnFailure: true) {
        case .loaded(let loaded):
            settings = loaded
        case .missing:
            settings = AppModel.firstLaunchDefaults()
        case .unreadable(let backup):
            settings = AppModel.firstLaunchDefaults()
            unreadableBackup = backup
        }
        L10n.setLanguage(settings.language)
        settings = AppModel.activatingFolders(settings)
        persist()
    }

    /// 全新安装：还没有授权任何文件夹（F-080），常用目录和发送到等第一次授权后再补。
    static func firstLaunchDefaults() -> Settings {
        var settings = Settings()
        settings.openTools = OpenToolDetector.detect(adding: [])
        settings.openToolsDetected = true
        return settings
    }

    // MARK: 文件夹授权（F-080）

    /// 解析全部文件夹的 bookmark 并保持访问。文件夹还在却无法访问的，标为需要重新授权。
    static func activatingFolders(_ settings: Settings) -> Settings {
        func activate(_ entries: [FolderEntry]) -> [FolderEntry] {
            entries.map { entry in
                if let active = FolderAccess.shared.activate(entry) { return active }
                var copy = entry
                copy.needsAuthorization = FolderStore.exists(entry)
                return copy
            }
        }
        var copy = settings
        copy.monitoredFolders = activate(settings.monitoredFolders)
        copy.favorites = activate(settings.favorites)
        copy.sendTo = activate(settings.sendTo)
        return copy
    }

    /// F-009：从文件夹选择面板加入监视目录，同时完成授权。第一次授权后补上默认的常用目录和发送到。
    func addMonitoredFolder(_ url: URL) {
        let path = PathRules.standardized(url.path(percentEncoded: false))
        guard !settings.monitoredFolders.contains(where: { PathRules.standardized($0.path) == path }) else { return }
        var copy = settings
        copy.monitoredFolders.append(authorizedEntry(for: url))
        copy.addStandardFoldersIfNeeded(home: FolderStore.home) { FileManager.default.fileExists(atPath: $0) }
        copy.favorites = activateNew(copy.favorites)
        copy.sendTo = activateNew(copy.sendTo)
        settings = copy
    }

    /// 常用目录和发送到从面板加入，同样完成授权。
    func addFolder(_ url: URL, to list: WritableKeyPath<Settings, [FolderEntry]>) {
        let path = PathRules.standardized(url.path(percentEncoded: false))
        guard !settings[keyPath: list].contains(where: { PathRules.standardized($0.path) == path }) else { return }
        settings[keyPath: list].append(authorizedEntry(for: url))
    }

    /// F-080「重新授权…」：保留原条目的标识和开关，换成新选中的文件夹和 bookmark。
    func reauthorize(_ entry: FolderEntry, in list: WritableKeyPath<Settings, [FolderEntry]>, with url: URL) {
        guard let index = settings[keyPath: list].firstIndex(where: { $0.id == entry.id }) else { return }
        var fresh = authorizedEntry(for: url)
        fresh.id = entry.id
        fresh.enabled = entry.enabled
        settings[keyPath: list][index] = fresh
    }

    private func authorizedEntry(for url: URL) -> FolderEntry {
        FolderAccess.shared.grant(url)
        let entry = FolderStore.entry(for: url)
        return FolderAccess.shared.activate(entry) ?? entry
    }

    /// 补上的默认文件夹还没有 bookmark，此时已在授权文件夹内，可以创建。
    private func activateNew(_ entries: [FolderEntry]) -> [FolderEntry] {
        entries.map { entry in
            guard entry.bookmark == nil else { return entry }
            let made = FolderStore.makeEntry(entry)
            return FolderAccess.shared.activate(made) ?? made
        }
    }

    private func persist() {
        do {
            try SharedStore.save(settings)
        } catch {
            log.error("Settings save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: 系统副作用

    func applyAll() {
        applyTheme()
        applyLoginItem()
    }

    /// F-002：只影响 RightKit 自己的窗口。
    func applyTheme() {
        NSApp.appearance = switch settings.theme {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    func applyLoginItem() {
        guard !AppModel.skipsLoginItem else { return }
        let service = SMAppService.mainApp
        do {
            if settings.launchAtLogin, service.status != .enabled {
                try service.register()
            } else if !settings.launchAtLogin, service.status == .enabled {
                try service.unregister()
            }
        } catch {
            log.error("Login item update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: 扩展状态（F-001）

    func refreshExtensionStatus(agentReachable: Bool) {
        let status: ExtensionStatus
        if !FIFinderSyncController.isExtensionEnabled {
            status = .disabled
        } else if !agentReachable || SMAppService.agent(plistName: ServiceNames.agentPlist).status == .requiresApproval {
            status = .backgroundBlocked
        } else if AppModel.extensionIsRunning() {
            status = .enabled
        } else {
            status = .notRunning
        }
        if status != extensionStatus { extensionStatus = status }
    }

    /// 心跳里记录的进程仍在运行，且确实是扩展进程。
    static func extensionIsRunning() -> Bool {
        guard let beat = SharedStore.readHeartbeat(), beat.pid > 0 else { return false }
        return processName(beat.pid) == "RightKitFinder"
    }

    /// 沙盒拒绝 `proc_name` 和向其他进程发信号，但允许用 sysctl 读进程表。进程不存在时返回 nil。
    static func processName(_ pid: pid_t) -> String? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return withUnsafeBytes(of: info.kp_proc.p_comm) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    // MARK: 待粘贴

    func setPending(_ paths: [String]) {
        do {
            try SharedStore.savePending(paths)
            pendingPaste = paths
        } catch {
            log.error("Pending list save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
