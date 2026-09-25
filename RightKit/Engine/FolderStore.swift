import AppKit
import Foundation
import RightKitCore

/// 用户选择的文件夹：保存 security-scoped bookmark，按 bookmark 找回被移动过的文件夹（technical.md 沙盒与文件访问）。
enum FolderStore {
    enum State: Equatable { case available, missing, needsAuthorization }

    /// 只有明确的不存在错误才显示丢失；沙盒或文件权限拒绝时保留重新授权入口。
    static func state(_ entry: FolderEntry) -> State {
        guard !isInTrash(entry.path) else { return .missing }
        do {
            let values = try URL(filePath: entry.path).resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { return .missing }
            return entry.needsAuthorization ? .needsAuthorization : .available
        } catch {
            let error = error as NSError
            if error.domain == NSCocoaErrorDomain,
               [NSFileNoSuchFileError, NSFileReadNoSuchFileError].contains(error.code) { return .missing }
            if error.domain == NSPOSIXErrorDomain,
               [Int(ENOENT), Int(ENOTDIR)].contains(error.code) { return .missing }
            return .needsAuthorization
        }
    }

    /// 真实主目录。沙盒里 `homeDirectoryForCurrentUser` 和 `NSHomeDirectory()` 都指向应用容器。
    static let home: String = {
        guard let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir else { return NSHomeDirectory() }
        return PathRules.standardized(String(cString: dir))
    }()

    /// 真实桌面，F-044 替身和 F-074 新建文件的默认位置。
    static var desktop: URL {
        URL(filePath: home, directoryHint: .isDirectory).appending(path: "Desktop", directoryHint: .isDirectory)
    }

    /// 文件夹选择面板给出的 URL 此时可以访问，趁这时存下 bookmark。
    static func entry(for url: URL) -> FolderEntry {
        FolderEntry(path: PathRules.standardized(url.path(percentEncoded: false)), bookmark: bookmark(for: url))
    }

    /// 给还没有 bookmark 的条目补上。只有在已授权文件夹内才能成功。
    static func makeEntry(_ entry: FolderEntry) -> FolderEntry {
        guard entry.bookmark == nil else { return entry }
        var copy = entry
        copy.bookmark = bookmark(for: URL(filePath: entry.path, directoryHint: .isDirectory))
        return copy
    }

    static func bookmark(for url: URL) -> Data? {
        try? url.bookmarkData(options: .withSecurityScope)
    }

    /// 按 bookmark 更新路径。进了废纸篓的文件夹算不存在，保留原路径。
    static func refreshed(_ entry: FolderEntry) -> FolderEntry {
        guard let data = entry.bookmark else { return entry }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [.withoutUI, .withoutMounting], bookmarkDataIsStale: &stale)
        else { return entry }
        let path = PathRules.standardized(url.path(percentEncoded: false))
        guard !isInTrash(path) else { return entry }
        var copy = entry
        copy.path = path
        if stale, let fresh = bookmark(for: url) { copy.bookmark = fresh }
        return copy
    }

    static func exists(_ entry: FolderEntry) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: entry.path, isDirectory: &isDirectory) && isDirectory.boolValue
            && !isInTrash(entry.path)
    }

    static func isInTrash(_ path: String) -> Bool {
        PathRules.isSameOrInside(path, (home as NSString).appendingPathComponent(".Trash"))
    }

    static func displayName(_ entry: FolderEntry) -> String {
        FileManager.default.displayName(atPath: entry.path)
    }
}

/// F-020 至 F-022。
enum OpenToolDetector {
    static func appURL(_ bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    /// 只查找内置的四个应用；已在列表里的不改。
    static func detect(adding existing: [OpenTool]) -> [OpenTool] {
        var tools = existing
        for known in OpenTool.known where appURL(known.bundleID) != nil && !tools.contains(where: { $0.bundleID == known.bundleID }) {
            var tool = known
            tool.name = appURL(known.bundleID).map(displayName) ?? known.name
            tools.append(tool)
        }
        return tools
    }

    /// 用户选择的 `.app`，默认是编辑器并开启。
    static func tool(forAppAt url: URL) -> OpenTool? {
        guard let bundleID = Bundle(url: url)?.bundleIdentifier else { return nil }
        return OpenTool(bundleID: bundleID, name: displayName(url), role: .editor)
    }

    static func displayName(_ url: URL) -> String {
        (FileManager.default.displayName(atPath: url.path(percentEncoded: false)) as NSString).deletingPathExtension
    }
}
