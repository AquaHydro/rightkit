import Foundation
import Testing
@testable import RightKitCore

@Suite struct EnvelopeTests {
    func data(_ e: CommandEnvelope) throws -> Data { try e.encoded() }

    @Test func validRequestDecodes() throws {
        let e = CommandEnvelope(command: Command(.copyPath), folder: URL(filePath: "/Users/t/a b/", directoryHint: .isDirectory),
                                items: [URL(filePath: "/Users/t/a b/\"引号\"\n.txt")])
        let r = try CommandEnvelope.validate(try data(e))
        #expect(r.id == e.requestID && r.command == Command(.copyPath))
        #expect(r.items[0].path(percentEncoded: false) == "/Users/t/a b/\"引号\"\n.txt")
        #expect(r.folder?.hasDirectoryPath == true)
    }

    @Test func rejectsBadInput() throws {
        #expect(throws: EnvelopeError.tooLarge) { try CommandEnvelope.validate(Data(count: CommandEnvelope.maxEncodedSize + 1)) }
        #expect(throws: EnvelopeError.malformed) { try CommandEnvelope.validate(Data("{\"x\":1}".utf8)) }

        var old = CommandEnvelope(command: Command(.cut), folder: nil, items: [], sentAt: Date(timeIntervalSinceNow: -31))
        #expect(throws: EnvelopeError.expired) { try CommandEnvelope.validate(try data(old)) }
        old.sentAt = Date()
        old.schemaVersion = 2
        #expect(throws: EnvelopeError.unsupportedVersion) { try CommandEnvelope.validate(try data(old)) }

        for bad in ["https://example.com/a", "/etc/passwd", "file:///a/../etc/passwd", "file://evil.host/a", "file:///a%00b"] {
            var e = CommandEnvelope(command: Command(.cut), folder: nil, items: [])
            e.items = [bad]
            #expect(throws: EnvelopeError.invalidURL, "\(bad)") { try CommandEnvelope.validate(try data(e)) }
        }
    }

    @Test func virtualFolderIsDropped() throws {
        for virtual in ["x-apple-finder:recents", "https://example.com/a", "file:"] {
            let e = CommandEnvelope(command: Command(.copyTo), folder: URL(string: virtual), items: [URL(filePath: "/Users/t/a.txt")])
            #expect(e.folder == nil, "\(virtual)")
            let r = try CommandEnvelope.validate(try data(e))
            #expect(r.folder == nil && r.items.count == 1)
        }
    }

    @Test func unknownActionIsMalformed() throws {
        var json = try JSONSerialization.jsonObject(with: try data(CommandEnvelope(command: Command(.cut), folder: nil, items: []))) as! [String: Any]
        json["command"] = ["action": "rm -rf"]
        #expect(throws: EnvelopeError.malformed) { try CommandEnvelope.validate(try JSONSerialization.data(withJSONObject: json)) }
    }

    @Test func duplicatesAreIgnored() {
        var d = RequestDeduplicator()
        let id = UUID()
        let results = [d.accept(id), d.accept(id), d.accept(UUID())]
        #expect(results == [true, false, true])
    }
}

@Suite struct HashTests {
    // V-043
    @Test func fixtureVector() {
        var h = MultiHasher()
        h.update(Data("RightKit research fixture\n".utf8))
        let r = h.finalize()
        #expect(r.md5 == "e4456d16d449ba7863b647d453a943a8")
        #expect(r.sha1 == "b75630a2350283ae79e7783f3220d813556c3f6f")
        #expect(r.sha256 == "b498f016419a7033869370c685746066601370413988cf11760d56e6d01d32bb")
        #expect(r.sha512 == "d9c01d63a6f36102ca19b74e032fef0b95a5ef4d4b918ebd800b90090792a8769561b2f9e25edf09509955ecc91203cfa17d56a44ee81adc153be4349f5064c7")
    }

    @Test func emptyInput() {
        let r = MultiHasher().finalize()
        #expect(r.md5 == "d41d8cd98f00b204e9800998ecf8427e")
        #expect(r.sha1 == "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        #expect(r.sha256 == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(r.sha512.hasPrefix("cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce"))
    }

    @Test func chunkedEqualsWhole() {
        let bytes = Data((0..<10_000).map { UInt8($0 % 251) })
        var whole = MultiHasher(); whole.update(bytes)
        var chunked = MultiHasher()
        stride(from: 0, to: bytes.count, by: 777).forEach { chunked.update(bytes[$0..<min($0 + 777, bytes.count)]) }
        #expect(whole.finalize() == chunked.finalize())
    }
}

@Suite struct TranslationTests {
    @Test func encodesText() throws {
        let text = "a&b=c #d/中文\n"
        let google = try TranslationService.google.url(for: text, language: .simplifiedChinese).absoluteString
        #expect(google.contains("tl=zh-CN") && google.hasSuffix("text=a%26b%3Dc%20%23d%2F%E4%B8%AD%E6%96%87%0A"))
        let baidu = try TranslationService.baidu.url(for: "hi", language: .english).absoluteString
        #expect(baidu == "https://fanyi.baidu.com/#auto/en/hi")
    }

    @Test func rejectsLongText() {
        #expect(throws: TranslationService.Failure.tooLong) {
            try TranslationService.google.url(for: String(repeating: "中", count: 3000), language: .simplifiedChinese)
        }
    }
}

@Suite struct ChannelIdentifierTests {
    @Test func derivesEveryNameFromInfoPlist() throws {
        let info: [String: Any] = ["RKAppBundleID": "app.rightkit.mac.store",
                                   "RKAppGroup": "Q9C87Z9H4G.app.rightkit.mac.store",
                                   "RKURLScheme": "rightkit-store"]
        let ids = try #require(ChannelIdentifiers(infoDictionary: info))
        #expect(ids.extensionBundleID == "app.rightkit.mac.store.finder")
        #expect(ids.agentBundleID == "app.rightkit.mac.store.agent")
        #expect(ids.agentPlist == "app.rightkit.mac.store.agent.plist")
        #expect(ids.command == "Q9C87Z9H4G.app.rightkit.mac.store.command")
        #expect(ids.settingsChanged == "Q9C87Z9H4G.app.rightkit.mac.store.settings")
        #expect(ids.activationURL?.absoluteString == "rightkit-store://activate")
        #expect(ids.url(for: .agentUnavailable)?.absoluteString == "rightkit-store://agent-unavailable")
    }

    @Test func urlActionsRoundTripAndRejectOtherSchemes() throws {
        let ids = ChannelIdentifiers(appBundleID: "app.rightkit.mac", appGroup: "T.app.rightkit.mac", urlScheme: "rightkit")
        for action in AppURLAction.allCases {
            #expect(ids.action(of: try #require(ids.url(for: action))) == action)
        }
        for other in ["rightkit-store://activate", "rightkit://unknown", "https://activate", "rightkit:///activate"] {
            #expect(ids.action(of: try #require(URL(string: other))) == nil, "\(other)")
        }
    }

    @Test func missingOrEmptyKeysAreRejected() {
        let full: [String: Any] = ["RKAppBundleID": "app.rightkit.mac", "RKAppGroup": "Q9C87Z9H4G.app.rightkit.mac",
                                   "RKURLScheme": "rightkit"]
        #expect(ChannelIdentifiers(infoDictionary: full) != nil)
        for key in full.keys {
            var missing = full
            missing.removeValue(forKey: key)
            #expect(ChannelIdentifiers(infoDictionary: missing) == nil, "\(key)")
            var empty = full
            empty[key] = ""
            #expect(ChannelIdentifiers(infoDictionary: empty) == nil, "\(key)")
        }
    }
}
