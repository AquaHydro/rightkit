import AppKit
import Foundation
import RightKitCore

/// 用户选择的文件夹：保存 bookmark，按 bookmark 找回被移动过的文件夹（technical.md 设置）。
enum FolderStore {
    static let home = PathRules.standardized(FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false))

    static func entry(for url: URL) -> FolderEntry {
        makeEntry(FolderEntry(path: PathRules.standardized(url.path(percentEncoded: false))))
    }

    static func makeEntry(_ entry: FolderEntry) -> FolderEntry {
        var copy = entry
        copy.bookmark = try? URL(filePath: entry.path, directoryHint: .isDirectory).bookmarkData()
        return copy
    }

    /// 按 bookmark 更新路径。进了废纸篓的文件夹算不存在，保留原路径。
    static func refreshed(_ entry: FolderEntry) -> FolderEntry {
        guard let bookmark = entry.bookmark else { return entry }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: [.withoutUI, .withoutMounting], bookmarkDataIsStale: &stale)
        else { return entry }
        let path = PathRules.standardized(url.path(percentEncoded: false))
        guard !isInTrash(path) else { return entry }
        var copy = entry
        copy.path = path
        if stale { copy.bookmark = try? url.bookmarkData() }
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
