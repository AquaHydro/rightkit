import Foundation
import Synchronization

/// 按设置里的语言选择 `.lproj`，主程序和扩展共用（F-004）。
public enum L10n {
    public static let supported = ["zh-Hans", "en"]
    private static let current = Mutex<(code: String, bundle: Bundle)>(resolve(.system))

    public static func setLanguage(_ language: AppLanguage) {
        let resolved = resolve(language)
        current.withLock { $0 = resolved }
    }

    /// 只对当前任务生效的语言，测试用它避免互相干扰。
    @TaskLocal public static var override: AppLanguage?

    public static var code: String { override.map(code(for:)) ?? current.withLock { $0.code } }
    public static var bundle: Bundle { override.map { resolve($0).bundle } ?? current.withLock { $0.bundle } }
    public static var isChinese: Bool { code == "zh-Hans" }

    public static func code(for language: AppLanguage) -> String {
        switch language {
        case .english: "en"
        case .simplifiedChinese: "zh-Hans"
        case .system: Bundle.preferredLocalizations(from: supported, forPreferences: Locale.preferredLanguages).first ?? "zh-Hans"
        }
    }

    private static func resolve(_ language: AppLanguage) -> (code: String, bundle: Bundle) {
        let code = code(for: language)
        let bundle = Bundle.module.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? Bundle.module
        return (code, bundle)
    }
}

/// 取当前界面语言的文案。键就是简体中文原文，带 `%@`、`%d` 时按顺序填入参数。
public func L(_ key: String, _ arguments: any CVarArg...) -> String {
    let format = L10n.bundle.localizedString(forKey: key, value: key, table: nil)
    return arguments.isEmpty ? format : String(format: format, locale: Locale(identifier: L10n.code), arguments: arguments)
}
