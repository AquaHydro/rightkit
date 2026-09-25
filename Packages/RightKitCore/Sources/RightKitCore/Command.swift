import Foundation

public enum CommandAction: String, Codable, CaseIterable, Sendable {
    case openSettings, paste, newFile, openFolder, openIn, copyCurrentPath, cut, copyTo, moveTo
    case copyPath, copyName, newFolderFromName, aliasToDesktop, airDrop, grantWrite, hash
    case toggleHidden, toggleExtension, convertImage, macIconset, iosIconset, setWallpaper, setFolderIcon
    case dissolveFolder, deletePermanently

    public init(_ tool: ToolboxCommand) {
        self.init(rawValue: tool.rawValue)!
    }
}

/// 菜单项携带的命令。`argument` 是模板、应用或文件夹的标识；复制到、移动到为 nil 时表示“选择文件夹…”。
public struct Command: Codable, Equatable, Hashable, Sendable {
    public var action: CommandAction
    public var argument: String?

    public init(_ action: CommandAction, _ argument: String? = nil) {
        self.action = action
        self.argument = argument
    }
}

/// 扩展发给主程序的请求信封。
public struct CommandEnvelope: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let maxEncodedSize = 1 << 20
    public static let maxAge: TimeInterval = 30

    public var schemaVersion = CommandEnvelope.currentSchemaVersion
    public var requestID = UUID()
    public var sentAt = Date()
    public var command: Command
    /// 当前文件夹的 file URL 字符串。
    public var folder: String?
    /// 选中项的 file URL 字符串。
    public var items: [String]

    public init(command: Command, folder: URL?, items: [URL], sentAt: Date = Date()) {
        self.command = command
        self.folder = folder?.absoluteString
        self.items = items.map(\.absoluteString)
        self.sentAt = sentAt
    }

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
}

public enum EnvelopeError: Error, Equatable, Sendable {
    case tooLarge, malformed, unsupportedVersion, expired, invalidURL
}

/// 通过校验的请求：URL 都是绝对、规范化的文件 URL。
public struct ValidatedRequest: Equatable, Sendable {
    public var id: UUID
    public var command: Command
    public var folder: URL?
    public var items: [URL]
}

public extension CommandEnvelope {
    /// 先检查大小、版本和时间，再解码 URL。不受信任的数据不直接当路径用。
    static func validate(_ data: Data, now: Date = Date()) throws(EnvelopeError) -> ValidatedRequest {
        guard data.count <= maxEncodedSize else { throw .tooLarge }
        guard let envelope = try? JSONDecoder().decode(CommandEnvelope.self, from: data) else { throw .malformed }
        guard envelope.schemaVersion == currentSchemaVersion else { throw .unsupportedVersion }
        let age = now.timeIntervalSince(envelope.sentAt)
        guard age <= maxAge, age >= -5 else { throw .expired }
        let folder = try envelope.folder.map { (s) throws(EnvelopeError) in try fileURL(s) }
        var items: [URL] = []
        for item in envelope.items { items.append(try fileURL(item)) }
        return ValidatedRequest(id: envelope.requestID, command: envelope.command, folder: folder, items: items)
    }

    private static func fileURL(_ string: String) throws(EnvelopeError) -> URL {
        guard let url = URL(string: string), url.isFileURL, url.host() == nil || url.host() == "localhost" else {
            throw .invalidURL
        }
        let path = url.path(percentEncoded: false)
        guard path.hasPrefix("/"), !path.contains("\0"),
              !path.split(separator: "/").contains(where: { $0 == ".." }) else { throw .invalidURL }
        return URL(filePath: PathRules.standardized(path), directoryHint: url.hasDirectoryPath ? .isDirectory : .notDirectory)
    }
}

/// 记住最近的请求 ID，重复的忽略（technical.md 通信）。
public struct RequestDeduplicator: Sendable {
    private var seen: [UUID: Date] = [:]
    public init() {}

