import Foundation
import Testing
@testable import RightKitCore

/// 每个测试用自己新建的临时目录，只删除自己创建的文件。
final class TempDir {
    let url: URL
    init() throws {
        url = URL(filePath: "/private/tmp", directoryHint: .isDirectory).appending(path: "rightkit-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    deinit { try? FileManager.default.removeItem(at: url) }

    @discardableResult
    func file(_ name: String, _ text: String = "x") throws -> URL {
        let file = url.appending(path: name)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: file)
        return file
    }

    @discardableResult
    func folder(_ name: String) throws -> URL {
        let folder = url.appending(path: name, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func names(_ sub: String = "") -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: url.appending(path: sub).path(percentEncoded: false))) ?? []).sorted()
    }
}

@Suite struct FileEngineTests {
    @Test func createNeverOverwrites() throws {
        let dir = try TempDir()
        try dir.file("未命名.txt", "keep")
        let created = try FileEngine.createFile(in: dir.url, named: "未命名.txt", contents: Data("new".utf8))
        #expect(created.lastPathComponent == "未命名 2.txt")
        #expect(try String(contentsOf: dir.url.appending(path: "未命名.txt"), encoding: .utf8) == "keep")
        #expect(dir.names() == ["未命名 2.txt", "未命名.txt"], "没有残留临时文件")
    }

    @Test func createRejectsBadNameAndReadOnlyFolder() throws {
        let dir = try TempDir()
        #expect(throws: FileEngineError.invalidName) { try FileEngine.createFile(in: dir.url, named: "a/b", contents: Data()) }
        let locked = try dir.folder("locked")
        chmod(locked.path(percentEncoded: false), 0o555)
        defer { chmod(locked.path(percentEncoded: false), 0o755) }
        #expect(throws: (any Error).self) { try FileEngine.createFile(in: locked, named: "a.txt", contents: Data()) }
        #expect(dir.names("locked").isEmpty, "不留半截文件")
    }

    @Test func copyKeepsSourceAndNumbers() throws {
        let dir = try TempDir()
        let source = try dir.file("src/报告 \"1\".txt", "data")
        let target = try dir.folder("dst")
        try dir.file("dst/报告 \"1\".txt", "old")
        let result = try FileEngine.transfer(source, to: target, mode: .copy, progress: nil)
        #expect(result.lastPathComponent == "报告 \"1\" 2.txt")
        #expect(FileManager.default.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(try String(contentsOf: result, encoding: .utf8) == "data")
    }

    @Test func moveRemovesSource() throws {
        let dir = try TempDir()
        let source = try dir.folder("A")
        try dir.file("A/inner.txt")
        let target = try dir.folder("B")
        let result = try FileEngine.transfer(source, to: target, mode: .move, progress: nil)
        #expect(!FileManager.default.fileExists(atPath: source.path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: result.appending(path: "inner.txt").path(percentEncoded: false)))
    }

    @Test func cannotMoveFolderIntoItself() throws {
        let dir = try TempDir()
        let a = try dir.folder("A")
        let inner = try dir.folder("A/inner")
        #expect(throws: FileEngineError.movingIntoItself) { try FileEngine.transfer(a, to: inner, mode: .move, progress: nil) }
        #expect(throws: FileEngineError.movingIntoItself) { try FileEngine.transfer(a, to: a, mode: .copy, progress: nil) }
    }

    @Test func missingSourceFails() throws {
        let dir = try TempDir()
        #expect(throws: FileEngineError.sourceMissing) {
            try FileEngine.transfer(dir.url.appending(path: "gone"), to: dir.url, mode: .move, progress: nil)
        }
    }

    @Test func symlinkIsTransferredAsLink() throws {
        let dir = try TempDir()
        let real = try dir.file("real.txt", "content")
        let link = dir.url.appending(path: "link.txt")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)
        let target = try dir.folder("dst")
        let copied = try FileEngine.transfer(link, to: target, mode: .copy, progress: nil)
        #expect(try FileManager.default.destinationOfSymbolicLink(atPath: copied.path(percentEncoded: false)) == real.path(percentEncoded: false))
        let moved = try FileEngine.transfer(link, to: try dir.folder("dst2"), mode: .move, progress: nil)
        #expect((try? FileManager.default.destinationOfSymbolicLink(atPath: moved.path(percentEncoded: false))) != nil)
        #expect(FileManager.default.fileExists(atPath: real.path(percentEncoded: false)), "链接指向的内容不动")
    }

    @Test func moveWithinSameFolderIsNoop() throws {
        let dir = try TempDir()
        let file = try dir.file("a.txt")
        #expect(try FileEngine.transfer(file, to: dir.url, mode: .move, progress: nil) == file)
        #expect(dir.names() == ["a.txt"])
    }

    @Test func cancelledCopyLeavesNoPartialFile() throws {
        let dir = try TempDir()
        let big = dir.url.appending(path: "big.bin")
        try Data(count: 8 << 20).write(to: big)
        let progress = OperationProgress()
        progress.cancel()
        let target = try dir.folder("dst")
        #expect(throws: FileEngineError.cancelled) { try FileEngine.transfer(big, to: target, mode: .copy, progress: progress) }
        #expect(dir.names("dst").isEmpty)
        #expect(FileManager.default.fileExists(atPath: big.path(percentEncoded: false)))
    }

    @Test func progressReachesItemSize() throws {
        let dir = try TempDir()
        let file = dir.url.appending(path: "f.bin")
        try Data(count: 300_000).write(to: file)
        let progress = OperationProgress()
        progress.addTotal(FileEngine.size(of: file))
        _ = try FileEngine.transfer(file, to: try dir.folder("dst"), mode: .copy, progress: progress)
        #expect(progress.snapshot.fraction == 1)
    }

    @Test func folderCreationNumbers() throws {
        let dir = try TempDir()
        try dir.folder("新文件夹")
        #expect(try FileEngine.createFolder(in: dir.url, named: "新文件夹").lastPathComponent == "新文件夹 2")
    }
}
