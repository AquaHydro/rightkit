import Foundation
import UniformTypeIdentifiers

/// 访达当前选中的一项。只包含扩展能从快照和元数据得到的信息。
public struct SelectedItem: Equatable, Sendable {
    public var path: String
    public var isDirectory: Bool
    public var isHidden: Bool
    public var isExtensionHidden: Bool

    public init(path: String, isDirectory: Bool, isHidden: Bool = false, isExtensionHidden: Bool = false) {
        self.path = path
        self.isDirectory = isDirectory
        self.isHidden = isHidden
        self.isExtensionHidden = isExtensionHidden
    }

    /// 包和应用程序按文件对待，不能解散（F-050）。
    public var isPackage: Bool {
        let ext = (path as NSString).pathExtension
        guard isDirectory, !ext.isEmpty, let type = UTType(filenameExtension: ext, conformingTo: .package) else { return false }
        // 未登记的扩展名（如 “v1.2”）会得到动态类型，这种按普通文件夹处理。
        return !type.isDynamic && type.conforms(to: .package)
    }
    public var isFolder: Bool { isDirectory && !isPackage }
    public var isFile: Bool { !isFolder }
    public var isImage: Bool { !isDirectory && (UTType.forPath(path)?.conforms(to: .image) ?? false) }
}

public enum MenuLocation: Equatable, Sendable {
    /// 空白处右键。
    case container
    /// 选中项目后右键。
    case items
    /// 访达工具栏按钮。
    case toolbar
}

public struct MenuInput: Equatable, Sendable {
    public var location: MenuLocation
    /// 当前文件夹。
    public var folder: String
    public var items: [SelectedItem]
    public var hasPendingPaste: Bool

    public init(location: MenuLocation, folder: String, items: [SelectedItem] = [], hasPendingPaste: Bool = false) {
        self.location = location
        self.folder = folder
        self.items = items
        self.hasPendingPaste = hasPendingPaste
    }
}

/// 构建菜单时需要的外部事实，扩展提供真实实现，测试提供假的。
public struct MenuEnvironment: Sendable {
    public var folderExists: @Sendable (String) -> Bool
    public var displayName: @Sendable (String) -> String
    public var isAppInstalled: @Sendable (String) -> Bool

    public init(
        folderExists: @escaping @Sendable (String) -> Bool,
        displayName: @escaping @Sendable (String) -> String = { ($0 as NSString).lastPathComponent },
        isAppInstalled: @escaping @Sendable (String) -> Bool
    ) {
        self.folderExists = folderExists
        self.displayName = displayName
        self.isAppInstalled = isAppInstalled
    }
}

/// 菜单项指向具体事物（应用、文档类型、文件夹）时用它的真实彩色图标，抽象动作用 SF Symbol。
public enum MenuIcon: Equatable, Sendable {
    case symbol(String)
    case app(bundleID: String)
    /// 该扩展名的文档图标，由默认打开它的应用提供（如 Word、Excel）。
    case fileType(extension: String)
    /// 文件夹在访达里的图标，包括下载、桌面等特殊文件夹和自定义图标。
    case file(path: String)
}

public struct MenuNode: Equatable, Sendable {
    public enum Content: Equatable, Sendable {
        case command(Command)
        case submenu([MenuNode])
        case separator
    }

    public var title: String
    public var icon: MenuIcon?
    public var content: Content

    public static let separator = MenuNode(title: "", icon: nil, content: .separator)

    public var command: Command? { if case .command(let c) = content { c } else { nil } }
    public var children: [MenuNode] { if case .submenu(let c) = content { c } else { [] } }
}

public enum MenuBuilder {
    public static func build(_ input: MenuInput, settings: Settings, environment env: MenuEnvironment) -> [MenuNode] {
        let nodes = buildNodes(input, settings: settings, environment: env)
        return settings.showMenuIcons ? nodes : nodes.map(stripIcons)
    }

