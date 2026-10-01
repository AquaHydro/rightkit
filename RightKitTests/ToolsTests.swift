import AppKit
import Foundation
import ImageIO
import Testing
@testable import RightKitCore

@Suite struct ToolsTests {
    @Test func newFolderFromNameContainsFile() throws {
        let dir = try TempDir()
        let file = try dir.file("photo.large.jpg")
        let folder = try Tools.newFolderFromName(file)
        #expect(folder.lastPathComponent == "photo.large")
        #expect(dir.names("photo.large") == ["photo.large.jpg"])
        // 没有扩展名：文件夹与文件同名，也不冲突。
        let readme = try dir.file("README")
        #expect(try Tools.newFolderFromName(readme).lastPathComponent == "README")
        #expect(dir.names("README") == ["README"])
        // 目标名被占用时编号。
        try dir.folder("notes")
        let notes = try dir.file("notes.txt")
        #expect(try Tools.newFolderFromName(notes).lastPathComponent == "notes 2")
    }

    @Test func aliasGoesToGivenDesktopWithNumbering() throws {
        let dir = try TempDir()
        let desktop = try dir.folder("Desktop")
        let file = try dir.file("a.txt")
        let first = try Tools.makeAliasOnDesktop(file, desktop: desktop)
        let second = try Tools.makeAliasOnDesktop(file, desktop: desktop)
        #expect([first.lastPathComponent, second.lastPathComponent] == ["a.txt", "a 2.txt"])
        #expect(try URL(resolvingAliasFileAt: first).path(percentEncoded: false) == file.path(percentEncoded: false))
    }

    @Test func hiddenAndExtensionToggleBackAndForth() throws {
        let dir = try TempDir()
        let file = try dir.file("a.txt")
        func hidden() throws -> Bool { try file.resourceValues(forKeys: [.isHiddenKey]).isHidden == true }
        func extHidden() throws -> Bool {
            var url = file
            url.removeAllCachedResourceValues()
            return try url.resourceValues(forKeys: [.hasHiddenExtensionKey]).hasHiddenExtension == true
        }
        #expect(Tools.toggleHidden([file]).values.allSatisfy { $0 })
        var fresh = file; fresh.removeAllCachedResourceValues()
        #expect(try fresh.resourceValues(forKeys: [.isHiddenKey]).isHidden == true)
        _ = Tools.toggleHidden([file])
        fresh.removeAllCachedResourceValues()
        #expect(try fresh.resourceValues(forKeys: [.isHiddenKey]).isHidden == false)
        _ = Tools.toggleExtension([file])
        #expect(try extHidden())
        _ = Tools.toggleExtension([file])
        #expect(try !extHidden())
        _ = try hidden()
    }

    @Test func grantWriteIsNotRecursive() throws {
        let dir = try TempDir()
        let folder = try dir.folder("ro")
        let inner = try dir.file("ro/inner.txt")
        chmod(inner.path(percentEncoded: false), 0o444)
        chmod(folder.path(percentEncoded: false), 0o555)
        defer { chmod(folder.path(percentEncoded: false), 0o755) }
        try Tools.grantWrite(folder)
        var info = stat()
        stat(folder.path(percentEncoded: false), &info)
        #expect(info.st_mode & 0o777 == 0o755)
        stat(inner.path(percentEncoded: false), &info)
        #expect(info.st_mode & 0o777 == 0o444, "不递归")
    }

    @Test func dissolveMovesChildrenAndTrashesFolder() throws {
        let dir = try TempDir()
        try dir.file("box/a.txt", "inner")
        try dir.file("box/sub/b.txt")
        try dir.file("box/.DS_Store")
        try dir.file("a.txt", "outer")
        let trashed = try #require(try Tools.dissolve(dir.url.appending(path: "box")))
        defer { try? FileManager.default.removeItem(at: trashed) }
        #expect(FileManager.default.fileExists(atPath: trashed.path(percentEncoded: false)), "原文件夹在废纸篓")
        #expect(dir.names() == ["a 2.txt", "a.txt", "sub"])
        #expect(try String(contentsOf: dir.url.appending(path: "a.txt"), encoding: .utf8) == "outer", "不覆盖")
    }

