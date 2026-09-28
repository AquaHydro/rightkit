import Darwin
import Foundation

/// 扩展主线程持有。每次只检查共享文件的版本，内容未变时不重复读取和解码整个待粘贴列表。
/// 主程序使用原子替换；同时检查 inode、大小和纳秒时间，避免漏掉等长替换。
final class PendingPasteState {
    private struct Version: Equatable {
        let device: dev_t
        let inode: ino_t
        let size: off_t
        let modifiedSeconds: Int
        let modifiedNanoseconds: Int
        let changedSeconds: Int
        let changedNanoseconds: Int

        init?(_ url: URL) {
            var info = stat()
            guard stat(url.path(percentEncoded: false), &info) == 0 else { return nil }
            device = info.st_dev
            inode = info.st_ino
            size = info.st_size
            modifiedSeconds = info.st_mtimespec.tv_sec
            modifiedNanoseconds = info.st_mtimespec.tv_nsec
            changedSeconds = info.st_ctimespec.tv_sec
            changedNanoseconds = info.st_ctimespec.tv_nsec
        }
    }

    private let url: URL
    private let read: (URL) throws -> Data
    private var version: Version?
    private var nonempty = false

    init(url: URL, read: @escaping (URL) throws -> Data = { try Data(contentsOf: $0) }) {
        self.url = url
        self.read = read
    }

    func hasItems() -> Bool {
        guard let current = Version(url) else {
            version = nil
            nonempty = false
            return false
        }
        if current == version { return nonempty }
        do {
            nonempty = !(try JSONDecoder().decode([String].self, from: read(url))).isEmpty
            version = current
            return nonempty
        } catch {
            // 读取失败可以是暂时的；不能把失败缓存成永久的空列表。
            version = nil
            nonempty = false
            return false
        }
    }
}
