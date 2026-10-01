import Foundation
import Testing
@testable import RightKitCore

/// V-050：features.md 两张菜单表的每一格。
@Suite struct MenuTests {
    let home = "/Users/tester"
    var settings: Settings
    let env = MenuEnvironment(folderExists: { !$0.hasSuffix("Gone") }, isAppInstalled: { $0 != "com.microsoft.VSCode" })

    init() {
        settings = Settings.afterAuthorizing(home: "/Users/tester") { _ in true }
        settings.openTools = OpenTool.known
        settings.sendTo.append(FolderEntry(path: "/Users/tester/Gone"))
    }

    func folder(_ name: String) -> SelectedItem { SelectedItem(path: "\(home)/\(name)", isDirectory: true) }
    func file(_ name: String) -> SelectedItem { SelectedItem(path: "\(home)/\(name)", isDirectory: false) }

    func menu(_ location: MenuLocation, _ items: [SelectedItem] = [], pending: Bool = false, folder: String? = nil, settings: Settings? = nil) -> [MenuNode] {
        let language = L10n.override ?? .simplifiedChinese
        return L10n.$override.withValue(language) { build(location, items, pending, folder, settings) }
    }

    private func build(_ location: MenuLocation, _ items: [SelectedItem], _ pending: Bool, _ folder: String?, _ settings: Settings?) -> [MenuNode] {
        MenuBuilder.build(MenuInput(location: location, folder: folder ?? home, items: items, hasPendingPaste: pending),
                          settings: settings ?? self.settings, environment: env)
    }

    func titles(_ nodes: [MenuNode]) -> [String] { nodes.map { $0.content == .separator ? "—" : $0.title } }
    func toolbox(_ nodes: [MenuNode]) -> [String] { titles(nodes.first { $0.title == "工具箱" }?.children ?? []) }

    // MARK: 顶层表

    @Test func noSelection() {
        #expect(titles(menu(.container)) == ["新建文件", "常用目录", "在应用中打开", "拷贝当前路径"])
        #expect(titles(menu(.container, pending: true)) == ["粘贴", "新建文件", "常用目录", "在应用中打开", "拷贝当前路径"])
        #expect(titles(menu(.items, [])) == titles(menu(.container)), "空选择按无选择处理")
        #expect(menu(.container).last?.command == Command(.copyCurrentPath))
    }

    @Test func oneFolder() {
        let nodes = menu(.items, [folder("A")], pending: true)
        #expect(titles(nodes) == ["粘贴", "新建文件", "在应用中打开", "剪切", "复制到", "移动到", "工具箱"])
        #expect(!titles(menu(.items, [folder("A")])).contains("粘贴"))
    }

    @Test func plainFile() {
        let nodes = menu(.items, [file("a.txt")], pending: true)
        #expect(titles(nodes) == ["在应用中打开", "剪切", "复制到", "移动到", "工具箱"])
    }

    @Test func image() {
        #expect(titles(menu(.items, [file("a.png")], pending: true)) == ["在应用中打开", "剪切", "复制到", "移动到", "工具箱"])
    }

    @Test func multipleFoldersAndMixed() {
        let expected = ["在应用中打开", "剪切", "复制到", "移动到", "工具箱"]
        #expect(titles(menu(.items, [folder("A"), folder("B")], pending: true)) == expected)
        #expect(titles(menu(.items, [folder("A"), file("b.txt")], pending: true)) == expected)
    }

    @Test func packageCountsAsFile() {
        #expect(!titles(menu(.items, [folder("Foo.app")])).contains("新建文件"))
        #expect(!toolbox(menu(.items, [folder("Foo.app")])).contains("解散文件夹"))
    }

    @Test func outsideMonitoredHasNoMenu() {
        #expect(menu(.container, folder: "/Volumes/Other").isEmpty)
        #expect(menu(.items, [SelectedItem(path: "/tmp/a", isDirectory: false)]).isEmpty)
        var s = settings
        s.monitoredFolders.append(FolderEntry(path: "/Volumes/Other"))
        #expect(!menu(.container, folder: "/Volumes/Other/sub", settings: s).isEmpty)
        s.monitoredFolders = []
        #expect(menu(.container, settings: s).isEmpty, "移除主目录后不显示")
    }

