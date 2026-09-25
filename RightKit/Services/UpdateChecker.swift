#if !APP_STORE
import AppKit
import os
import RightKitCore

/// F-081：官网版检查更新。有新版本时只打开 Release 网页，不下载也不安装任何文件。
/// 开关和检查记录只有主程序用，放在主程序自己的 UserDefaults 里，不进共享设置。
@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()
    static let autoCheckKey = "autoCheckUpdates"
    private static let lastCheckKey = "lastUpdateCheck"
    private static let dismissedKey = "dismissedUpdateVersion"

    private let log = Logger(subsystem: ServiceNames.appBundleID, category: "update")
    private var isChecking = false
    private let defaults = UserDefaults.standard

    /// 「自动检查更新」默认开。
    var automaticChecksEnabled: Bool { defaults.object(forKey: Self.autoCheckKey) as? Bool ?? true }

    /// 启动后调用：开关打开且距上次检查超过 24 小时才检查。
    func checkAutomaticallyIfDue() {
        guard automaticChecksEnabled, UpdateCheck.isDue(lastCheck: defaults.object(forKey: Self.lastCheckKey) as? Date) else { return }
        Task { await check(automatic: true) }
    }

    /// 关于弹出层的「检查更新…」。
    func checkNow() {
        Task { await check(automatic: false) }
    }

    private func check(automatic: Bool) async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        let outcome = await fetch()
        if outcome != .failed { defaults.set(Date(), forKey: Self.lastCheckKey) }
        guard UpdateCheck.shouldPrompt(outcome, automatic: automatic, dismissedVersion: defaults.string(forKey: Self.dismissedKey)) else { return }
        switch outcome {
        case .available(let version, let page):
            present(version: version, page: page, automatic: automatic)
        case .upToDate:
            Alerts.show(L("RightKit 已是最新版本。"), style: .informational)
        case .failed:
            Alerts.show(L("无法检查更新。"))
        }
    }

    private func fetch() async -> UpdateCheck.Outcome {
        var request = URLRequest(url: UpdateCheck.latestReleaseURL, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("RightKit/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return .failed }
            return UpdateCheck.evaluate(data, currentVersion: currentVersion)
        } catch {
            log.error("Update check failed: \(error.localizedDescription, privacy: .public)")
            return .failed
        }
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func present(version: String, page: URL, automatic: Bool) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L("RightKit %@ 可用", version)
        alert.informativeText = L("你正在使用 %@。前往下载页面获取新版本。", currentVersion)
        alert.addButton(withTitle: L("前往下载"))
        alert.addButton(withTitle: L("稍后"))
        if Alerts.run(alert) == .alertFirstButtonReturn {
            NSWorkspace.shared.open(page)
        } else if automatic {
            defaults.set(version, forKey: Self.dismissedKey)
        }
    }
}
#endif
