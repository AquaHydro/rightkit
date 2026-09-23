import Darwin
import Foundation
import RightKitCore
import Synchronization

enum FileEngineError: Error, Equatable {
    case invalidName
    case sourceMissing
    case movingIntoItself
    case notAFolder
    case cancelled
    case posix(Int32)
}

/// 进度和取消，供进度窗口读取（F-075）。多个线程读写，用锁保护。
final class OperationProgress: Sendable {
    struct Snapshot: Equatable, Sendable {
        var completedBytes: Int64 = 0
        var totalBytes: Int64 = 0
        var currentName = ""
        var isCancelled = false

        var fraction: Double { totalBytes > 0 ? min(1, Double(completedBytes) / Double(totalBytes)) : 0 }
    }

    private let state = Mutex(Snapshot())

    var snapshot: Snapshot { state.withLock { $0 } }
    var isCancelled: Bool { state.withLock { $0.isCancelled } }

    func cancel() { state.withLock { $0.isCancelled = true } }
    func addTotal(_ bytes: Int64) { state.withLock { $0.totalBytes += bytes } }
    func addCompleted(_ bytes: Int64) { state.withLock { $0.completedBytes += bytes } }
    func setCompleted(_ bytes: Int64) { state.withLock { $0.completedBytes = bytes } }
    func setCurrent(_ name: String) { state.withLock { $0.currentName = name } }
}

/// 所有产生或移动文件的命令共用的一套编号、临时文件和不覆盖规则（technical.md 文件操作）。
enum FileEngine {
    static let tempPrefix = ".rightkit-tmp-"

    static func tempURL(in folder: URL) -> URL {
        folder.appending(path: tempPrefix + UUID().uuidString)
    }

    /// 把同一目录里的临时项改成最终名字。名字被占用时按 ` 2`、` 3` 编号，用 `RENAME_EXCL` 保证不覆盖。
    static func place(_ temp: URL, in folder: URL, as desiredName: String) throws(FileEngineError) -> URL {
        try claimName(desiredName, in: folder) { destination in
            renamex_np(temp.path(percentEncoded: false), destination.path(percentEncoded: false), UInt32(RENAME_EXCL)) == 0
        }
    }

    /// 反复尝试候选名，直到 `attempt` 成功或出现“已存在”以外的错误。
    private static func claimName(_ desiredName: String, in folder: URL, attempt: (URL) -> Bool) throws(FileEngineError) -> URL {
        guard Naming.isValidFileName(desiredName) else { throw .invalidName }
        var index = 1
        while true {
            let destination = folder.appending(path: Naming.candidate(desiredName, index: index))
            if attempt(destination) { return destination }
            guard errno == EEXIST || errno == ENOTEMPTY else { throw .posix(errno) }
            index += 1
        }
    }

    // MARK: 新建（F-010 至 F-014）

    static func createFile(in folder: URL, named name: String, contents: Data) throws(FileEngineError) -> URL {
        guard Naming.isValidFileName(name) else { throw .invalidName }
        let temp = tempURL(in: folder)
        do {
            try contents.write(to: temp, options: .withoutOverwriting)
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw .posix((error as NSError).underlyingPOSIXCode ?? EIO)
        }
        return try placeOrClean(temp, in: folder, as: name)
    }

    /// 整份克隆模板副本（F-014）。
    static func cloneFile(_ source: URL, into folder: URL, named name: String) throws(FileEngineError) -> URL {
        guard Naming.isValidFileName(name) else { throw .invalidName }
        let temp = tempURL(in: folder)
        try copy(source, to: temp, progress: nil)
        return try placeOrClean(temp, in: folder, as: name)
    }

    static func createFolder(in folder: URL, named name: String) throws(FileEngineError) -> URL {
        let temp = tempURL(in: folder)
        guard mkdir(temp.path(percentEncoded: false), 0o755) == 0 else { throw .posix(errno) }
        return try placeOrClean(temp, in: folder, as: name)
    }

    private static func placeOrClean(_ temp: URL, in folder: URL, as name: String) throws(FileEngineError) -> URL {
        do {
            return try place(temp, in: folder, as: name)
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw error
        }
    }

    // MARK: 复制和移动（F-032、F-033）

    enum TransferMode { case copy, move }

