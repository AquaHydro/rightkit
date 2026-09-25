import AppKit
import Darwin
import Foundation
import RightKitCore

/// 工具箱里不涉及图片的文件操作（features.md 工具行为）。都是同步函数，由调用方放到后台。
enum Tools {
    // MARK: F-043

    /// 在文件旁边新建同名文件夹并把文件移进去。先用临时名，避免和没有扩展名的源文件同名冲突。
    static func newFolderFromName(_ file: URL) throws(FileEngineError) -> URL {
        let parent = file.deletingLastPathComponent()
        let temp = FileEngine.tempURL(in: parent)
        guard mkdir(temp.path(percentEncoded: false), 0o755) == 0 else { throw .posix(errno) }
        let inside = temp.appending(path: file.lastPathComponent)
        guard rename(file.path(percentEncoded: false), inside.path(percentEncoded: false)) == 0 else {
            let code = errno
            rmdir(temp.path(percentEncoded: false))
            throw .posix(code)
        }
        do {
            return try FileEngine.place(temp, in: parent, as: Naming.removingExtension(file.lastPathComponent))
        } catch {
            // 放回原处，不留下临时文件夹。
            rename(inside.path(percentEncoded: false), file.path(percentEncoded: false))
            rmdir(temp.path(percentEncoded: false))
            throw error
        }
    }

    // MARK: F-044

    static func makeAliasOnDesktop(_ item: URL, desktop: URL = FolderStore.desktop) throws(FileEngineError) -> URL {
        let temp = FileEngine.tempURL(in: desktop)
        do {
            let data = try item.bookmarkData(options: .suitableForBookmarkFile)
            try URL.writeBookmarkData(data, to: temp)
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw .posix((error as NSError).underlyingPOSIXCode ?? EIO)
        }
        do {
            return try FileEngine.place(temp, in: desktop, as: item.lastPathComponent)
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw error
        }
    }

    // MARK: F-046、F-047

    /// 全部已隐藏时显示，否则全部隐藏。
    static func toggleHidden(_ items: [URL]) -> [URL: Bool] {
        let hide = !items.allSatisfy { (try? $0.resourceValues(forKeys: [.isHiddenKey]).isHidden) == true }
        return setFlag(items) { values in values.isHidden = hide }
    }

    static func toggleExtension(_ files: [URL]) -> [URL: Bool] {
        let hide = !files.allSatisfy { (try? $0.resourceValues(forKeys: [.hasHiddenExtensionKey]).hasHiddenExtension) == true }
        return setFlag(files) { values in values.hasHiddenExtension = hide }
    }

    private static func setFlag(_ items: [URL], _ apply: (inout URLResourceValues) -> Void) -> [URL: Bool] {
        var results: [URL: Bool] = [:]
        for item in items {
            var url = item
            var values = URLResourceValues()
            apply(&values)
            results[item] = (try? url.setResourceValues(values)) != nil
        }
        return results
    }

    // MARK: F-048

    /// 只给选中项本身加上属主写权限，不递归，不改属主。不是属主时失败。
    static func grantWrite(_ item: URL) throws(FileEngineError) {
        let path = item.path(percentEncoded: false)
        var info = stat()
        guard stat(path, &info) == 0 else { throw .posix(errno) }
        guard info.st_uid == getuid() else { throw .posix(EPERM) }
        guard chmod(path, (info.st_mode & 0o7777) | S_IWUSR) == 0 else { throw .posix(errno) }
    }

    // MARK: F-050

    /// 子项移到父目录，变空的文件夹放进废纸篓。`.DS_Store` 留在原处随文件夹进废纸篓。
    /// 返回文件夹在废纸篓里的位置。
    @discardableResult
    static func dissolve(_ folder: URL) throws(FileEngineError) -> URL? {
        let parent = folder.deletingLastPathComponent()
        let children: [URL]
        do {
            children = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        } catch {
            throw .posix((error as NSError).underlyingPOSIXCode ?? EIO)
        }
        for child in children where child.lastPathComponent != ".DS_Store" {
            _ = try FileEngine.transfer(child, to: parent, mode: .move, progress: nil)
        }
        var trashed: NSURL?
        do {
            try FileManager.default.trashItem(at: folder, resultingItemURL: &trashed)
        } catch {
            throw .posix((error as NSError).underlyingPOSIXCode ?? EIO)
        }
        return trashed as URL?
    }

    // MARK: F-051、F-073

    static func resolvedPath(_ url: URL) -> String {
        guard let resolved = realpath(url.path(percentEncoded: false), nil) else { return url.path(percentEncoded: false) }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    /// 先解析符号链接再判断目标本身。
    static func isProtected(_ url: URL) -> Bool {
        PathRules.isProtectedFromDeletion(resolvedPath: resolvedPath(url), home: resolvedPath(URL(filePath: FolderStore.home)))
    }

    static func deletePermanently(_ item: URL) throws(FileEngineError) {
        do {
            try FileManager.default.removeItem(at: item)
        } catch {
            throw .posix((error as NSError).underlyingPOSIXCode ?? EIO)
        }
    }

    // MARK: F-049

    enum HashError: Error, Equatable { case notAFile, unreadable, changed, cancelled }

    /// 流式读取，读完后比较文件大小和修改时间，变化了就放弃这次结果。
    static func hashFile(_ url: URL, progress: OperationProgress? = nil) throws(HashError) -> FileHashes {
        let path = url.path(percentEncoded: false)
        var before = stat()
        guard stat(path, &before) == 0 else { throw .unreadable }
        guard (before.st_mode & S_IFMT) == S_IFREG else { throw .notAFile }
        guard let handle = try? FileHandle(forReadingFrom: url) else { throw .unreadable }
        defer { try? handle.close() }
        var hasher = MultiHasher()
        progress?.addTotal(Int64(before.st_size))
        while true {
            if progress?.isCancelled == true || Task.isCancelled { throw .cancelled }
            let chunk: Data
            do {
                chunk = try handle.read(upToCount: 1 << 20) ?? Data()
            } catch {
                throw .unreadable
            }
            if chunk.isEmpty { break }
            hasher.update(chunk)
            progress?.addCompleted(Int64(chunk.count))
        }
        var after = stat()
        guard stat(path, &after) == 0, after.st_size == before.st_size,
              after.st_mtimespec.tv_sec == before.st_mtimespec.tv_sec,
              after.st_mtimespec.tv_nsec == before.st_mtimespec.tv_nsec
        else { throw .changed }
        return hasher.finalize()
    }
}
