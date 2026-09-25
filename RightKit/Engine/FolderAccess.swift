import Foundation
import RightKitCore
import Synchronization

/// F-080：RightKit 在沙盒里能访问的文件夹（technical.md 沙盒与文件访问）。
/// 保存的文件夹在启动时解析 security-scoped bookmark 并一直保持访问；文件夹选择面板给的 URL 在本次运行内可访问。
/// 命令分派入口和快捷指令用 `isAuthorized` 判断目标能不能读写。可以从任意线程调用。
final class FolderAccess: Sendable {
    static let shared = FolderAccess()

    /// 已授权文件夹的标准化路径。开始访问后在整个运行期间保持，不结束。
    private let roots = Mutex(Set<String>())

    /// 解析 bookmark 并开始访问。成功时返回路径和 bookmark 已更新的条目；失败返回 nil，调用方把它标为需要重新授权。
    func activate(_ entry: FolderEntry) -> FolderEntry? {
        guard let data = entry.bookmark else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI, .withoutMounting],
                                 bookmarkDataIsStale: &stale)
        else { return nil }
        let path = PathRules.standardized(url.path(percentEncoded: false))
        let started = roots.withLock { paths in
            guard !paths.contains(path) else { return true }
            guard url.startAccessingSecurityScopedResource() else { return false }
            paths.insert(path)
            return true
        }
        guard started else { return nil }
        var copy = entry
        copy.path = path
        copy.needsAuthorization = false
        if stale, let fresh = FolderStore.bookmark(for: url) { copy.bookmark = fresh }
        return copy
    }

    /// 用户刚在文件夹选择面板里选中的文件夹或文件。
    func grant(_ url: URL) {
        let path = PathRules.standardized(url.path(percentEncoded: false))
        _ = roots.withLock { $0.insert(path) }
    }

    func isAuthorized(_ url: URL) -> Bool {
        let path = PathRules.standardized(url.path(percentEncoded: false))
        return roots.withLock { PathRules.isInsideAny(path, of: Array($0)) }
    }

    /// 第一个不在任何已授权文件夹内的项目。
    func firstUnauthorized(_ urls: [URL]) -> URL? {
        urls.first { !isAuthorized($0) }
    }
}
