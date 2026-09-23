import AppIntents
import AppKit
import RightKitCore
import UniformTypeIdentifiers

// F-074：对聚焦和快捷指令暴露的 9 个动作。彻底删除和解散文件夹不做 Intent，避免绕过确认。

struct IntentFailure: Error, CustomLocalizedStringResourceConvertible {
    let message: String
    var localizedStringResource: LocalizedStringResource { "\(message)" }
}

@MainActor
private func currentSettings() -> Settings {
    if let model = AppContext.delegate?.model { return model.settings }
    if case .loaded(let settings) = SharedStore.loadSettings(backupOnFailure: false) { return settings }
    return AppModel.firstLaunchDefaults()
}

private func urls(_ files: [IntentFile]) -> [URL] { files.compactMap(\.fileURL) }

// MARK: 拷贝路径、拷贝名称

struct CopyPathIntent: AppIntent {
    static let title: LocalizedStringResource = "拷贝路径"
    static let description = IntentDescription("把项目的路径拷贝到剪贴板，多项时每项一行。")

    @Parameter(title: "项目") var items: [IntentFile]

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let lines = urls(items).map { PathRules.standardized($0.path(percentEncoded: false)) }
        Pasteboard.copyLines(lines)
        return .result(value: lines.joined(separator: "\n"))
    }
}

struct CopyNameIntent: AppIntent {
    static let title: LocalizedStringResource = "拷贝名称"
    static let description = IntentDescription("把项目在访达中显示的名称拷贝到剪贴板，多项时每项一行。")

    @Parameter(title: "项目") var items: [IntentFile]

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let lines = urls(items).map { FileManager.default.displayName(atPath: $0.path(percentEncoded: false)) }
        Pasteboard.copyLines(lines)
        return .result(value: lines.joined(separator: "\n"))
    }
}

// MARK: 新建文件

struct NewFileTypeEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "文件类型"
    static let defaultQuery = NewFileTypeQuery()

    let id: String
    let title: String
    let fileExtension: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(fileExtension.isEmpty ? "" : "." + fileExtension)")
    }
}

struct NewFileTypeQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [NewFileTypeEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [NewFileTypeEntity] {
        currentSettings().newItems.map { NewFileTypeEntity(id: $0.id, title: $0.title, fileExtension: $0.fileExtension) }
    }
}

struct NewFileIntent: AppIntent {
    static let title: LocalizedStringResource = "新建文件"
    static let description = IntentDescription("用内置类型或自定义模板新建文件。没有指定文件夹时创建在桌面。")

    @Parameter(title: "文件类型") var type: NewFileTypeEntity
    @Parameter(title: "文件夹", supportedContentTypes: [.folder]) var folder: IntentFile?
    @Parameter(title: "名称") var name: String?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let settings = currentSettings()
        guard let item = settings.newItems.first(where: { $0.id == type.id }) else { throw IntentFailure(message: L("无法创建文件。")) }
        let target = folder?.fileURL ?? URL.desktopDirectory
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fileName = trimmed.isEmpty ? Naming.untitled(fileExtension: item.fileExtension) : Naming.ensuringExtension(trimmed, item.fileExtension)
        do {
            let created: URL
            switch item.kind {
            case .builtin(let builtin):
                if let text = builtin.textContent {
                    created = try FileEngine.createFile(in: target, named: fileName, contents: Data(text.utf8))
                } else if let template = Bundle.main.url(forResource: "Template", withExtension: builtin.rawValue) {
                    created = try FileEngine.cloneFile(template, into: target, named: fileName)
                } else {
                    throw FileEngineError.sourceMissing
                }
            case .custom(let template):
                created = try FileEngine.cloneFile(TemplateLibrary.url(for: template), into: target, named: fileName)
            }
            return .result(value: IntentFile(fileURL: created))
        } catch {
            throw IntentFailure(message: L("无法创建文件。"))
        }
    }
}

// MARK: 文件哈希

struct FileHashIntent: AppIntent {
    static let title: LocalizedStringResource = "文件哈希"
    static let description = IntentDescription("计算文件的 MD5、SHA-1、SHA-256 和 SHA-512。")

    @Parameter(title: "文件") var file: IntentFile

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let url = file.fileURL else { throw IntentFailure(message: L("无法读取文件。")) }
        do {
            let hashes = try Tools.hashFile(url)
            let text = FileHashes.Algorithm.allCases.map { "\($0.rawValue): \(hashes.value($0))" }.joined(separator: "\n")
            return .result(value: text)
        } catch .notAFile {
            throw IntentFailure(message: L("仅支持为文件计算哈希。"))
        } catch {
            throw IntentFailure(message: L("无法读取文件。"))
        }
    }
}

// MARK: 图片

enum ImageFormatOption: String, AppEnum {
    case png, jpeg, heic, tiff

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "图片格式"
    static let caseDisplayRepresentations: [ImageFormatOption: DisplayRepresentation] = [
        .png: "PNG", .jpeg: "JPEG", .heic: "HEIC", .tiff: "TIFF",
    ]

    var format: ImageFormat { ImageFormat(rawValue: rawValue)! }
}

