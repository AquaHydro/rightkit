import AppKit
import Foundation
import RightKitCore

/// 真实 AppKit 呈现器及文件元数据路径；不注册扩展、不读取用户设置。
@main
struct MenuPipelineBenchmark {
    static func measure(_ label: String, count: Int = 50, _ body: () throws -> Void) rethrows {
        var samples: [Double] = []
        for _ in 0..<count {
            let start = ProcessInfo.processInfo.systemUptime
            try autoreleasepool { try body() }
            samples.append((ProcessInfo.processInfo.systemUptime - start) * 1000)
        }
        let ordered = samples.sorted()
        print(String(format: "%@ n=%d first_ms=%.3f p50_ms=%.3f p95_ms=%.3f", label, count,
                     samples[0], ordered[count / 2], ordered[Int(ceil(Double(count) * 0.95)) - 1]))
    }

    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "rightkit-menu-pipeline-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let urls = try (0..<1000).map { index in
            let url = root.appending(path: "file-\(index).txt")
            try Data("fixture".utf8).write(to: url)
            return url
        }
        var settings = Settings.afterAuthorizing(home: root.path) { _ in false }
        settings.openTools = []
        for index in 0..<30 {
            let url = root.appending(path: "folder-\(index)")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
            let entry = FolderEntry(path: url.path)
            settings.sendTo.append(entry)
            settings.favorites.append(entry)
        }
        let environment = MenuEnvironment(folderExists: { FileManager.default.fileExists(atPath: $0) },
                                          displayName: { FileManager.default.displayName(atPath: $0) },
                                          isAppInstalled: { _ in false })
        let pendingURL = root.appending(path: "pending.json")
        try JSONEncoder().encode((0..<10000).map { root.appending(path: "pending-\($0)").path }).write(to: pendingURL, options: .atomic)
        let pending = PendingPasteState(url: pendingURL)
        measure("pending-cached-10000") { precondition(pending.hasItems()) }
        try measure("pending-full-decode-10000") {
            let paths = try JSONDecoder().decode([String].self, from: Data(contentsOf: pendingURL))
            precondition(!paths.isEmpty)
        }

        for count in [0, 1, 100, 1000] {
            let renderer = MenuRenderer()
            let location: MenuLocation = count == 0 ? .container : .items
            measure("pipeline-selected-\(count)") {
                let items = urls.prefix(count).map { original -> SelectedItem in
                    // 与每次右键相同，重新拿 URL 的元数据，不能复用上次 resourceValues 缓存。
                    let url = URL(filePath: original.path)
                    let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isHiddenKey, .hasHiddenExtensionKey])
                    return SelectedItem(path: url.path, isDirectory: values?.isDirectory ?? false,
                                        isHidden: values?.isHidden ?? false, isExtensionHidden: values?.hasHiddenExtension ?? false)
                }
                let input = MenuInput(location: location, folder: root.path, items: items,
                                      hasPendingPaste: count == 0 && pending.hasItems())
                let nodes = MenuBuilder.build(input, settings: settings, environment: environment)
                let result = renderer.render(nodes, target: nil, action: nil, isDark: false)
                precondition(!result.menu.items.isEmpty)
            }
            let input = MenuInput(location: location, folder: root.path,
                                  items: urls.prefix(count).map { SelectedItem(path: $0.path, isDirectory: false) })
            let nodes = MenuBuilder.build(input, settings: settings, environment: environment)
            measure("presentation-cold-selected-\(count)") {
                _ = MenuRenderer().render(nodes, target: nil, action: nil, isDark: false)
            }
            measure("presentation-warm-selected-\(count)") {
                _ = renderer.render(nodes, target: nil, action: nil, isDark: false)
            }
        }
        for roots in [1, 10, 30] {
            settings.monitoredFolders = (0..<roots).map { FolderEntry(path: "/Users/perf/root-\($0)") }
            settings.sendTo = []
            for count in [100, 1000, 10000] {
                let folder = "/Users/perf/root-\(roots - 1)"
                let input = MenuInput(location: .items, folder: folder, items: (0..<count).map {
                    SelectedItem(path: folder + "/folder/file-\($0).txt", isDirectory: false)
                })
                measure("rules-roots-\(roots)-selected-\(count)", count: 20) {
                    precondition(!MenuBuilder.build(input, settings: settings, environment: environment).isEmpty)
                }
            }
        }
    }
}
