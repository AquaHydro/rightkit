import AppKit
import Foundation
import Testing
@testable import RightKitCore

@Suite @MainActor struct MenuPresentationTests {
    @Test func pendingStateTracksAtomicReplacementDeletionAndRepair() throws {
        let dir = try TempDir()
        let file = dir.url.appending(path: "pending.json")
        var reads = 0
        let state = PendingPasteState(url: file) { url in
            reads += 1
            return try Data(contentsOf: url)
        }
        #expect(!state.hasItems())
        #expect(reads == 0)
        try Data("[\"a\"]".utf8).write(to: file, options: .atomic)
        #expect(state.hasItems())
        #expect(state.hasItems())
        #expect(reads == 1)
        // 同样大小、不同内容的原子替换也必须失效。
        try Data("[\"b\"]".utf8).write(to: file, options: .atomic)
        #expect(state.hasItems())
        #expect(reads == 2)
        try Data("[]".utf8).write(to: file, options: .atomic)
        #expect(!state.hasItems())
        try Data("broken".utf8).write(to: file, options: .atomic)
        #expect(!state.hasItems())
        try Data("[\"c\"]".utf8).write(to: file, options: .atomic)
        #expect(state.hasItems())
        try FileManager.default.removeItem(at: file)
        #expect(!state.hasItems())
        try Data("[]".utf8).write(to: file, options: .atomic)
        #expect(!state.hasItems())
    }

    @Test func failedReadIsRetriedWithoutAFileChange() throws {
        let dir = try TempDir()
        let file = try dir.file("pending.json", "[\"a\"]")
        var fail = true
        let state = PendingPasteState(url: file) { url in
            if fail { throw CocoaError(.fileReadNoPermission) }
            return try Data(contentsOf: url)
        }
        #expect(!state.hasItems())
        fail = false
        #expect(state.hasItems())
    }

    @Test func rendererPreservesCommandsSeparatorsAndDisablingIcons() {
        let renderer = MenuRenderer()
        let nodes = [MenuNode(title: "Tools", icon: .symbol("folder"), content: .submenu([
            MenuNode(title: "Copy", icon: .symbol("doc.on.doc"), content: .command(Command(.copyPath))),
            .separator,
            MenuNode(title: "Name", icon: nil, content: .command(Command(.copyName)))
        ]))]
        let result = renderer.render(nodes, target: nil, action: nil, isDark: false)
        #expect(result.commands == [Command(.copyPath), Command(.copyName)])
        let children = result.menu.items[0].submenu!.items
        #expect(children.map(\.title) == ["Copy", "", "Name"])
        #expect(children[0].tag == 0)
        #expect(children[1].isSeparatorItem)
        #expect(children[2].tag == 1)
        #expect(children[0].image != nil)
        #expect(children[2].image == nil)
        let next = renderer.render([MenuNode(title: "Settings", icon: nil, content: .command(Command(.openSettings)))],
                                   target: nil, action: nil, isDark: false)
        #expect(next.commands == [Command(.openSettings)])
        #expect(next.menu.items[0].tag == 0)
        #expect(next.menu.items[0].image == nil)
    }

    @Test func symbolCachePreservesPixelsAndTracksAppearance() throws {
        let renderer = MenuRenderer()
        let nodes = [MenuNode(title: "Copy", icon: .symbol("doc.on.doc"), content: .command(Command(.copyPath)))]
        func icon(_ dark: Bool) throws -> NSImage {
            try #require(renderer.render(nodes, target: nil, action: nil, isDark: dark).menu.items[0].image)
        }
        let light = try icon(false)
        let warm = try icon(false)
        #expect(light !== warm, "菜单收到独立副本，不能修改缓存对象")
        #expect(light.tiffRepresentation == warm.tiffRepresentation)
        #expect(light.isTemplate && warm.isTemplate)
        let dark = try icon(true)
        #expect(dark.tiffRepresentation != light.tiffRepresentation)
        #expect(try icon(false).tiffRepresentation == light.tiffRepresentation)
    }

    /// 访达把菜单跨进程拷过去时会编码图标的全部尺寸，多尺寸的应用和文件图标会让每次右键多出约 270 ms。
    @Test func appAndFileIconsAreSingleSmallBitmaps() throws {
        let dir = try TempDir()
        let file = try dir.file("a.txt", "a")
        let nodes: [MenuIcon] = [.app(bundleID: "com.apple.finder"), .fileType(extension: "md"), .file(path: file.path)]
        let result = MenuRenderer().render(nodes.map { MenuNode(title: "x", icon: $0, content: .command(Command(.copyPath))) },
                                           target: nil, action: nil, isDark: false)
        for item in result.menu.items {
            let image = try #require(item.image)
            #expect(image.size == NSSize(width: 16, height: 16))
            #expect(image.representations.count == 1)
            let rep = try #require(image.representations.first as? NSBitmapImageRep)
            #expect(rep.pixelsWide == 32 && rep.pixelsHigh == 32)
            #expect(!image.isTemplate, "应用和文件图标保留原色")
        }
    }
}
