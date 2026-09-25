#if !APP_STORE
import Foundation

/// F-081 检查更新的纯逻辑：解析 GitHub 最新 Release、比较版本、决定要不要提示。只有官网版编译。
enum UpdateCheck {
    static let latestReleaseURL = URL(string: "https://api.github.com/repos/AquaHydro/rightkit/releases/latest")!
    /// 自动检查的最短间隔。
    static let interval: TimeInterval = 24 * 60 * 60

    enum Outcome: Equatable {
        case available(version: String, page: URL)
        case upToDate
        case failed
    }

    struct Version: Comparable {
        let components: [Int]

        /// `1.2.3` 或 `v1.2.3`。预发布后缀、缺位或非数字都算格式错误。
        init?(_ text: String) {
            let trimmed = text.hasPrefix("v") ? String(text.dropFirst()) : text
            let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count == 3 else { return nil }
            var numbers: [Int] = []
            for part in parts {
                guard !part.isEmpty, part.allSatisfy(\.isASCII), part.allSatisfy(\.isNumber), let number = Int(part) else { return nil }
                numbers.append(number)
            }
            components = numbers
        }

        var text: String { components.map(String.init).joined(separator: ".") }

        static func < (lhs: Version, rhs: Version) -> Bool { lhs.components.lexicographicallyPrecedes(rhs.components) }
    }

    private struct Release: Decodable {
        let tagName: String
        let htmlURL: URL
        let draft: Bool
        let prerelease: Bool

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name", htmlURL = "html_url", draft, prerelease
        }
    }

    /// `data` 是 releases/latest 的响应。草稿、预发布、标签格式错误和不在本仓库下的网页都算失败。
    static func evaluate(_ data: Data, currentVersion: String) -> Outcome {
        guard let release = try? JSONDecoder().decode(Release.self, from: data),
              !release.draft, !release.prerelease,
              let latest = Version(release.tagName),
              let current = Version(currentVersion),
              release.htmlURL.scheme == "https", release.htmlURL.host() == "github.com",
              release.htmlURL.path(percentEncoded: false).hasPrefix("/AquaHydro/rightkit/releases/")
        else { return .failed }
        return latest > current ? .available(version: latest.text, page: release.htmlURL) : .upToDate
    }

    static func isDue(lastCheck: Date?, now: Date = Date()) -> Bool {
        guard let lastCheck else { return true }
        return now.timeIntervalSince(lastCheck) >= interval || lastCheck > now
    }

    /// 自动检查里被点过「稍后」的版本不再提示；手动检查照常提示。
    static func shouldPrompt(_ outcome: Outcome, automatic: Bool, dismissedVersion: String?) -> Bool {
        switch outcome {
        case .available(let version, _): !automatic || version != dismissedVersion
        case .upToDate, .failed: !automatic
        }
    }
}
#endif