    static func buildNodes(_ input: MenuInput, settings: Settings, environment env: MenuEnvironment) -> [MenuNode] {
        // F-008：工具栏只放设置，不看当前文件夹和选择。
        if input.location == .toolbar {
            return [leaf(L("设置…"), "gearshape", Command(.openSettings))]
        }
        var nodes: [MenuNode] = []

        // F-060：只在监视目录及其子目录出现。
        let monitored = PathRules.MonitoringScope(settings.activeMonitoredPaths)
        if input.location == .items && !input.items.isEmpty {
            guard input.items.allSatisfy({ monitored.contains($0.path) }) else { return [] }
        } else {
            guard monitored.contains(input.folder) else { return [] }
        }

        let items = input.location == .items ? input.items : []
        let isNone = items.isEmpty
        let isOneFolder = items.count == 1 && items[0].isFolder
        let groups = settings.groups

        if groups.cutPaste, input.hasPendingPaste, isNone || isOneFolder {
            nodes.append(leaf(L("粘贴"), "doc.on.clipboard", Command(.paste)))
        }
        if groups.newFile, isNone || isOneFolder {
            let children = settings.newItems.filter(\.enabled).map { item in
                MenuNode(title: item.title + (settings.askFileName ? "…" : ""), icon: .fileType(extension: item.fileExtension), content: .command(Command(.newFile, item.id)))
            }
            if !children.isEmpty { nodes.append(submenu(L("新建文件"), "doc.badge.plus", children)) }
        }
        if groups.favorites, isNone {
            let children = folderTargets(settings.favorites, env).map { folderLeaf($0, Command(.openFolder, $0.entry.id.uuidString)) }
            if !children.isEmpty { nodes.append(submenu(L("常用目录"), "star", children)) }
        }
        if groups.openIn {
            let children = settings.openTools.filter { $0.enabled && env.isAppInstalled($0.bundleID) }.map {
                MenuNode(title: $0.name, icon: .app(bundleID: $0.bundleID), content: .command(Command(.openIn, $0.bundleID)))
            }
            if !children.isEmpty { nodes.append(submenu(L("在应用中打开"), "arrow.up.forward.app", children)) }
        }
        if isNone, enabledTools(settings).contains(.copyPath) {
            nodes.append(leaf(L("拷贝当前路径"), ToolboxCommand.copyPath.symbol, Command(.copyCurrentPath)))
        }
        guard !isNone else { return nodes }

        if groups.cutPaste {
            nodes.append(leaf(L("剪切"), "scissors", Command(.cut)))
        }
        if groups.copyMove {
            let targets = folderTargets(settings.sendTo, env)
            func transfer(_ title: String, _ symbol: String, _ action: CommandAction) -> MenuNode {
                var children = targets.map { folderLeaf($0, Command(action, $0.entry.id.uuidString)) }
                if !children.isEmpty { children.append(.separator) }
                children.append(leaf(L("选择文件夹…"), "folder.badge.questionmark", Command(action)))
                return submenu(title, symbol, children)
            }
            nodes.append(transfer(L("复制到"), "plus.rectangle.on.folder", .copyTo))
            nodes.append(transfer(L("移动到"), "arrow.forward.folder", .moveTo))
        }
        let toolbox = toolboxNodes(items, settings: settings)
        if !toolbox.isEmpty { nodes.append(submenu(L("工具箱"), "wrench.and.screwdriver", toolbox)) }
        return nodes
    }

    /// 已开启的工具箱命令，危险分组固定排在最后（F-040）。
    static func enabledTools(_ settings: Settings) -> [ToolboxCommand] {
        let enabled = settings.toolbox.filter(\.enabled).map(\.command)
        return enabled.filter { !$0.isDangerous } + enabled.filter(\.isDangerous)
    }

    static func toolboxNodes(_ items: [SelectedItem], settings: Settings) -> [MenuNode] {
        let tools = enabledTools(settings)
        guard !tools.isEmpty else { return [] }
        var nodes: [MenuNode] = []
        var lastGroup: Int?
        let selection = SelectionSummary(items)
        for tool in tools where selection.applies(tool) {
            if let lastGroup, lastGroup != tool.group { nodes.append(.separator) }
            lastGroup = tool.group
            nodes.append(leaf(title(of: tool, items: items, settings: settings), tool.symbol, Command(CommandAction(tool))))
        }
        return nodes
    }

    /// 工具箱内部的上下文匹配表（features.md）。
    public static func applies(_ tool: ToolboxCommand, to items: [SelectedItem]) -> Bool {
        SelectionSummary(items).applies(tool)
    }

