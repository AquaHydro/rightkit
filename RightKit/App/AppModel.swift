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
        persist()
    }

    static func firstLaunchDefaults() -> Settings {
        var settings = Settings.makeDefault(home: FolderStore.home) { FileManager.default.fileExists(atPath: $0) }
        settings.monitoredFolders = settings.monitoredFolders.map(FolderStore.makeEntry)
        settings.favorites = settings.favorites.map(FolderStore.makeEntry)
        settings.sendTo = settings.sendTo.map(FolderStore.makeEntry)
        settings.openTools = OpenToolDetector.detect(adding: [])
        settings.openToolsDetected = true
        return settings
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
        guard let beat = SharedStore.readHeartbeat(), beat.pid > 0, kill(beat.pid, 0) == 0 || errno == EPERM else { return false }
        var name = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard proc_name(beat.pid, &name, UInt32(name.count)) > 0 else { return false }
        return String(decoding: name.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self) == "RightKitFinder"
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
