import Foundation
import Testing

/// V-081：检查更新的六种结果用注入的响应测试，不访问网络。
@Suite struct UpdateCheckTests {
    func release(_ tag: String, draft: Bool = false, prerelease: Bool = false,
                 page: String = "https://github.com/AquaHydro/rightkit/releases/tag/v9.9.9") -> Data {
        Data("""
        {"tag_name": "\(tag)", "html_url": "\(page)", "draft": \(draft), "prerelease": \(prerelease)}
        """.utf8)
    }

    @Test func newerReleaseIsAvailable() throws {
        let outcome = UpdateCheck.evaluate(release("v0.2.0"), currentVersion: "0.1.1")
        #expect(outcome == .available(version: "0.2.0", page: try #require(URL(string: "https://github.com/AquaHydro/rightkit/releases/tag/v9.9.9"))))
        #expect(UpdateCheck.evaluate(release("0.1.10"), currentVersion: "0.1.9") != .upToDate, "按数字比较，不按字符串")
    }

    @Test func sameOrOlderIsUpToDate() {
        #expect(UpdateCheck.evaluate(release("v0.1.1"), currentVersion: "0.1.1") == .upToDate)
        #expect(UpdateCheck.evaluate(release("v0.1.0"), currentVersion: "0.1.1") == .upToDate)
    }

    @Test func badReleasesFail() {
        #expect(UpdateCheck.evaluate(release("v0.2.0", prerelease: true), currentVersion: "0.1.1") == .failed)
        #expect(UpdateCheck.evaluate(release("v0.2.0", draft: true), currentVersion: "0.1.1") == .failed)
        for tag in ["v0.2", "0.2.0-beta", "latest", "v0..1", "v1.2.3.4", "v١.2.3"] {
            #expect(UpdateCheck.evaluate(release(tag), currentVersion: "0.1.1") == .failed, "\(tag)")
        }
        #expect(UpdateCheck.evaluate(release("v0.2.0", page: "https://evil.example/AquaHydro/rightkit/releases/x"), currentVersion: "0.1.1") == .failed)
        #expect(UpdateCheck.evaluate(release("v0.2.0", page: "http://github.com/AquaHydro/rightkit/releases/x"), currentVersion: "0.1.1") == .failed)
        #expect(UpdateCheck.evaluate(release("v0.2.0", page: "https://github.com/someone/else/releases/x"), currentVersion: "0.1.1") == .failed)
        #expect(UpdateCheck.evaluate(Data("not json".utf8), currentVersion: "0.1.1") == .failed)
        #expect(UpdateCheck.evaluate(release("v0.2.0"), currentVersion: "") == .failed)
    }

    @Test func dueAfterADay() {
        let now = Date()
        #expect(UpdateCheck.isDue(lastCheck: nil, now: now))
        #expect(!UpdateCheck.isDue(lastCheck: now.addingTimeInterval(-3600), now: now))
        #expect(UpdateCheck.isDue(lastCheck: now.addingTimeInterval(-UpdateCheck.interval), now: now))
        #expect(UpdateCheck.isDue(lastCheck: now.addingTimeInterval(3600), now: now), "时钟回拨时照常检查")
    }

    @Test func promptRules() throws {
        let page = try #require(URL(string: "https://github.com/AquaHydro/rightkit/releases/tag/v0.2.0"))
        let available = UpdateCheck.Outcome.available(version: "0.2.0", page: page)
        #expect(UpdateCheck.shouldPrompt(available, automatic: true, dismissedVersion: nil))
        #expect(!UpdateCheck.shouldPrompt(available, automatic: true, dismissedVersion: "0.2.0"), "自动检查不再提示点过稍后的版本")
        #expect(UpdateCheck.shouldPrompt(available, automatic: true, dismissedVersion: "0.1.9"))
        #expect(UpdateCheck.shouldPrompt(available, automatic: false, dismissedVersion: "0.2.0"), "手动检查照常提示")
        #expect(!UpdateCheck.shouldPrompt(.upToDate, automatic: true, dismissedVersion: nil))
        #expect(!UpdateCheck.shouldPrompt(.failed, automatic: true, dismissedVersion: nil))
        #expect(UpdateCheck.shouldPrompt(.upToDate, automatic: false, dismissedVersion: nil))
        #expect(UpdateCheck.shouldPrompt(.failed, automatic: false, dismissedVersion: nil))
    }
}