    @Test func foldersNeedingAuthorizationHaveNoMenu() {
        var s = settings
        s.monitoredFolders[0].needsAuthorization = true
        #expect(menu(.container, settings: s).isEmpty, "F-080：需要重新授权的目录不注册")
        #expect(menu(.items, [file("a.txt")], settings: s).isEmpty)
    }

    @Test func toolbarOnlyHasSettings() {
        #expect(titles(menu(.toolbar, [file("a.txt")], folder: "/elsewhere")) == ["设置…"])
    }

    @Test func groupsOff() {
        var s = settings
        s.groups.newFile = false
        s.groups.favorites = false
        s.groups.openIn = false
        s.groups.cutPaste = false
        s.groups.copyMove = false
        #expect(titles(menu(.container, pending: true, settings: s)) == ["拷贝当前路径"])
        #expect(titles(menu(.items, [file("a.txt")], settings: s)) == ["工具箱"])
    }

    @Test func commandsOff() {
        var s = settings
        for i in s.toolbox.indices { s.toolbox[i].enabled = false }
        #expect(!titles(menu(.container, settings: s)).contains("拷贝当前路径"))
        #expect(!titles(menu(.items, [file("a.txt")], settings: s)).contains("工具箱"), "没有可用命令时不显示工具箱")
        s.toolbox[s.toolbox.firstIndex { $0.command == .hash }!].enabled = true
        #expect(toolbox(menu(.items, [file("a.txt")], settings: s)) == ["文件信息（哈希）…"])
        #expect(!titles(menu(.items, [folder("A")], settings: s)).contains("工具箱"))
    }

    @Test func submenuContents() {
        let root = menu(.container)
        #expect(titles(root[0].children) == ["文本文档", "Markdown", "RTF 文稿", "Word 文档", "Excel 工作簿", "PowerPoint 演示文稿"])
        #expect(titles(root[1].children) == ["Downloads", "Desktop", "Documents"])
        #expect(titles(root[2].children) == ["终端", "Ghostty", "Xcode"], "未安装的应用不列出")
        let copyTo = menu(.items, [file("a")]).first { $0.title == "复制到" }!.children
        #expect(titles(copyTo) == ["Downloads", "Desktop", "Documents", "—", "选择文件夹…"], "不存在的目录不列出")
        #expect(copyTo.last?.command == Command(.copyTo))
    }

    @Test func askFileNameAddsEllipsis() {
        var s = settings
        s.askFileName = true
        #expect(menu(.container, settings: s)[0].children[0].title == "文本文档…")
    }

    @Test func customOrderIsKept() {
        var s = settings
        s.newItems.swapAt(0, 1)
        #expect(menu(.container, settings: s)[0].children.prefix(2).map(\.title) == ["Markdown", "文本文档"])
    }

    @Test func iconsCanBeHidden() {
        var s = settings
        s.showMenuIcons = false
        func allNil(_ nodes: [MenuNode]) -> Bool { nodes.allSatisfy { $0.icon == nil && allNil($0.children) } }
        #expect(allNil(menu(.items, [file("a.png")], settings: s)))
        #expect(!allNil(menu(.items, [file("a.png")])))
    }

    @Test func concreteThingsUseRealIcons() {
        let newFile = menu(.container)[0].children
        #expect(newFile.allSatisfy { if case .fileType = $0.icon { true } else { false } })
        #expect(newFile.first?.icon == .fileType(extension: settings.newItems.first { $0.enabled }!.fileExtension))
    }

    // MARK: 工具箱表