    /// 第一次见到返回 true。
    public mutating func accept(_ id: UUID, now: Date = Date()) -> Bool {
        seen = seen.filter { now.timeIntervalSince($0.value) < CommandEnvelope.maxAge * 2 }
        return seen.updateValue(now, forKey: id) == nil
    }
}

/// 一个发布渠道的全部标识（technical.md 发布渠道与标识）。只由主程序 bundle ID、App Group 和网址 scheme 推出，不写死。
public struct ChannelIdentifiers: Equatable, Sendable {
    public static let appBundleIDKey = "RKAppBundleID"
    public static let appGroupKey = "RKAppGroup"
    public static let urlSchemeKey = "RKURLScheme"

    public let appBundleID: String
    public let appGroup: String
    public let urlScheme: String

    public init(appBundleID: String, appGroup: String, urlScheme: String) {
        self.appBundleID = appBundleID
        self.appGroup = appGroup
        self.urlScheme = urlScheme
    }

    /// 从 Info.plist 读取。缺少任何一项都返回 nil。
    public init?(infoDictionary info: [String: Any]) {
        guard let app = info[Self.appBundleIDKey] as? String, !app.isEmpty,
              let group = info[Self.appGroupKey] as? String, !group.isEmpty,
              let scheme = info[Self.urlSchemeKey] as? String, !scheme.isEmpty
        else { return nil }
        self.init(appBundleID: app, appGroup: group, urlScheme: scheme)
    }

    public var extensionBundleID: String { appBundleID + ".finder" }
    public var agentBundleID: String { appBundleID + ".agent" }
    /// agent 的 launchd 配置在主程序包 `Contents/Library/LaunchAgents` 里的文件名。
    public var agentPlist: String { agentBundleID + ".plist" }
    /// XPC 服务名必须是 App Group 的直接子名，沙盒里的扩展才能查找。
    public var command: String { appGroup + ".command" }
    public var settingsChanged: String { appGroup + ".settings" }
    /// 只用来让系统把主程序带到前台，不带任何命令。
    public var activationURL: URL? { URL(string: urlScheme + "://activate") }
}

/// 当前进程所属渠道的标识。主程序、扩展和 agent 的 Info.plist 都带这三项。
public enum ServiceNames {
    public static let current: ChannelIdentifiers = {
        guard let identifiers = ChannelIdentifiers(infoDictionary: Bundle.main.infoDictionary ?? [:]) else {
            fatalError("Info.plist lacks \(ChannelIdentifiers.appBundleIDKey), \(ChannelIdentifiers.appGroupKey) or \(ChannelIdentifiers.urlSchemeKey)")
        }
        return identifiers
    }()

    public static var appGroup: String { current.appGroup }
    public static var command: String { current.command }
    public static var settingsChanged: String { current.settingsChanged }
    public static var appBundleID: String { current.appBundleID }
    public static var extensionBundleID: String { current.extensionBundleID }
    public static var agentBundleID: String { current.agentBundleID }
    public static var agentPlist: String { current.agentPlist }
    public static var activationURL: URL? { current.activationURL }
}

/// agent 对外的 XPC 接口。扩展调用 `submit`，主程序调用 `checkIn`。
@objc public protocol AgentXPC {
    func submit(_ envelope: Data, reply: @escaping @Sendable (Bool) -> Void)
    func checkIn(_ endpoint: NSXPCListenerEndpoint, reply: @escaping @Sendable (Bool) -> Void)
}

/// 主程序匿名监听的接口，只接受 agent。
@objc public protocol AppXPC {
    func handle(_ envelope: Data, reply: @escaping @Sendable (Bool) -> Void)
}

public extension Command {
    /// 会弹出窗口或对话框的命令。扩展先请系统把主程序带到前台，否则访达仍在前台，对话框拿不到键盘焦点。
    func presentsUI(settings: Settings) -> Bool {
        switch action {
        case .openSettings, .hash, .convertImage, .airDrop, .setFolderIcon: true
        case .newFile: settings.askFileName
        case .copyTo, .moveTo: argument == nil
        case .deletePermanently: settings.confirmPermanentDelete
        default: false
        }
    }
}
