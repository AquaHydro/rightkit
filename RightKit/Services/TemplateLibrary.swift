import Foundation
import RightKitCore

/// F-014：自定义模板保存为应用自己的副本，不再引用原文件。
enum TemplateLibrary {
    static var directory: URL { SharedStore.directory.appending(path: "Templates", directoryHint: .isDirectory) }

    static func url(for template: CustomTemplate) -> URL {
        directory.appending(path: template.storedFileName)
    }

    /// 复制一份到模板目录。菜单名默认用原文件名（去掉扩展名）。
    static func importTemplate(from source: URL, name: String? = nil) throws -> CustomTemplate {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let ext = source.pathExtension
        let stored = Naming.withExtension(UUID().uuidString, ext)
        try FileEngine.copy(source, to: directory.appending(path: stored), progress: nil)
        let menuName = name ?? Naming.removingExtension(source.lastPathComponent)
        return CustomTemplate(name: menuName, storedFileName: stored, fileExtension: ext)
    }

    static func remove(_ template: CustomTemplate) {
        try? FileManager.default.removeItem(at: url(for: template))
    }
}