struct ConvertImageIntent: AppIntent {
    static let title: LocalizedStringResource = "转换图片"
    static let description = IntentDescription("把图片转换成 PNG、JPEG、HEIC 或 TIFF，输出在原图旁边。")

    @Parameter(title: "图片", supportedContentTypes: [.image]) var images: [IntentFile]
    @Parameter(title: "格式", default: .png) var format: ImageFormatOption

    func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
        let outputs = try forEachImage(urls(images)) { try ImageTools.convert($0, to: format.format) }
        return .result(value: outputs.map { IntentFile(fileURL: $0) })
    }
}

struct MacIconSetIntent: AppIntent {
    static let title: LocalizedStringResource = "生成 macOS 图标集"
    static let description = IntentDescription("在原图旁边生成 .iconset 和 .icns。")

    @Parameter(title: "图片", supportedContentTypes: [.image]) var images: [IntentFile]

    func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
        let outputs = try forEachImage(urls(images)) { try ImageTools.makeMacIconSet($0).icns }
        return .result(value: outputs.map { IntentFile(fileURL: $0) })
    }
}

struct IOSIconSetIntent: AppIntent {
    static let title: LocalizedStringResource = "生成 iOS 图标集"
    static let description = IntentDescription("在原图旁边生成一组 iOS 图标 PNG。")

    @Parameter(title: "图片", supportedContentTypes: [.image]) var images: [IntentFile]

    func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
        let outputs = try forEachImage(urls(images)) { try ImageTools.makeIOSIconSet($0) }
        return .result(value: outputs.map { IntentFile(fileURL: $0) })
    }
}

/// 逐张处理；部分失败时保留成功的结果，全部失败才报错。
private func forEachImage(_ images: [URL], _ body: (URL) throws -> URL) throws -> [URL] {
    var outputs: [URL] = []
    var lastFailure: ImageTools.Failure?
    for image in images {
        do {
            outputs.append(try body(image))
        } catch {
            lastFailure = error as? ImageTools.Failure ?? .writeFailed
        }
    }
    if outputs.isEmpty, let lastFailure {
        switch lastFailure {
        case .unreadable where images.count == 1: throw IntentFailure(message: L("“%@”不是可读取的图片。", images[0].lastPathComponent))
        case .iconutilFailed: throw IntentFailure(message: L("iconutil 生成 ICNS 文件失败。"))
        default: throw IntentFailure(message: L("部分项目无法完成。"))
        }
    }
    return outputs
}

// MARK: 二维码

struct QRCodeIntent: AppIntent {
    static let title: LocalizedStringResource = "生成二维码"
    static let description = IntentDescription("在本机把文本生成二维码，打开二维码窗口。")
    static let openAppWhenRun = true

    @Parameter(title: "文本") var text: String

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let delegate = AppContext.delegate else { throw IntentFailure(message: L("无法保存二维码。")) }
        delegate.qr.text = text
        delegate.windows.open(id: WindowID.qrCode)
        return .result()
    }
}

// MARK: 在应用中打开

struct OpenToolEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "打开工具"
    static let defaultQuery = OpenToolQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct OpenToolQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [OpenToolEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [OpenToolEntity] {
        currentSettings().openTools
            .filter { OpenToolDetector.appURL($0.bundleID) != nil }
            .map { OpenToolEntity(id: $0.bundleID, name: $0.name) }
    }
}

struct OpenInAppIntent: AppIntent {
    static let title: LocalizedStringResource = "在应用中打开"
    static let description = IntentDescription("终端打开所在文件夹，编辑器打开项目本身。")

    @Parameter(title: "项目") var items: [IntentFile]
    @Parameter(title: "应用") var app: OpenToolEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let tool = currentSettings().openTools.first(where: { $0.bundleID == app.id }),
              let appURL = OpenToolDetector.appURL(tool.bundleID)
        else { throw IntentFailure(message: L("“%@”已不在系统中。", app.name)) }
        let isFolder: (URL) -> Bool = { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])).map { $0.isDirectory == true && $0.isPackage != true } ?? false
        }
        let targets = OpenTargets.resolve(role: tool.role, folder: nil, items: urls(items), isFolder: isFolder)
        do {
            _ = try await NSWorkspace.shared.open(targets, withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
        } catch {
            throw IntentFailure(message: L("无法用“%@”打开。", tool.name))
        }
        return .result()
    }
}

// MARK: App Shortcuts（最多 10 个，挑常用的）

struct RightKitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CopyPathIntent(), phrases: ["用 \(.applicationName) 拷贝路径"],
                    shortTitle: "拷贝路径", systemImageName: "link")
        AppShortcut(intent: NewFileIntent(), phrases: ["用 \(.applicationName) 新建文件"],
                    shortTitle: "新建文件", systemImageName: "doc.badge.plus")
        AppShortcut(intent: FileHashIntent(), phrases: ["用 \(.applicationName) 计算文件哈希"],
                    shortTitle: "文件哈希", systemImageName: "number")
        AppShortcut(intent: QRCodeIntent(), phrases: ["用 \(.applicationName) 生成二维码"],
                    shortTitle: "生成二维码", systemImageName: "qrcode")
    }
}