    @Test func protectionResolvesSymlinks() throws {
        let dir = try TempDir()
        let link = dir.url.appending(path: "sys")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: URL(filePath: "/System"))
        #expect(Tools.isProtected(link))
        #expect(Tools.isProtected(URL(filePath: FolderStore.home)))
        #expect(Tools.isProtected(URL(filePath: NSTemporaryDirectory())), "/var/folders 解析后在 /private/var 里")
        #expect(!Tools.isProtected(try dir.file("mine.txt")))
    }

    @Test func permanentDeleteSkipsTrash() throws {
        let dir = try TempDir()
        let file = try dir.file("gone.txt")
        try Tools.deletePermanently(file)
        #expect(dir.names().isEmpty)
    }

    @Test func hashMatchesVectorsAndRejectsFolders() throws {
        let dir = try TempDir()
        let file = try dir.file("fixture.txt", "RightKit research fixture\n")
        #expect(try Tools.hashFile(file).sha256 == "b498f016419a7033869370c685746066601370413988cf11760d56e6d01d32bb")
        let empty = try dir.file("empty", "")
        #expect(try Tools.hashFile(empty).md5 == "d41d8cd98f00b204e9800998ecf8427e")
        #expect(throws: Tools.HashError.notAFile) { try Tools.hashFile(dir.url) }
        #expect(throws: Tools.HashError.unreadable) { try Tools.hashFile(dir.url.appending(path: "missing")) }
        let locked = try dir.file("locked", "x")
        chmod(locked.path(percentEncoded: false), 0o000)
        defer { chmod(locked.path(percentEncoded: false), 0o644) }
        #expect(throws: Tools.HashError.unreadable) { try Tools.hashFile(locked) }
    }
}

@Suite struct ImageToolsTests {
    /// 写一张带透明的 PNG。
    func makePNG(_ dir: TempDir, name: String, width: Int, height: Int) throws -> URL {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        let url = dir.url.appending(path: name)
        let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
        #expect(CGImageDestinationFinalize(dest))
        return url
    }

    func pixelSize(_ url: URL) throws -> (Int, Int, Bool) {
        let (image, _) = try ImageTools.load(url)
        let alpha = ![.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo)
        return (image.width, image.height, alpha)
    }

    @Test func convertsToEveryFormatWithoutOverwriting() throws {
        let dir = try TempDir()
        let png = try makePNG(dir, name: "pic.png", width: 40, height: 20)
        for format in ImageFormat.allCases {
            let out = try ImageTools.convert(png, to: format)
            #expect(out.pathExtension == format.fileExtension)
            let (w, h, alpha) = try pixelSize(out)
            #expect(w == 40 && h == 20)
            if format == .jpeg || format == .heic { #expect(!alpha, "\(format) 不保留透明") }
        }
        #expect(dir.names().contains("pic 2.png"), "同格式输出编号，不覆盖源文件")
    }

    @Test func unreadableImageFails() throws {
        let dir = try TempDir()
        let fake = try dir.file("fake.png", "not an image")
        #expect(throws: ImageTools.Failure.unreadable) { try ImageTools.convert(fake, to: .png) }
    }

    @Test func macIconSetHasAllSizes() throws {
        let dir = try TempDir()
        let png = try makePNG(dir, name: "logo.png", width: 1200, height: 800)
        let (iconset, icns) = try ImageTools.makeMacIconSet(png)
        #expect(iconset.lastPathComponent == "logo.iconset" && icns.lastPathComponent == "logo.icns")
        let files = dir.names("logo.iconset")
        #expect(files.count == 10)
        #expect(try pixelSize(iconset.appending(path: "icon_512x512@2x.png")).0 == 1024)
        #expect(try pixelSize(iconset.appending(path: "icon_16x16.png")).1 == 16)
        #expect(!dir.names().contains { $0.hasPrefix(FileEngine.tempPrefix) })
    }

    @Test func iOSIconSetHasAllSizes() throws {
        let dir = try TempDir()
        let png = try makePNG(dir, name: "app.png", width: 300, height: 500)
        let folder = try ImageTools.makeIOSIconSet(png)
        #expect(folder.lastPathComponent == "app iOS")
        #expect(dir.names("app iOS").count == 13)
        let (w, h, _) = try pixelSize(folder.appending(path: "icon-1024.png"))
        #expect(w == 1024 && h == 1024)
    }
}
