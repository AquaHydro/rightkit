import Foundation

/// F-071 翻译网址。
public enum TranslationService: String, CaseIterable, Sendable {
    case google, baidu

    public static let maxURLLength = 8000

    public enum Failure: Error, Equatable { case tooLong }

    /// 目标语言跟随界面语言，源语言自动检测。
    public func url(for text: String, chineseTarget: Bool) throws(Failure) -> URL {
        // 只保留非保留字符，其余全部百分号编码，`&`、`#`、`/` 等都不会破坏网址。
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let encoded = text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let string = switch self {
        case .google: "https://translate.google.com/?sl=auto&tl=\(chineseTarget ? "zh-CN" : "en")&op=translate&text=\(encoded)"
        case .baidu: "https://fanyi.baidu.com/#auto/\(chineseTarget ? "zh" : "en")/\(encoded)"
        }
        guard string.count <= Self.maxURLLength, let url = URL(string: string) else { throw .tooLong }
        return url
    }
}
