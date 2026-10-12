// Isolated production settings Window. SharedStore is memory-only; no production AppDelegate,
// agent, extension registration, installed settings, or system-action buttons.
import AppKit
import Observation
import QuartzCore
import RightKitCore
import SwiftUI

enum SharedStore {
    enum LoadResult { case loaded(RightKitCore.Settings), missing, unreadable(backup: URL?) }
    static let directory = URL.temporaryDirectory.appending(path: "rightkit-settings-perf-" + UUID().uuidString)
    static func loadSettings(backupOnFailure: Bool) -> LoadResult {
        var settings = RightKitCore.Settings()
        settings.language = .simplifiedChinese
        settings.welcomeShown = true
        settings.showMenuBarIcon = false
        return .loaded(settings)
    }
    static func save(_ settings: RightKitCore.Settings) throws {}
    static func loadPending() -> [String] { [] }
    static func savePending(_ paths: [String]) throws {}
    static func heartbeatIsAlive() -> Bool { false }
}

@MainActor enum ProbeMetric {
    static func argument(_ name: String, fallback: String) -> String {
        guard let index = CommandLine.arguments.firstIndex(of: name), index + 1 < CommandLine.arguments.count else { return fallback }
        return CommandLine.arguments[index + 1]
    }
    static let suite = argument("--suite", fallback: "app.rightkit.settings-probe." + UUID().uuidString)
    static let defaults = UserDefaults(suiteName: suite)!
    static let interactive = CommandLine.arguments.contains("--interactive") || !CommandLine.arguments.contains("--output")
    static var displayedTab = ""
    static var totals: [String: Double] = [:]
    static var counts: [String: Int] = [:]
    static var folderStates: [String: String] = [:]
    static var hasRun = false
    static var cleanupObserver: NSObjectProtocol?
    static func mark(_ key: String) { counts[key, default: 0] += 1 }
    static func recordFolder(_ path: String, state: FolderStore.State) { folderStates[path] = String(describing: state) }
    static func measure<T>(_ key: String, _ operation: () -> T) -> T {
        let start = CACurrentMediaTime()
        let value = operation()
        totals[key, default: 0] += (CACurrentMediaTime() - start) * 1000
        counts[key, default: 0] += 1
        return value
    }
    static func fixture() -> AppModel {
        setenv("RIGHTKIT_SKIP_LOGIN_ITEM", "1", 1)
        defaults.removePersistentDomain(forName: suite)
        defaults.set("general", forKey: "settingsTab")
        let model = AppModel()
        let paths = (0..<12).map { SharedStore.directory.appending(path: "folder\($0)") }
        for url in paths { try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) }
        // Real bookmarks for only our own local temporary directories.
        let entries = paths.map { FolderStore.entry(for: $0) }
        model.settings.monitoredFolders = Array(entries.prefix(3))
        model.settings.favorites = Array(entries.prefix(6))
        model.settings.sendTo = Array(entries.suffix(6))
        model.settings.openTools = [
            OpenTool(bundleID: "com.apple.Terminal", name: "Terminal", role: .terminal),
            OpenTool(bundleID: "com.apple.TextEdit", name: "TextEdit", role: .editor),
            OpenTool(bundleID: "com.microsoft.VSCode", name: "VS Code", role: .editor),
        ]
        cleanupObserver = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                defaults.removePersistentDomain(forName: suite)
                try? FileManager.default.removeItem(at: SharedStore.directory)
            }
        }
        return model
    }
    static func nextTurn() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
    static func layout(_ window: NSWindow) {
        window.contentView?.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        CATransaction.flush()
    }
    static func switchTo(_ tab: SettingsTab, window: NSWindow) async -> Double {
        let start = CACurrentMediaTime()
        defaults.set(tab.rawValue, forKey: "settingsTab")
        layout(window)
        await nextTurn()
        layout(window)
        // Some AppStorage observations are deferred. Include that delay instead
        // of accidentally measuring a no-op. The marker observes production tab.
        for _ in 0..<30 where displayedTab != tab.rawValue {
            await nextTurn()
            layout(window)
        }
        guard displayedTab == tab.rawValue else {
            fputs("Tab did not update to \(tab.rawValue)\n", stderr)
            return .infinity
        }
        return (CACurrentMediaTime() - start) * 1000
    }
    static func screenshot(_ window: NSWindow, to url: URL) throws -> Data {
        guard let view = window.contentView,
              let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            throw NSError(domain: "SettingsProbe", code: 1)
        }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "SettingsProbe", code: 2)
        }
        try data.write(to: url)
        return data
    }
    static func run(_ model: AppModel) async {
        guard !hasRun, !interactive else { return }
        hasRun = true
        do {
            try await Task.sleep(for: .milliseconds(700))
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else {
                throw NSError(domain: "SettingsProbe", code: 3)
            }
            let output = URL(filePath: argument("--output", fallback: "/tmp/rightkit-settings-perf.json"))
            let rounds = Int(argument("--rounds", fallback: "20")) ?? 20
            var samples: [[String: Any]] = []
            var assertions: [[String: Any]] = []
            var chineseImage = Data()
            for round in 0...rounds {
                for tab in SettingsTab.allCases {
                    // Initial general is already selected, so exclude its no-op.
                    if round == 0, tab == .general { continue }
                    totals = [:]; counts = [:]
                    let elapsed = await switchTo(tab, window: window)
                    guard elapsed.isFinite else { throw NSError(domain: "SettingsProbe.tab-update", code: 4) }
                    let queryTimes = totals, queryCounts = counts
                    try await Task.sleep(for: .milliseconds(150))
                    let selected = displayedTab == tab.rawValue
                    assertions.append(["check": "tab-selected", "round": round, "tab": tab.rawValue, "passed": selected])
                    samples.append(["round": round, "tab": tab.rawValue, "layout_display_ms": elapsed,
                                    "query_ms": queryTimes, "query_count": queryCounts, "selected": selected])
                    if round == 0 {
                        let image = try screenshot(window, to: URL(filePath: output.path + "." + tab.rawValue + ".png"))
                        if tab == .newFile { chineseImage = image }
                    }
                }
            }
            // Refresh a previously cached page after language change.
            _ = await switchTo(.newFile, window: window)
            model.settings.language = .english
            layout(window)
            try await Task.sleep(for: .milliseconds(300))
            layout(window)
            let englishImage = try screenshot(window, to: URL(filePath: output.path + ".english.png"))
            assertions.append(["check": "language-bitmap-diff", "passed": !englishImage.isEmpty && englishImage != chineseImage])
            assertions.append(["check": "english-title-accessible", "status": "manual_required",
                               "reason": "NSHostingView local AX getters cannot reliably expose SwiftUI leaf text; inspect with external accessibility or screenshots"])
            // Delete only our own test folder while its page is inactive. On
            // return, FolderRow must show missing instead of a retained stale row.
            // Language invalidation discards earlier cached hosts. Mount the
            // folders page again before leaving and deleting its test directory.
            _ = await switchTo(.folders, window: window)
            try await Task.sleep(for: .milliseconds(150))
            layout(window)
            _ = await switchTo(.toolbox, window: window)
            let deleted = model.settings.favorites[0].path
            try FileManager.default.removeItem(atPath: deleted)
            folderStates = [:]
            _ = await switchTo(.folders, window: window)
            try await Task.sleep(for: .milliseconds(300))
            layout(window)
            let refreshedState = folderStates[deleted] ?? "not-rendered"
            assertions.append(["check": "deleted-folder-refresh", "passed": refreshedState == "missing", "observed": refreshedState])
            _ = try screenshot(window, to: URL(filePath: output.path + ".deleted-folder.png"))
            let data = try JSONSerialization.data(withJSONObject: [
                "samples": samples, "assertions": assertions,
                "succeeded": !assertions.contains(where: { ($0["passed"] as? Bool) == false }),
                "language_check_limit": "Bitmap difference is a smoke check. Translated copy semantics requires external accessibility or screenshot review; local AX semantic assertion is explicitly manual_required",
                "os": ProcessInfo.processInfo.operatingSystemVersionString,
                "window_content_size": [window.contentView!.bounds.width, window.contentView!.bounds.height],
                "fixture": "3 monitored,6 favorites,6 sendTo,real local folder bookmarks,3 apps,stock newItems/toolbox",
                "measurement": "AppStorage assignment through next-main-turn layout/display-return; not compositor presentation",
            ], options: [.prettyPrinted, .sortedKeys])
            try data.write(to: output)
            if assertions.contains(where: { ($0["passed"] as? Bool) == false }) {
                fputs("Probe assertions failed; inspect JSON\n", stderr)
            }
            NSApp.terminate(nil)
        } catch {
            fputs("Settings probe failed: \(error)\n", stderr)
            let output = URL(filePath: argument("--output", fallback: "/tmp/rightkit-settings-perf.json"))
            if let data = try? JSONSerialization.data(withJSONObject: ["succeeded": false, "error": String(describing: error)], options: [.prettyPrinted]) { try? data.write(to: output) }
            NSApp.terminate(nil)
        }
    }
}

// Preview-only lifecycle delegate; never calls production service integration.
@MainActor final class PreviewLifecycleDelegate: NSObject, NSApplicationDelegate {
    static var reopen: (() -> Void)?
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows { Self.reopen?() }
        return true
    }
}

private struct SettingsProbeRoot: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        SettingsView()
            .environment(model)
            .defaultAppStorage(ProbeMetric.defaults)
            .onAppear { PreviewLifecycleDelegate.reopen = { openWindow(id: "settings-probe") } }
            .task { await ProbeMetric.run(model) }
    }
}

@main struct SettingsPerformancePreview: App {
    @NSApplicationDelegateAdaptor(PreviewLifecycleDelegate.self) private var lifecycle
    @State private var model: AppModel
    init() { _model = State(initialValue: ProbeMetric.fixture()) }
    var body: some Scene {
        Window("RightKit Settings Probe", id: "settings-probe") {
            SettingsProbeRoot(model: model)
        }
        .windowToolbarStyle(.unified)
        .windowResizability(.contentMinSize)
        .restorationBehavior(.disabled)
        .defaultSize(width: 640, height: 620)
    }
}
