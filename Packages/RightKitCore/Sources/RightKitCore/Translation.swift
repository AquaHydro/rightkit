import Foundation

/// F-071 翻译网址。
public enum TranslationService: String, CaseIterable, Sendable {
    case google, baidu

    public static let maxURLLength = 8000

    public enum Failure: Error, Equatable { case tooLong }

    /// 目标语言跟随界面语言，源语言自动检测。
    public func url(for text: String, language: AppLanguage) throws(Failure) -> URL {
        // 只保留非保留字符，其余全部百分号编码，`&`、`#`、`/` 等都不会破坏网址。
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let encoded = text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let code = L10n.code(for: language)
        let target = switch (self, code) {
        case (.google, "zh-Hans"): "zh-CN"
        case (.baidu, "zh-Hans"): "zh"
        case (.baidu, "ja"): "jp"
        case (.baidu, "ko"): "kor"
        default: code
        }
        let string = switch self {
        case .google: "https://translate.google.com/?sl=auto&tl=\(target)&op=translate&text=\(encoded)"
        case .baidu: "https://fanyi.baidu.com/#auto/\(target)/\(encoded)"
        }
        guard string.count <= Self.maxURLLength, let url = URL(string: string) else { throw .tooLong }
        return url
    }
}
