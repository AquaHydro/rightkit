import Foundation
import os
import RightKitCore

/// App Group 里的共享文件：设置、待粘贴列表和扩展心跳。主程序写设置，扩展只读。
enum SharedStore {
    static let log = Logger(subsystem: ServiceNames.appBundleID, category: "store")

    /// 测试用 `RIGHTKIT_SETTINGS_DIR` 指向临时目录，避免碰到真实设置。
    static let directory: URL = {
        if let custom = ProcessInfo.processInfo.environment["RIGHTKIT_SETTINGS_DIR"], !custom.isEmpty {
            return URL(filePath: custom, directoryHint: .isDirectory)
        }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ServiceNames.appGroup)
            ?? URL.applicationSupportDirectory.appending(path: ServiceNames.appGroup)
    }()

    static var settingsURL: URL { directory.appending(path: "settings.json") }
    static var pendingURL: URL { directory.appending(path: "pending.json") }
    static var heartbeatURL: URL { directory.appending(path: "heartbeat.json") }

    enum LoadResult {
        case loaded(Settings)
        case missing
        /// 文件存在但无法识别，已备份到 `backup`。
        case unreadable(backup: URL?)
    }

    /// `backupOnFailure` 只有主程序传 true，扩展不改文件。
    static func loadSettings(backupOnFailure: Bool) -> LoadResult {
        guard let data = try? Data(contentsOf: settingsURL) else {
            return FileManager.default.fileExists(atPath: settingsURL.path) ? .unreadable(backup: nil) : .missing
        }
        if let settings = try? JSONDecoder().decode(Settings.self, from: data),
           settings.schemaVersion == Settings.currentSchemaVersion {
            return .loaded(settings.normalized())
        }
        guard backupOnFailure else { return .unreadable(backup: nil) }
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backup = directory.appending(path: "settings.unreadable-\(stamp).json")
        do {
            try FileManager.default.moveItem(at: settingsURL, to: backup)
            log.error("Unreadable settings moved to \(backup.path, privacy: .public)")
            return .unreadable(backup: backup)
        } catch {
            log.error("Could not back up unreadable settings: \(error.localizedDescription, privacy: .public)")
            return .unreadable(backup: nil)
        }
    }

    static func save(_ settings: Settings) throws {
        try write(settings, to: settingsURL)
        postSettingsChanged()
    }

    // MARK: 待粘贴（F-033）

    static func loadPending() -> [String] {
        guard let data = try? Data(contentsOf: pendingURL) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    static func savePending(_ paths: [String]) throws {
        try write(paths, to: pendingURL)
    }

    // MARK: 心跳（F-001）

    struct Heartbeat: Codable {
        var pid: Int32
        var date: Date
    }

    static func writeHeartbeat() {
        do {
            try write(Heartbeat(pid: ProcessInfo.processInfo.processIdentifier, date: Date()), to: heartbeatURL)
        } catch {
            log.error("Heartbeat write failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func readHeartbeat() -> Heartbeat? {
        guard let data = try? Data(contentsOf: heartbeatURL) else { return nil }
        return try? JSONDecoder().decode(Heartbeat.self, from: data)
    }

    // MARK: 设置变化提醒

    static func postSettingsChanged() {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             CFNotificationName(ServiceNames.settingsChanged as CFString), nil, nil, true)
    }

    private static func write(_ value: some Encodable, to url: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: url, options: .atomic)
    }
}
