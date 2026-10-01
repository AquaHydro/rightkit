import AppKit
import os
import RightKitCore

/// 把通过校验的请求分派到具体操作。所有文件改动都在主程序里完成，耗时部分放到后台。
@MainActor
final class CommandRouter {
    private let log = Logger(subsystem: ServiceNames.appBundleID, category: "router")
    private let model: AppModel
    private let windows: WindowOpener
    private let progress: ProgressCenter
    private var pasteInProgress = false

    init(model: AppModel, windows: WindowOpener, progress: ProgressCenter) {
        self.model = model
        self.windows = windows
        self.progress = progress
    }

    func handle(_ request: ValidatedRequest) {
        log.notice("handle \(request.command.action.rawValue, privacy: .public) items=\(request.items.count)")
        Task { await perform(request) }
    }

    private var settings: Settings { model.settings }

    /// 只选中一个文件夹时目标是它，否则是当前文件夹。
    private func destinationFolder(_ request: ValidatedRequest) -> URL? {
        if request.items.count == 1, isFolder(request.items[0]) { return request.items[0] }
        return request.folder
    }

    private func perform(_ request: ValidatedRequest) async {
        let items = request.items
        let action = request.command.action
        if let denied = FolderAccess.shared.firstUnauthorized(locations(touchedBy: request)) {
            log.error("Unauthorized \(action.rawValue, privacy: .public)")
            return Alerts.showUnauthorized(denied)
        }
        switch action {
        case .openSettings:
            windows.openSettings()

        case .copyCurrentPath:
            guard let folder = request.folder else { return Alerts.showFailure(for: action) }
            Pasteboard.copyLines([PathRules.standardized(folder.path(percentEncoded: false))])
        case .copyPath:
            Pasteboard.copyLines(items.map { PathRules.standardized($0.path(percentEncoded: false)) })
        case .copyName:
            Pasteboard.copyLines(items.map { FileManager.default.displayName(atPath: $0.path(percentEncoded: false)) })

        case .newFile:
            guard let folder = destinationFolder(request), let id = request.command.argument else { return Alerts.showFailure(for: action) }
            await newFile(id: id, in: folder)

        case .openFolder:
            guard let entry = folderEntry(request.command.argument, in: settings.favorites) else {
                return Alerts.showFailure(for: action)
            }
            NSWorkspace.shared.open(URL(filePath: entry.path, directoryHint: .isDirectory))

        case .openIn:
            openIn(request)

        case .cut:
            model.setPending(items.map { $0.path(percentEncoded: false) })

        case .paste:
            guard let folder = destinationFolder(request) else { return Alerts.showFailure(for: action) }
            guard !pasteInProgress else { return }
            let pendingPaths = model.pendingPaste
            guard !pendingPaths.isEmpty else { return }
            pasteInProgress = true
            defer { pasteInProgress = false }
            let outcome = await transfer(pendingPaths.map { URL(filePath: $0) }, to: folder, mode: .move, action: .paste)
            if model.pendingPaste == pendingPaths {
                model.setPending(outcome.remaining.map { $0.path(percentEncoded: false) })
            }

        case .copyTo, .moveTo:
            let mode: FileEngine.TransferMode = action == .copyTo ? .copy : .move
            let folder: URL
            if let id = request.command.argument {
                guard let entry = folderEntry(id, in: settings.sendTo) else { return Alerts.show(L("该文件夹已不存在。")) }
                folder = URL(filePath: entry.path, directoryHint: .isDirectory)
            } else {
                guard let chosen = Alerts.chooseFolder(prompt: action == .copyTo ? L("复制") : L("移动")) else { return }
                folder = chosen
            }
            await transfer(items, to: folder, mode: mode, action: action)

        case .newFolderFromName:
            await batch(action, items.filter { !isFolder($0) }) { _ = try Tools.newFolderFromName($0) }
        case .aliasToDesktop:
            await batch(action, items) { _ = try Tools.makeAliasOnDesktop($0) }
        case .grantWrite:
            await batch(action, items) { try Tools.grantWrite($0) }
        case .toggleHidden:
            report(action, Tools.toggleHidden(items))
        case .toggleExtension:
            report(action, Tools.toggleExtension(items.filter { !isFolder($0) }))

        case .airDrop:
            guard let service = NSSharingService(named: .sendViaAirDrop), service.canPerform(withItems: items) else {
                return Alerts.showFailure(for: action)
            }
            Alerts.bringToFront()
            service.perform(withItems: items)

        case .hash:
            let files = items.filter { !isDirectory($0) }
            guard !files.isEmpty else { return Alerts.show(L("仅支持为文件计算哈希。")) }
            files.forEach { windows.open(id: WindowID.hash, value: $0) }

        case .convertImage:
            await convertImages(items.filter(isImage))
        case .macIconset:
            await batch(action, items.filter(isImage), title: L("正在生成图标集…")) { _ = try ImageTools.makeMacIconSet($0) }
        case .iosIconset:
            await batch(action, items.filter(isImage), title: L("正在生成图标集…")) { _ = try ImageTools.makeIOSIconSet($0) }
        case .setWallpaper:
            guard items.count == 1, ImageTools.setWallpaper(items[0]) else { return Alerts.showFailure(for: action) }
        case .setFolderIcon:
            setFolderIcon(items)

        case .dissolveFolder:
            let folders = items.filter(isFolder)
            await batch(action, folders, title: L("正在解散文件夹…")) { folder in
                guard !Tools.isProtected(folder) else { throw FileEngineError.posix(EPERM) }
                try Tools.dissolve(folder)
            }

        case .deletePermanently:
            // F-073：只要有一个受保护项，整批不删除。
            if items.contains(where: Tools.isProtected) { return Alerts.showProtectedLocation() }
            if settings.confirmPermanentDelete, !Alerts.confirmPermanentDelete(items) { return }
            await batch(action, items) { try Tools.deletePermanently($0) }
        }
    }

