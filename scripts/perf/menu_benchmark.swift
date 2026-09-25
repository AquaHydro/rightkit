import AppKit
import Foundation
import RightKitCore
import UniformTypeIdentifiers

@main
struct MenuBenchmark {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "rightkit-menu-benchmark-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        var settings = Settings.afterAuthorizing(home: root.path) { _ in true }
        settings.openTools = []
        for index in 0..<30 {
            let folder = root.appending(path: "folder-\(index)")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            let entry = FolderEntry(path: folder.path)
            settings.favorites.append(entry)
            settings.sendTo.append(entry)
        }
        let environment = MenuEnvironment(
            folderExists: { FileManager.default.fileExists(atPath: $0) },
            displayName: { FileManager.default.displayName(atPath: $0) },
            isAppInstalled: { _ in false }
        )
        let cases: [(String, MenuInput)] = [
            ("empty", MenuInput(location: .container, folder: root.path)),
            ("selected-100", MenuInput(location: .items, folder: root.path, items: (0..<100).map {
                SelectedItem(path: root.appending(path: "file-\($0).txt").path, isDirectory: false)
            })),
            ("selected-1000", MenuInput(location: .items, folder: root.path, items: (0..<1_000).map {
                SelectedItem(path: root.appending(path: "file-\($0).txt").path, isDirectory: false)
            })),
        ]
        for (name, input) in cases {
            for icons in [true, false] {
                settings.showMenuIcons = icons
                for toolbox in [true, false] {
                    settings.toolbox = Settings.defaultToolbox.map { ToolboxEntry(command: $0.command, enabled: toolbox) }
                    var build: [Double] = []
                    var render: [Double] = []
                    for _ in 0..<50 {
                        let start = ProcessInfo.processInfo.systemUptime
                        let nodes = MenuBuilder.build(input, settings: settings, environment: environment)
                        let built = ProcessInfo.processInfo.systemUptime
                        consumeIcons(nodes)
                        let rendered = ProcessInfo.processInfo.systemUptime
                        build.append((built - start) * 1_000)
                        render.append((rendered - built) * 1_000)
                    }
                    print("case=\(name) icons=\(icons) toolbox=\(toolbox) build_p50_ms=\(p50(build)) icon_p50_ms=\(p50(render)) build_p95_ms=\(p95(build)) icon_p95_ms=\(p95(render))")
                }
            }
        }
    }

    static func consumeIcons(_ nodes: [MenuNode]) {
        for node in nodes {
            switch node.icon {
            case .symbol(let name): _ = NSImage(systemSymbolName: name, accessibilityDescription: nil)
            case .fileType(let ext): _ = NSWorkspace.shared.icon(for: UTType(filenameExtension: ext) ?? .data)
            case .file(let path): _ = NSWorkspace.shared.icon(forFile: path)
            case .app(let id): _ = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
            case nil: break
            }
            consumeIcons(node.children)
        }
    }

    static func p50(_ samples: [Double]) -> Int { Int(samples.sorted()[samples.count / 2]) }
    static func p95(_ samples: [Double]) -> Int { Int(samples.sorted()[Int(Double(samples.count - 1) * 0.95)]) }
}
