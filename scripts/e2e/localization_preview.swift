// Isolated visual QA: production views/model, in-memory settings, no app delegate,
// LaunchAgent, Finder extension registration, installed configuration or updates.
import AppKit
import RightKitCore
import SwiftUI

// Replace only persistence; AppModel and all displayed views remain production code.
enum SharedStore {
    enum LoadResult { case loaded(RightKitCore.Settings), missing, unreadable(backup: URL?) }
    static let directory = URL.temporaryDirectory.appending(path: "rightkit-localization-preview")
    static func loadSettings(backupOnFailure: Bool) -> LoadResult {
        var settings = RightKitCore.Settings()
        settings.language = CommandLine.arguments.contains("ko") ? .korean : .japanese
        settings.welcomeShown = true
        settings.showMenuBarIcon = false
        return .loaded(settings)
    }
    static func save(_ settings: RightKitCore.Settings) throws {}
    static func loadPending() -> [String] { [] }
    static func savePending(_ paths: [String]) throws {}
    static func heartbeatIsAlive() -> Bool { false }
}

@main struct LocalizationPreview: App {
    @State private var model: AppModel
    private let windows = WindowOpener()

    init() {
        setenv("RIGHTKIT_SKIP_LOGIN_ITEM", "1", 1)
        _model = State(initialValue: AppModel())
    }

    var body: some Scene {
        Window("RightKit Localization Preview", id: "preview") {
            SettingsView().environment(model)
        }
        .windowToolbarStyle(.unified)
        .windowResizability(.contentMinSize)
        .restorationBehavior(.disabled)
        .defaultSize(width: 640, height: 620)
        Window("Welcome Preview", id: WindowID.welcome) {
            WelcomeView(windows: windows).environment(model)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(.presented)
    }
}
