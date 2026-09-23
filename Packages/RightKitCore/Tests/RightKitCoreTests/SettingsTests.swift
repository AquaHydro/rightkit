import Foundation
import Testing
@testable import RightKitCore

@Suite struct SettingsTests {
    let home = "/Users/tester"

    @Test func freshDefaultsMatchFeatureTable() {
        let s = Settings.makeDefault(home: home) { _ in true }
        #expect(s.theme == .system && s.language == .system)
        #expect(s.launchAtLogin && s.showMenuBarIcon && s.showMenuIcons && s.confirmPermanentDelete)
        #expect(s.groups == FeatureGroups())
        #expect(s.monitoredFolders.map(\.path) == [home])
        #expect(s.newItems.filter(\.enabled).map(\.fileExtension) == ["txt", "md", "rtf", "docx", "xlsx", "pptx"])
        #expect(s.newItems.map(\.fileExtension) == BuiltinType.allCases.map(\.rawValue))
        #expect(!s.openAfterCreate && !s.askFileName)
        #expect(s.favorites.map(\.path) == ["Downloads", "Desktop", "Documents"].map { "\(home)/\($0)" })
        #expect(s.sendTo.map(\.path) == s.favorites.map(\.path))
        #expect(s.favorites.allSatisfy { $0.enabled })
        #expect(s.toolbox.count == 16 && s.toolbox.allSatisfy { $0.enabled })
        #expect(!s.welcomeShown)
    }

    @Test func missingStandardFoldersAreSkipped() {
        let s = Settings.makeDefault(home: home) { !$0.hasSuffix("Desktop") }
        #expect(s.favorites.map(\.path) == ["\(home)/Downloads", "\(home)/Documents"])
    }

    @Test func roundTripsThroughJSON() throws {
        var s = Settings.makeDefault(home: home) { _ in true }
        s.newItems.append(NewItemEntry(kind: .custom(CustomTemplate(name: "周报", storedFileName: "a.key", fileExtension: "key")), enabled: true))
        s.openTools = [OpenTool.known[0]]
        let decoded = try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(s))
        #expect(decoded == s)
    }

    @Test func resetNewFileKeepsCustomTemplates() {
        var s = Settings()
        let custom = NewItemEntry(kind: .custom(CustomTemplate(name: "X", storedFileName: "x", fileExtension: "x")), enabled: false)
        s.newItems.reverse()
        s.newItems.insert(custom, at: 3)
        s.newItems[0].enabled.toggle()
        s.askFileName = true
        s.openAfterCreate = true
        s.toolbox[0].enabled = false
        s.resetNewFilePage()
        #expect(Array(s.newItems.prefix(12)) == Settings.defaultNewItems)
        #expect(s.newItems.last == custom)
        #expect(!s.askFileName && !s.openAfterCreate)
        #expect(!s.toolbox[0].enabled, "其他页不受影响")
    }

    @Test func resetToolboxRestoresOrderAndSwitches() {
        var s = Settings()
        s.toolbox.reverse()
        s.toolbox[2].enabled = false
        s.resetToolboxPage()
        #expect(s.toolbox == Settings.defaultToolbox)
    }

    @Test func normalizationAddsMissingAndDropsDuplicates() {
        var s = Settings()
        s.toolbox = [ToolboxEntry(command: .hash, enabled: false), ToolboxEntry(command: .hash)]
        s.newItems = [NewItemEntry(kind: .builtin(.sh), enabled: true)]
        let n = s.normalized()
        #expect(n.toolbox.count == 16 && n.toolbox[0] == ToolboxEntry(command: .hash, enabled: false))
        #expect(n.newItems.count == 12 && n.newItems[0].fileExtension == "sh")
    }
}