    // MARK: 新建

    private func newFile(id: String, in folder: URL) async {
        guard let item = settings.newItems.first(where: { $0.id == id }) else { return Alerts.showFailure(for: .newFile) }
        let ext = item.fileExtension
        var name = Naming.untitled(fileExtension: ext)
        if settings.askFileName {
            guard let typed = Alerts.askFileName() else { return }
            name = Naming.ensuringExtension(typed, ext)
        }
        let source: TemplateSource
        switch item.kind {
        case .builtin(let type):
            if let text = type.textContent {
                source = .data(Data(text.utf8))
            } else if let url = Bundle.main.url(forResource: "Template", withExtension: type.rawValue) {
                source = .file(url)
            } else {
                return Alerts.showFailure(for: .newFile)
            }
        case .custom(let template):
            source = .file(TemplateLibrary.url(for: template))
        }
        let result = await Task.detached { () -> Result<URL, FileEngineError> in
            Result { () throws(FileEngineError) -> URL in
                switch source {
                case .data(let data): try FileEngine.createFile(in: folder, named: name, contents: data)
                case .file(let url): try FileEngine.cloneFile(url, into: folder, named: name)
                }
            }
        }.value
        switch result {
        case .success(let created):
            if settings.openAfterCreate, !NSWorkspace.shared.open(created) { Alerts.show(L("无法打开文件。")) }
        case .failure(let error):
            log.error("New file failed: \(String(describing: error), privacy: .public)")
            Alerts.showFailure(for: .newFile)
        }
    }

    private enum TemplateSource: Sendable { case data(Data), file(URL) }

    // MARK: 在应用中打开（F-023）

    private func openIn(_ request: ValidatedRequest) {
        guard let tool = settings.openTools.first(where: { $0.bundleID == request.command.argument }) else { return }
        guard let appURL = OpenToolDetector.appURL(tool.bundleID) else {
            return Alerts.show(L("“%@”已不在系统中。", tool.name))
        }
        let targets = OpenTargets.resolve(role: tool.role, folder: request.folder, items: request.items, isFolder: isFolder)
        guard !targets.isEmpty else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open(targets, withApplicationAt: appURL, configuration: configuration) { _, error in
            guard error != nil else { return }
            Task { @MainActor in Alerts.show(L("无法用“%@”打开。", tool.name)) }
        }
    }

    // MARK: 传输

    @discardableResult
    private func transfer(_ items: [URL], to folder: URL, mode: FileEngine.TransferMode, action: CommandAction) async -> BatchWorker.Outcome {
        guard !items.isEmpty else { return BatchWorker.Outcome() }
        let title = mode == .copy
            ? (items.count == 1 ? L("正在复制“%@”…", items[0].lastPathComponent) : L("正在复制 %d 个项目…", items.count))
            : (items.count == 1 ? L("正在移动“%@”…", items[0].lastPathComponent) : L("正在移动 %d 个项目…", items.count))
        return await batch(action, items, title: title, measure: mode == .copy || !items.allSatisfy { FileEngine.isSameVolume($0.path(percentEncoded: false), folder.path(percentEncoded: false)) }) { item, progress in
            _ = try FileEngine.transfer(item, to: folder, mode: mode, progress: progress)
        }
    }

    // MARK: 图片

    private func convertImages(_ images: [URL]) async {
        guard !images.isEmpty, let format = Alerts.chooseImageFormat(for: images, initial: settings.lastImageFormat) else { return }
        model.settings.lastImageFormat = format
        var failures: [(URL, ImageTools.Failure)] = []
        let item = progress.begin(images.count == 1 ? L("正在转换“%@”…", images[0].lastPathComponent) : L("正在转换 %d 张图片…", images.count))
        let tracker = item.progress
        tracker.addTotal(Int64(images.count))
        for image in images {
            if tracker.isCancelled { break }
            tracker.setCurrent(image.lastPathComponent)
            let result = await Task.detached { Result { () throws(ImageTools.Failure) -> URL in try ImageTools.convert(image, to: format) } }.value
            if case .failure(let failure) = result { failures.append((image, failure)) }
            tracker.addCompleted(1)
        }
        progress.end(item)
        guard !tracker.isCancelled, !failures.isEmpty else { return }
        if failures.count < images.count { return Alerts.show(L("部分项目无法完成。")) }
        if images.count == 1 {
            let name = images[0].lastPathComponent
            return Alerts.show(failures[0].1 == .unreadable ? L("“%@”不是可读取的图片。", name) : L("无法转换“%@”。", name))
        }
        Alerts.showFailure(for: .convertImage)
    }

