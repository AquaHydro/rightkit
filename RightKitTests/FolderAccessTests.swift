import Foundation
import Testing
@testable import RightKitCore

/// F-080：授权判断。解析 security-scoped bookmark 需要沙盒签名，放在 V-080 真机验收里。
@Suite struct FolderAccessTests {
    @Test func grantedFolderCoversItsContentsOnly() {
        let access = FolderAccess()
        access.grant(URL(filePath: "/Users/tester/Projects", directoryHint: .isDirectory))
        #expect(access.isAuthorized(URL(filePath: "/Users/tester/Projects")))
        #expect(access.isAuthorized(URL(filePath: "/Users/tester/Projects/a b/c.txt")))
        #expect(!access.isAuthorized(URL(filePath: "/Users/tester/ProjectsX/c.txt")))
        #expect(!access.isAuthorized(URL(filePath: "/Users/tester/Desktop")))
    }

    @Test func firstUnauthorizedKeepsOrder() {
        let access = FolderAccess()
        access.grant(URL(filePath: "/Users/tester", directoryHint: .isDirectory))
        let inside = URL(filePath: "/Users/tester/a.txt")
        let outside = URL(filePath: "/Volumes/Work/b.txt")
        #expect(access.firstUnauthorized([inside]) == nil)
        #expect(access.firstUnauthorized([inside, outside, URL(filePath: "/tmp/c")]) == outside)
        #expect(access.firstUnauthorized([]) == nil)
    }

    @Test func rootIsNeverAuthorized() {
        let access = FolderAccess()
        access.grant(URL(filePath: "/", directoryHint: .isDirectory))
        #expect(!access.isAuthorized(URL(filePath: "/Users/tester/a.txt")))
    }

    @Test func entryWithoutBookmarkCannotBeActivated() {
        #expect(FolderAccess().activate(FolderEntry(path: "/Users/tester")) == nil)
    }

    @Test func filesystemAliasesKeepTheSameAuthorizationBoundary() throws {
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: base) }
        let root = base.appendingPathComponent("authorized")
        let child = root.appendingPathComponent("child")
        let outside = base.appendingPathComponent("outside")
        let alias = base.appendingPathComponent("alias")
        try fm.createDirectory(at: child, withIntermediateDirectories: true)
        try fm.createDirectory(at: outside, withIntermediateDirectories: true)
        try fm.createSymbolicLink(at: alias, withDestinationURL: root)
        let access = FolderAccess()
        access.grant(root)
        #expect(access.isAuthorized(alias))
        #expect(access.isAuthorized(alias.appendingPathComponent("child")))
        #expect(!access.isAuthorized(outside))
        #expect(!access.isAuthorized(base.appendingPathComponent("missing")))
        #expect(!FolderAccess().isAuthorized(alias))
    }

}