    @Test func toolboxForFolder() {
        #expect(toolbox(menu(.items, [folder("A")])) == [
            "拷贝路径", "拷贝名称", "—", "发送替身到桌面", "隔空投送", "授予写入权限", "—", "隐藏所选", "—",
            "设置文件夹图标…", "—", "解散文件夹", "彻底删除…",
        ])
    }

    @Test func toolboxForPlainFile() {
        #expect(toolbox(menu(.items, [file("a.txt")])) == [
            "拷贝路径", "拷贝名称", "—", "根据文件名新建文件夹", "发送替身到桌面", "隔空投送", "授予写入权限", "文件信息（哈希）…",
            "—", "隐藏所选", "隐藏扩展名", "—", "彻底删除…",
        ])
    }

    @Test func toolboxForImage() {
        #expect(toolbox(menu(.items, [file("a.PNG")])) == [
            "拷贝路径", "拷贝名称", "—", "根据文件名新建文件夹", "发送替身到桌面", "隔空投送", "授予写入权限", "文件信息（哈希）…",
            "—", "隐藏所选", "隐藏扩展名", "—", "转换图片…", "生成 macOS 图标集", "生成 iOS 图标集", "设为壁纸", "设置文件夹图标…",
            "—", "彻底删除…",
        ])
    }

    @Test func toolboxForMultiple() {
        let images = toolbox(menu(.items, [file("a.png"), file("b.jpg")]))
        #expect(!images.contains("设为壁纸") && !images.contains("设置文件夹图标…") && images.contains("转换图片…"))
        let folderAndImage = toolbox(menu(.items, [folder("A"), file("b.jpg")]))
        #expect(folderAndImage.contains("设置文件夹图标") && !folderAndImage.contains("解散文件夹"))
        let twoFolders = toolbox(menu(.items, [folder("A"), folder("B")]))
        #expect(twoFolders.contains("解散文件夹") && !twoFolders.contains("设置文件夹图标…") && !twoFolders.contains("文件信息（哈希）…"))
        let mixed = toolbox(menu(.items, [folder("A"), file("b.txt")]))
        #expect(!mixed.contains("解散文件夹") && mixed.contains("根据文件名新建文件夹"))
    }

    @Test func toggleTitlesFollowState() {
        let hidden = SelectedItem(path: "\(home)/.a", isDirectory: false, isHidden: true, isExtensionHidden: true)
        #expect(toolbox(menu(.items, [hidden])).contains("显示所选"))
        #expect(toolbox(menu(.items, [hidden])).contains("显示扩展名"))
        #expect(toolbox(menu(.items, [hidden, file("b.txt")])).contains("隐藏/显示所选"))
        #expect(toolbox(menu(.items, [hidden, file("b.txt")])).contains("隐藏/显示扩展名"))
    }

    @Test func deleteWithoutConfirmationHasNoEllipsis() {
        var s = settings
        s.confirmPermanentDelete = false
        #expect(toolbox(menu(.items, [file("a")], settings: s)).last == "彻底删除")
    }

    @Test func dangerousCommandsStayLast() {
        var s = settings
        s.toolbox.reverse()
        let t = toolbox(menu(.items, [folder("A")], settings: s))
        #expect(t.suffix(2) == ["彻底删除…", "解散文件夹"])
        #expect(t[t.count - 3] == "—")
    }

    @Test func englishTitles() {
        L10n.$override.withValue(.english) {
            #expect(titles(menu(.container)) == ["New File", "Favorite Folders", "Open in App", "Copy Current Path"])
            var s = settings
            s.newItems.append(NewItemEntry(kind: .custom(CustomTemplate(name: "周报", storedFileName: "x", fileExtension: "key")), enabled: true))
            #expect(menu(.container, settings: s)[0].children.last?.title == "周报", "用户写的名字不翻译")
        }
    }

    @Test func monitoredPathMatchingKeepsExistingNormalizationAndBoundaryRules() {
        let roots = ["/", "/Users/tester/./work//", "/Volumes/Other", "/Users/tester/work/../kept"]
        let paths = ["/", "/Users/tester/work", "/Users/tester/work//./a", "/Users/tester/worker/a", "/Volumes/Other/a",
                     "/Volumes/Otherland", "/Users/tester/work/../kept/a", "/Users/tester/kept/a", "/tmp/file"]
        func previousMatch(_ path: String, _ roots: [String]) -> Bool {
            roots.contains { root in
                guard root != "/" else { return false }
                let p = PathRules.standardized(path), r = PathRules.standardized(root)
                return p == r || r == "/" || p.hasPrefix(r + "/")
            }
        }
        for candidateRoots in [roots, ["/"], ["//"], ["/Users/tester/work"], [String]()] {
            let scope = PathRules.MonitoringScope(candidateRoots)
            for path in paths {
                #expect(scope.contains(path) == previousMatch(path, candidateRoots), "\(path), \(candidateRoots)")
                #expect(PathRules.isInsideAny(path, of: candidateRoots) == previousMatch(path, candidateRoots))
            }
        }
    }

    @Test func transferTargetsKeepCompleteMenusAndQuerySynchronousFactsOnce() {
        final class Counts: @unchecked Sendable {
            private let lock = NSLock()
            private var existence: [String: Int] = [:]
            private var names: [String: Int] = [:]
            private var missing: Set<String> = []
            func exists(_ path: String) -> Bool {
                lock.lock(); defer { lock.unlock() }
                existence[path, default: 0] += 1
                return !path.hasSuffix("Gone") && !missing.contains(path)
            }
            func name(_ path: String) -> String {
                lock.lock(); defer { lock.unlock() }
                names[path, default: 0] += 1
                return "name: " + (path as NSString).lastPathComponent
            }
            func snapshot() -> ([String: Int], [String: Int]) {
                lock.lock(); defer { lock.unlock() }
                return (existence, names)
            }
            func remove(_ path: String) {
                lock.lock(); defer { lock.unlock() }
                missing.insert(path)
            }
        }
        var s = settings
        s.sendTo.append(s.sendTo[0]) // 两个条目指向同一路径，保持菜单两项。
        let counts = Counts()
        let measured = MenuEnvironment(folderExists: { counts.exists($0) }, displayName: { counts.name($0) }, isAppInstalled: { _ in false })
        let input = MenuInput(location: .items, folder: home, items: [file("a.txt")])
        let nodes = L10n.$override.withValue(.simplifiedChinese) {
            MenuBuilder.build(input, settings: s, environment: measured)
        }
        let targets = s.sendTo.filter { $0.enabled && !$0.path.hasSuffix("Gone") }
        let expectedCopy = targets.map {
            MenuNode(title: "name: " + ($0.path as NSString).lastPathComponent, icon: .file(path: $0.path), content: .command(Command(.copyTo, $0.id.uuidString)))
        } + [.separator, MenuBuilder.leaf("选择文件夹…", "folder.badge.questionmark", Command(.copyTo))]
        let expectedMove = targets.map {
            MenuNode(title: "name: " + ($0.path as NSString).lastPathComponent, icon: .file(path: $0.path), content: .command(Command(.moveTo, $0.id.uuidString)))
        } + [.separator, MenuBuilder.leaf("选择文件夹…", "folder.badge.questionmark", Command(.moveTo))]
        #expect(nodes.first { $0.title == "复制到" }?.children == expectedCopy)
        #expect(nodes.first { $0.title == "移动到" }?.children == expectedMove)
        let (existence, names) = counts.snapshot()
        #expect(existence == Dictionary(uniqueKeysWithValues: Set(s.sendTo.filter(\.enabled).map(\.path)).map { ($0, 1) }))
        #expect(names == Dictionary(uniqueKeysWithValues: Set(targets.map(\.path)).map { ($0, 1) }))

        let removedPath = s.sendTo[0].path
        counts.remove(removedPath)
        let nextMenu = L10n.$override.withValue(.simplifiedChinese) {
            MenuBuilder.build(input, settings: s, environment: measured)
        }
        #expect(nextMenu.first { $0.title == "复制到" }?.children.filter { $0.icon == .file(path: removedPath) }.isEmpty == true)
        let (nextExistence, _) = counts.snapshot()
        #expect(nextExistence[removedPath] == 2, "下一次构建必须重新检查已删除的文件夹")
    }
}

import AppKit

@Suite struct SymbolTests {
    @Test func everyMenuSymbolExists() {
        var settings = Settings.afterAuthorizing(home: "/Users/t") { _ in true }
        settings.openTools = OpenTool.known
        let env = MenuEnvironment(folderExists: { _ in true }, isAppInstalled: { _ in true })
        let inputs = [
            MenuInput(location: .container, folder: "/Users/t", hasPendingPaste: true),
            MenuInput(location: .items, folder: "/Users/t", items: [SelectedItem(path: "/Users/t/A", isDirectory: true)], hasPendingPaste: true),
            MenuInput(location: .items, folder: "/Users/t", items: [SelectedItem(path: "/Users/t/a.png", isDirectory: false)]),
            MenuInput(location: .toolbar, folder: "/"),
        ]
        var symbols = Set(ToolboxCommand.allCases.map(\.symbol))
        func collect(_ nodes: [MenuNode]) {
            for node in nodes {
                if case .symbol(let name) = node.icon { symbols.insert(name) }
                collect(node.children)
            }
        }
        inputs.forEach { collect(MenuBuilder.build($0, settings: settings, environment: env)) }
        for name in symbols.sorted() {
            #expect(NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil, "\(name)")
        }
    }
}
