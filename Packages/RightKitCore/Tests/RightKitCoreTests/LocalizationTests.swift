import Foundation
import Testing
@testable import RightKitCore

// Failure modes: regional system preferences, unsupported preferences, persisted old/new
// settings, missing resource bundles, format arguments, and user-authored names.
@Suite struct LocalizationTests {
    @Test(arguments: [
        (["ja-JP", "en-US"], "ja"),
        (["ko-KR", "ja-JP"], "ko"),
        (["fr-FR", "ko-KR", "en-US"], "ko"),
        (["en-GB", "ja-JP"], "en"),
        (["zh-Hans-CN", "en-US"], "zh-Hans"),
    ])
    func followsPreferredSupportedLanguage(preferences: [String], expected: String) {
        #expect(L10n.code(for: .system, preferences: preferences) == expected)
    }

    @Test func unsupportedPreferencesResolveToSupportedLanguage() {
        #expect(L10n.supported.contains(L10n.code(for: .system, preferences: ["fr-FR"])))
        #expect(L10n.supported.contains(L10n.code(for: .system, preferences: [])))
    }

    @Test(arguments: AppLanguage.allCases)
    func settingsRoundTrip(language: AppLanguage) throws {
        var settings = Settings()
        settings.language = language
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(Settings.self, from: data).language == language)
        #expect(settings.schemaVersion == Settings.currentSchemaVersion)
    }

    @Test func persistedIdentifiersStayCompatible() throws {
        for raw in ["system", "english", "simplifiedChinese"] {
            #expect(try JSONDecoder().decode(AppLanguage.self, from: Data("\"\(raw)\"".utf8)).rawValue == raw)
        }
    }

    @Test(arguments: [AppLanguage.japanese, .korean])
    func selectsResourceBundleAndFormatsArguments(language: AppLanguage) {
        L10n.$override.withValue(language) {
            #expect(L10n.code == language.localizationCode)
            #expect(L10n.language == language)
            #expect(L10n.bundle.bundleURL.lastPathComponent == "\(L10n.code).lproj")
            #expect(L("取消") == (language == .japanese ? "キャンセル" : "취소"))
            #expect(!L("彻底删除 %d 个项目？", 3).contains("%d"))
            #expect(L("彻底删除 %d 个项目？", 3).contains("3"))
            #expect(Naming.untitled(fileExtension: "txt") == (language == .japanese ? "名称未設定.txt" : "이름 없음.txt"))
        }
    }

    @Test(arguments: [AppLanguage.english, .simplifiedChinese, .japanese, .korean])
    func translationTargetsMatchLanguage(language: AppLanguage) throws {
        let googleCode = language == .simplifiedChinese ? "zh-CN" : try #require(language.localizationCode)
        let baiduCode = switch language {
        case .japanese: "jp"
        case .korean: "kor"
        case .simplifiedChinese: "zh"
        default: "en"
        }
        let text = "한글 日本語 & # /"
        let google = try TranslationService.google.url(for: text, language: language)
        let components = try #require(URLComponents(url: google, resolvingAgainstBaseURL: false))
        #expect(components.queryItems?.first { $0.name == "tl" }?.value == googleCode)
        #expect(components.queryItems?.first { $0.name == "text" }?.value == text)
        let baidu = try TranslationService.baidu.url(for: text, language: language)
        #expect(baidu.absoluteString.hasPrefix("https://fanyi.baidu.com/#auto/\(baiduCode)/"))
        #expect(baidu.fragment(percentEncoded: false) == "auto/\(baiduCode)/\(text)")
    }
}