    private struct SelectionSummary {
        let count: Int
        let files: Int
        let folders: Int
        let images: Int

        init(_ items: [SelectedItem]) {
            count = items.count
            var files = 0, folders = 0, images = 0
            for item in items {
                if item.isFolder { folders += 1 } else { files += 1 }
                if item.isImage { images += 1 }
            }
            self.files = files
            self.folders = folders
            self.images = images
        }

        func applies(_ tool: ToolboxCommand) -> Bool {
            guard count > 0 else { return false }
            switch tool {
            case .copyPath, .copyName, .aliasToDesktop, .airDrop, .grantWrite, .toggleHidden, .deletePermanently:
                return true
            case .newFolderFromName, .hash, .toggleExtension:
                return files > 0
            case .convertImage, .macIconset, .iosIconset:
                return images > 0
            case .setWallpaper:
                return count == 1 && images == 1
            case .setFolderIcon:
                return (count == 1 && (folders == 1 || images == 1)) || (count == 2 && folders == 1 && images == 1)
            case .dissolveFolder:
                return folders == count
            }
        }
    }

    static func title(of tool: ToolboxCommand, items: [SelectedItem], settings: Settings) -> String {
        switch tool {
        case .copyPath: L("拷贝路径")
        case .copyName: L("拷贝名称")
        case .newFolderFromName: L("根据文件名新建文件夹")
        case .aliasToDesktop: L("发送替身到桌面")
        case .airDrop: L("隔空投送")
        case .grantWrite: L("授予写入权限")
        case .hash: L("文件信息（哈希）…")
        case .toggleHidden:
            switch toggleState(items.map(\.isHidden)) {
            case true: L("显示所选")
            case false: L("隐藏所选")
            case nil: L("隐藏/显示所选")
            }
        case .toggleExtension:
            switch toggleState(items.filter(\.isFile).map(\.isExtensionHidden)) {
            case true: L("显示扩展名")
            case false: L("隐藏扩展名")
            case nil: L("隐藏/显示扩展名")
            }
        case .convertImage: L("转换图片…")
        case .macIconset: L("生成 macOS 图标集")
        case .iosIconset: L("生成 iOS 图标集")
        case .setWallpaper: L("设为壁纸")
        case .setFolderIcon: items.count == 2 ? L("设置文件夹图标") : L("设置文件夹图标…")
        case .dissolveFolder: L("解散文件夹")
        case .deletePermanently: settings.confirmPermanentDelete ? L("彻底删除…") : L("彻底删除")
        }
    }

    /// 全部为真返回 true，全部为假返回 false，混合返回 nil。
    static func toggleState(_ values: [Bool]) -> Bool? {
        if values.allSatisfy({ $0 }) { return true }
        if values.allSatisfy({ !$0 }) { return false }
        return nil
    }

    private struct FolderTarget {
        let entry: FolderEntry
        let title: String
    }

    private static func folderTargets(_ entries: [FolderEntry], _ env: MenuEnvironment) -> [FolderTarget] {
        var existence: [String: Bool] = [:]
        var names: [String: String] = [:]
        var targets: [FolderTarget] = []
        for entry in entries where entry.enabled {
            let exists = existence[entry.path] ?? env.folderExists(entry.path)
            existence[entry.path] = exists
            guard exists else { continue }
            let title = names[entry.path] ?? env.displayName(entry.path)
            names[entry.path] = title
            targets.append(FolderTarget(entry: entry, title: title))
        }
        return targets
    }

    static func leaf(_ title: String, _ symbol: String, _ command: Command) -> MenuNode {
        MenuNode(title: title, icon: .symbol(symbol), content: .command(command))
    }

    private static func folderLeaf(_ target: FolderTarget, _ command: Command) -> MenuNode {
        MenuNode(title: target.title, icon: .file(path: target.entry.path), content: .command(command))
    }

    static func submenu(_ title: String, _ symbol: String, _ children: [MenuNode]) -> MenuNode {
        MenuNode(title: title, icon: .symbol(symbol), content: .submenu(children))
    }

    static func stripIcons(_ node: MenuNode) -> MenuNode {
        var copy = node
        copy.icon = nil
        if case .submenu(let children) = node.content { copy.content = .submenu(children.map(stripIcons)) }
        return copy
    }
}
