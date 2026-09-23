import Foundation

public enum Theme: String, Codable, CaseIterable, Sendable { case system, light, dark }

public enum AppLanguage: String, Codable, CaseIterable, Sendable { case system, english, simplifiedChinese }

public enum ImageFormat: String, Codable, CaseIterable, Sendable {
    case png, jpeg, heic, tiff

    public var fileExtension: String {
        switch self {
        case .png: "png"
        case .jpeg: "jpg"
        case .heic: "heic"
        case .tiff: "tiff"
        }
    }

    public var title: String { rawValue.uppercased() }
}

/// 设置中可整体开关的五个功能组（F-006）。
public struct FeatureGroups: Codable, Equatable, Sendable {
    public var newFile = true
    public var cutPaste = true
    public var copyMove = true
    public var favorites = true
    public var openIn = true
    public init() {}
}

/// 用户选择的文件夹。`path` 是上次解析 bookmark 得到的路径，扩展只读它。
public struct FolderEntry: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var path: String
    public var bookmark: Data?
    public var enabled = true

    public init(path: String, bookmark: Data? = nil, enabled: Bool = true) {
        self.path = path
        self.bookmark = bookmark
        self.enabled = enabled
    }
}

public struct CustomTemplate: Codable, Equatable, Sendable {
    public var id = UUID()
    /// 菜单名，用户自己写，不翻译。
    public var name: String
    /// 模板副本在应用支持目录里的文件名。
    public var storedFileName: String
    /// 创建时使用的扩展名，可以为空。
    public var fileExtension: String

    public init(name: String, storedFileName: String, fileExtension: String) {
        self.name = name
        self.storedFileName = storedFileName
        self.fileExtension = fileExtension
    }
}

public struct NewItemEntry: Codable, Equatable, Identifiable, Sendable {
    public enum Kind: Codable, Equatable, Sendable {
        case builtin(BuiltinType)
        case custom(CustomTemplate)
    }

    public var kind: Kind
    public var enabled: Bool

    public init(kind: Kind, enabled: Bool) {
        self.kind = kind
        self.enabled = enabled
    }

    public var id: String {
        switch kind {
        case .builtin(let type): "builtin." + type.rawValue
        case .custom(let template): template.id.uuidString
        }
    }

    public var fileExtension: String {
        switch kind {
        case .builtin(let type): type.rawValue
        case .custom(let template): template.fileExtension
        }
    }

    public var title: String {
        switch kind {
        case .builtin(let type): type.title
        case .custom(let template): template.name
        }
    }
}

public enum OpenToolRole: String, Codable, CaseIterable, Sendable { case editor, terminal }

public struct OpenTool: Codable, Equatable, Identifiable, Sendable {
    public var bundleID: String
    public var name: String
    public var role: OpenToolRole
    public var enabled = true
    public var id: String { bundleID }

    public init(bundleID: String, name: String, role: OpenToolRole, enabled: Bool = true) {
        self.bundleID = bundleID
        self.name = name
        self.role = role
        self.enabled = enabled
    }

    /// F-020 内置检测对象。
    public static let known: [OpenTool] = [
        OpenTool(bundleID: "com.apple.Terminal", name: "终端", role: .terminal),
        OpenTool(bundleID: "com.mitchellh.ghostty", name: "Ghostty", role: .terminal),
        OpenTool(bundleID: "com.microsoft.VSCode", name: "Visual Studio Code", role: .editor),
        OpenTool(bundleID: "com.apple.dt.Xcode", name: "Xcode", role: .editor),
    ]
}

public struct ToolboxEntry: Codable, Equatable, Identifiable, Sendable {
    public var command: ToolboxCommand
    public var enabled = true
    public var id: ToolboxCommand { command }

    public init(command: ToolboxCommand, enabled: Bool = true) {
        self.command = command
        self.enabled = enabled
    }
}

public struct Settings: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion = Settings.currentSchemaVersion
    public var theme = Theme.system
    public var language = AppLanguage.system
    public var launchAtLogin = true
    public var showMenuBarIcon = true
    public var showMenuIcons = true
    public var confirmPermanentDelete = true
    public var groups = FeatureGroups()
    public var monitoredFolders: [FolderEntry] = []
    public var newItems: [NewItemEntry] = Settings.defaultNewItems
    public var openAfterCreate = false
    public var askFileName = false
    public var openTools: [OpenTool] = []
    public var openToolsDetected = false
    public var favorites: [FolderEntry] = []
    public var sendTo: [FolderEntry] = []
    public var toolbox: [ToolboxEntry] = Settings.defaultToolbox
    public var welcomeShown = false
    public var lastImageFormat = ImageFormat.png

    public init() {}

    public static let defaultNewItems: [NewItemEntry] = BuiltinType.allCases.map {
        NewItemEntry(kind: .builtin($0), enabled: $0.enabledByDefault)
    }

    public static let defaultToolbox: [ToolboxEntry] = ToolboxCommand.allCases.map { ToolboxEntry(command: $0) }

    /// 首次启动的默认值。`exists` 用来跳过不存在的下载、桌面、文稿。
    public static func makeDefault(home: String, exists: (String) -> Bool) -> Settings {
        var settings = Settings()
        settings.monitoredFolders = [FolderEntry(path: home)]
        let standard = ["Downloads", "Desktop", "Documents"]
            .map { (home as NSString).appendingPathComponent($0) }
            .filter(exists)
        settings.favorites = standard.map { FolderEntry(path: $0) }
        settings.sendTo = standard.map { FolderEntry(path: $0) }
        return settings
    }

    /// 补齐后来新增的内置类型和工具箱命令，保证每项恰好出现一次。
    public func normalized() -> Settings {
        var copy = self
        var seenBuiltins = Set<BuiltinType>()
        copy.newItems = newItems.filter {
            guard case .builtin(let type) = $0.kind else { return true }
            return seenBuiltins.insert(type).inserted
        }
        for type in BuiltinType.allCases where !seenBuiltins.contains(type) {
            copy.newItems.append(NewItemEntry(kind: .builtin(type), enabled: type.enabledByDefault))
        }
        var seenTools = Set<ToolboxCommand>()
        copy.toolbox = toolbox.filter { seenTools.insert($0.command).inserted }
        for command in ToolboxCommand.allCases where !seenTools.contains(command) {
            copy.toolbox.append(ToolboxEntry(command: command))
        }
        return copy
    }

    // MARK: 恢复默认（只影响对应页面）

    /// F-016：内置类型的开关和顺序恢复默认，自定义模板保留在后面，原有相对顺序不变。
    public mutating func resetNewFilePage() {
        let customs = newItems.filter { if case .custom = $0.kind { true } else { false } }
        newItems = Settings.defaultNewItems + customs
        openAfterCreate = false
        askFileName = false
    }

    /// F-040
    public mutating func resetToolboxPage() {
        toolbox = Settings.defaultToolbox
    }
}