@Suite struct NamingTests {
    @Test(arguments: [
        ("未命名.txt", 1, "未命名.txt"), ("未命名.txt", 2, "未命名 2.txt"), ("a.tar.gz", 3, "a.tar 3.gz"),
        ("文件夹", 2, "文件夹 2"), (".zshrc", 2, ".zshrc 2"),
    ])
    func candidates(name: String, index: Int, expected: String) {
        #expect(Naming.candidate(name, index: index) == expected)
    }

    @Test func uniqueSkipsTakenNames() {
        let taken: Set = ["未命名.txt", "未命名 2.txt"]
        #expect(Naming.unique("未命名.txt", isTaken: taken.contains) == "未命名 3.txt")
        #expect(Naming.unique("新.md", isTaken: taken.contains) == "新.md")
    }

    @Test func ensuringExtension() {
        #expect(Naming.ensuringExtension("报告", "docx") == "报告.docx")
        #expect(Naming.ensuringExtension("报告.DOCX", "docx") == "报告.DOCX")
        #expect(Naming.ensuringExtension("报告.docx.txt", "docx") == "报告.docx.txt.docx")
        #expect(Naming.ensuringExtension("无扩展", "") == "无扩展")
    }

    @Test func folderNameFromFile() {
        #expect(Naming.removingExtension("photo.large.jpg") == "photo.large")
        #expect(Naming.removingExtension("README") == "README")
        #expect(Naming.removingExtension(".zshrc") == ".zshrc")
        #expect(Naming.iOSIconFolderName(forImage: "icon.png") == "icon iOS")
    }

    @Test func untitledFollowsLanguage() {
        L10n.$override.withValue(.english) { #expect(Naming.untitled(fileExtension: "txt") == "Untitled.txt") }
        L10n.$override.withValue(.simplifiedChinese) { #expect(Naming.untitled(fileExtension: "txt") == "未命名.txt") }
    }

    @Test func invalidNames() {
        for name in ["", ".", "..", "a/b", String(repeating: "长", count: 100)] {
            #expect(!Naming.isValidFileName(name), "\(name)")
        }
        #expect(Naming.isValidFileName("报告 2.txt"))
    }
}

@Suite struct PathRuleTests {
    let home = "/Users/tester"

    @Test(arguments: ["/", "/Users/tester", "/Users/tester/", "/System", "/System/Library/x", "/usr/bin",
                      "/bin", "/sbin/x", "/Library", "/Library/Fonts/a.ttf", "/private/var", "/private/var/folders/x"])
    func protected(path: String) {
        #expect(PathRules.isProtectedFromDeletion(resolvedPath: path, home: home))
    }

    @Test(arguments: ["/Users/tester/Desktop/a.txt", "/Applications/Foo.app", "/private/tmp/x", "/Users/tester2",
                      "/Systemx", "/Library2/x", "/Users/tester/Library/Caches/x"])
    func unprotected(path: String) {
        #expect(!PathRules.isProtectedFromDeletion(resolvedPath: path, home: home))
    }

    @Test func monitorRules() {
        for bad in ["/", "/System", "/Library", "/Users", "/private", "/private/var/folders/x", "/usr/local"] {
            #expect(!PathRules.canMonitor(bad, home: home), "\(bad)")
        }
        for good in [home, "\(home)/Projects", "/Volumes/Work", "/private/tmp/e2e", "/Applications"] {
            #expect(PathRules.canMonitor(good, home: home), "\(good)")
        }
    }

    @Test func insideAndSelfMove() {
        #expect(PathRules.isInsideAny("/Users/tester/a", of: ["/Users/tester"]))
        #expect(!PathRules.isInsideAny("/Users/testerX", of: ["/Users/tester"]))
        #expect(!PathRules.isInsideAny("/anything", of: ["/"]))
        #expect(PathRules.isMovingIntoItself(source: "/a/b", destinationFolder: "/a/b/c"))
        #expect(PathRules.isMovingIntoItself(source: "/a/b", destinationFolder: "/a/b"))
        #expect(!PathRules.isMovingIntoItself(source: "/a/b", destinationFolder: "/a/bc"))
    }
}