    /// 复制或移动一项到目标文件夹，返回最终位置。符号链接只处理链接本身。
    static func transfer(_ source: URL, to folder: URL, mode: TransferMode, progress: OperationProgress?) throws(FileEngineError) -> URL {
        let sourcePath = source.path(percentEncoded: false)
        var info = stat()
        guard lstat(sourcePath, &info) == 0 else { throw .sourceMissing }
        let isDirectory = (info.st_mode & S_IFMT) == S_IFDIR
        if isDirectory, PathRules.isMovingIntoItself(source: sourcePath, destinationFolder: folder.path(percentEncoded: false)) {
            throw .movingIntoItself
        }
        let name = source.lastPathComponent
        progress?.setCurrent(name)
        if progress?.isCancelled == true { throw .cancelled }

        if mode == .move {
            // 已经在目标文件夹里，什么也不用做。
            if source.deletingLastPathComponent().path(percentEncoded: false) == folder.path(percentEncoded: false) { return source }
            if isSameVolume(sourcePath, folder.path(percentEncoded: false)) {
                let destination = try claimName(name, in: folder) { destination in
                    renamex_np(sourcePath, destination.path(percentEncoded: false), UInt32(RENAME_EXCL)) == 0
                }
                progress?.addCompleted(size(of: source))
                return destination
            }
        }

        // 跨卷移动：先复制再删除源。复制阶段取消时源仍在。
        let temp = tempURL(in: folder)
        let before = progress?.snapshot.completedBytes ?? 0
        try copy(source, to: temp, progress: progress)
        // 克隆不走数据回调，按这一项的大小补齐。
        progress?.setCompleted(before + size(of: temp))
        let destination = try placeOrClean(temp, in: folder, as: name)
        if mode == .move {
            do {
                try FileManager.default.removeItem(at: source)
            } catch {
                throw .posix((error as NSError).underlyingPOSIXCode ?? EIO)
            }
        }
        return destination
    }

    static func isSameVolume(_ a: String, _ b: String) -> Bool {
        var sa = stat(), sb = stat()
        return lstat(a, &sa) == 0 && stat(b, &sb) == 0 && sa.st_dev == sb.st_dev
    }

    /// 文件或文件夹的总字节数，只用于进度显示。
    static func size(of url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .isRegularFileKey]
        if let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true {
            return Int64(values.totalFileSize ?? 0)
        }
        var total: Int64 = 0
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys))
        while let child = enumerator?.nextObject() as? URL {
            if let values = try? child.resourceValues(forKeys: keys), values.isRegularFile == true {
                total += Int64(values.totalFileSize ?? 0)
            }
        }
        return total
    }

    // MARK: copyfile

    private final class CopyContext {
        let progress: OperationProgress?
        var currentFileCopied: Int64 = 0
        init(progress: OperationProgress?) { self.progress = progress }
    }

    /// 递归复制，能克隆时克隆。`destination` 必须不存在。失败或取消时清理写了一半的目标。
    static func copy(_ source: URL, to destination: URL, progress: OperationProgress?) throws(FileEngineError) {
        let context = CopyContext(progress: progress)
        let state = copyfile_state_alloc()
        defer { copyfile_state_free(state) }
        let callback: copyfile_callback_t = { what, stage, state, sourcePath, _, ctx in
            guard let ctx else { return COPYFILE_CONTINUE }
            let context = Unmanaged<CopyContext>.fromOpaque(ctx).takeUnretainedValue()
            if context.progress?.isCancelled == true { return COPYFILE_QUIT }
            switch (Int32(what), Int32(stage)) {
            case (COPYFILE_RECURSE_FILE, COPYFILE_START):
                if let sourcePath { context.progress?.setCurrent((String(cString: sourcePath) as NSString).lastPathComponent) }
            case (COPYFILE_COPY_DATA, COPYFILE_PROGRESS):
                var copied: off_t = 0
                copyfile_state_get(state, UInt32(COPYFILE_STATE_COPIED), &copied)
                context.progress?.addCompleted(Int64(copied) - context.currentFileCopied)
                context.currentFileCopied = Int64(copied)
            case (COPYFILE_RECURSE_FILE, COPYFILE_FINISH):
                context.currentFileCopied = 0
            default:
                break
            }
            return COPYFILE_CONTINUE
        }
        let unmanaged = Unmanaged.passRetained(context)
        defer { unmanaged.release() }
        copyfile_state_set(state, UInt32(COPYFILE_STATE_STATUS_CB), unsafeBitCast(callback, to: UnsafeRawPointer.self))
        copyfile_state_set(state, UInt32(COPYFILE_STATE_STATUS_CTX), unmanaged.toOpaque())

        let flags = copyfile_flags_t(COPYFILE_CLONE | COPYFILE_ALL | COPYFILE_RECURSIVE | COPYFILE_NOFOLLOW)
        let result = copyfile(source.path(percentEncoded: false), destination.path(percentEncoded: false), state, flags)
        let failure = errno
        if result != 0 || progress?.isCancelled == true {
            try? FileManager.default.removeItem(at: destination)
            throw progress?.isCancelled == true || failure == ECANCELED ? .cancelled : .posix(failure)
        }
    }
}

extension NSError {
    var underlyingPOSIXCode: Int32? {
        if domain == NSPOSIXErrorDomain { return Int32(code) }
        return (userInfo[NSUnderlyingErrorKey] as? NSError)?.underlyingPOSIXCode
    }
}
