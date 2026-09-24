import Foundation
import RightKitCore

/// F-014：自定义模板保存为应用自己的副本，不再引用原文件。
enum TemplateLibrary {
    static var directory: URL { SharedStore.directory.appending(path: "Templates", directoryHint: .isDirectory) }

    static func url(for template: CustomTemplate) -> URL {
        directory.appending(path: template.storedFileName)
    }

    /// 在后台复制一份到模板目录。菜单名默认用原文件名（去掉扩展名）。
    static func importTemplate(from source: URL, name: String? = nil) async throws -> CustomTemplate {
        try await importTemplate(from: source, name: name, into: directory)
    }

    static func importTemplate(from source: URL, name: String? = nil, into destinationDirectory: URL,
                               _beforeReturningForTesting: (@Sendable () async -> Void)? = nil) async throws -> CustomTemplate {
        let progress = OperationProgress()
        return try await withTaskCancellationHandler {
            let template = try await Task.detached(priority: .userInitiated) {
                try importTemplate(from: source, name: name, into: destinationDirectory, progress: progress)
            }.value
            if let _beforeReturningForTesting { await _beforeReturningForTesting() }
            do {
                try Task.checkCancellation()
                return template
            } catch {
                try? FileManager.default.removeItem(at: destinationDirectory.appending(path: template.storedFileName))
                throw error
            }
        } onCancel: {
            progress.cancel()
        }
    }

    /// 同步核心只供后台任务和文件操作测试使用。
    static func importTemplate(from source: URL, name: String? = nil, into destinationDirectory: URL,
                               progress: OperationProgress) throws -> CustomTemplate {
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        guard !progress.isCancelled else { throw FileEngineError.cancelled }

        let ext = source.pathExtension
        let desiredName = Naming.withExtension(UUID().uuidString, ext)
        let temporary = FileEngine.tempURL(in: destinationDirectory)
        var destination: URL?
        let storedFileName: String
        do {
            try FileEngine.copy(source, to: temporary, progress: progress)
            guard !progress.isCancelled else { throw FileEngineError.cancelled }
            let placed = try FileEngine.place(temporary, in: destinationDirectory, as: desiredName)
            destination = placed
            guard !progress.isCancelled else { throw FileEngineError.cancelled }
            storedFileName = placed.lastPathComponent
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            if let destination { try? FileManager.default.removeItem(at: destination) }
            throw error
        }
        let menuName = name ?? Naming.removingExtension(source.lastPathComponent)
        return CustomTemplate(name: menuName, storedFileName: storedFileName, fileExtension: ext)
    }

    static func remove(_ template: CustomTemplate) {
        try? FileManager.default.removeItem(at: url(for: template))
    }
}
