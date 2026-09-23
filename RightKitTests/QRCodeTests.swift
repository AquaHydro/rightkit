import Foundation
import Testing

/// V-060
@Suite struct QRCodeTests {
    @Test(arguments: ["https://example.com/?q=a&b=1", "中文与 emoji 😀 以及换行\n第二行", String(repeating: "长", count: 300)])
    func roundTrips(text: String) throws {
        let image = try #require(QRCode.image(for: text))
        #expect(QRCode.decode(image) == text)
        #expect(QRCode.pngData(for: text)?.starts(with: [0x89, 0x50, 0x4E, 0x47]) == true)
    }

    @Test func emptyTextHasNoImage() {
        #expect(QRCode.image(for: "") == nil)
        #expect(QRCode.pngData(for: "") == nil)
    }
}