    /// F-057：一个文件夹加一张图片时直接设置，缺哪样就让用户选哪样。
    private func setFolderIcon(_ items: [URL]) {
        var folder = items.first(where: isFolder)
        var image = items.first(where: isImage)
        if folder == nil { folder = Alerts.chooseFolder(prompt: L("选择")) }
        if image == nil { image = Alerts.chooseImage() }
        guard let folder, let image else { return }
        if !ImageTools.setFolderIcon(folder: folder, image: image) { Alerts.showFailure(for: .setFolderIcon) }
    }

    // MARK: 批量执行与汇总

    private func batch(_ action: CommandAction, _ items: [URL], title: String? = nil,
                       _ work: @escaping @Sendable (URL) throws -> Void) async {
        await batch(action, items, title: title, measure: false) { item, _ in try work(item) }
    }

    /// 逐项在后台执行，统计结果后只弹一条汇总。给了标题的操作会登记进度（F-075）。
    @discardableResult
    private func batch(_ action: CommandAction, _ items: [URL], title: String?, measure: Bool,
                       _ work: @escaping @Sendable (URL, OperationProgress) throws -> Void) async -> BatchWorker.Outcome {
        guard !items.isEmpty else { return BatchWorker.Outcome() }
        let entry = title.map { progress.begin($0) }
        let tracker = entry?.progress ?? OperationProgress()
        let outcome = await Task.detached { () -> BatchWorker.Outcome in
            BatchWorker.run(items, measure: measure, progress: tracker, work: work)
        }.value
        if let entry { progress.end(entry) }
        if let message = Messages.summary(for: action, succeeded: outcome.succeeded, failed: outcome.failed, cancelled: outcome.cancelled) {
            Alerts.show(message)
        }
        return outcome
    }

    private func report(_ action: CommandAction, _ results: [URL: Bool]) {
        let succeeded = results.values.filter { $0 }.count
        if let message = Messages.summary(for: action, succeeded: succeeded, failed: results.count - succeeded) {
            Alerts.show(message)
        }
    }

    // MARK: 判断

    /// F-080：命令要读写的位置。只拷贝路径、名称或在访达中打开文件夹的命令不碰文件内容，不检查。
    /// 从文件夹选择面板临时选中的目标在选中时已登记授权。
    private func locations(touchedBy request: ValidatedRequest) -> [URL] {
        switch request.command.action {
        case .openSettings, .copyCurrentPath, .copyPath, .copyName, .openFolder, .cut:
            return []
        case .newFile:
            return destinationFolder(request).map { [$0] } ?? []
        case .paste:
            return model.pendingPaste.map { URL(filePath: $0) } + (destinationFolder(request).map { [$0] } ?? [])
        case .openIn:
            return request.items.isEmpty ? (request.folder.map { [$0] } ?? []) : request.items
        case .copyTo, .moveTo:
            let target = folderEntry(request.command.argument, in: settings.sendTo)
                .map { URL(filePath: $0.path, directoryHint: .isDirectory) }
            return request.items + (target.map { [$0] } ?? [])
        case .aliasToDesktop:
            return request.items + [FolderStore.desktop]
        default:
            return request.items
        }
    }

    private func folderEntry(_ id: String?, in entries: [FolderEntry]) -> FolderEntry? {
        guard let entry = entries.first(where: { $0.id.uuidString == id }) else { return nil }
        let refreshed = FolderStore.refreshed(entry)
        return FolderStore.exists(refreshed) ? refreshed : nil
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func isFolder(_ url: URL) -> Bool {
        isDirectory(url) && !NSWorkspace.shared.isFilePackage(atPath: url.path(percentEncoded: false))
    }

    private func isImage(_ url: URL) -> Bool {
        SelectedItem(path: url.path(percentEncoded: false), isDirectory: isDirectory(url)).isImage
    }
}

enum Pasteboard {
    /// F-041、F-042：多项每项一行。
    static func copyLines(_ lines: [String]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(lines.joined(separator: "\n"), forType: .string)
    }
}

/// F-023：终端打开目录，编辑器打开项目本身。
enum OpenTargets {
    static func resolve(role: OpenToolRole, folder: URL?, items: [URL], isFolder: (URL) -> Bool) -> [URL] {
        guard !items.isEmpty else { return folder.map { [$0] } ?? [] }
        guard role == .terminal else { return items }
        var seen = Set<String>()
        return items.map { isFolder($0) ? $0 : $0.deletingLastPathComponent() }
            .filter { seen.insert($0.standardizedFileURL.path(percentEncoded: false)).inserted }
    }
}
