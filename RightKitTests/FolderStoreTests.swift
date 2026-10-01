import Foundation
import Testing
import RightKitCore

/// F-080：真实临时目录覆盖丢失、权限拒绝和授权恢复，不读取用户设置。
@Suite struct FolderStoreTests {
    @Test func missingIsDifferentFromDenied() throws {
        let dir = try TempDir()
        let parent = try dir.folder("locked")
        let child = try dir.folder("locked/child")
        let entry = FolderEntry(path: child.path(percentEncoded: false))
        #expect(FolderStore.state(entry) == .available)
        #expect(chmod(parent.path(percentEncoded: false), 0o000) == 0)
        defer { chmod(parent.path(percentEncoded: false), 0o755) }
        #expect(FolderStore.state(entry) == .needsAuthorization)
        #expect(chmod(parent.path(percentEncoded: false), 0o755) == 0)
        #expect(FolderStore.state(entry) == .available)
        try FileManager.default.removeItem(at: child)
        #expect(FolderStore.state(entry) == .missing)
    }

    @Test func invalidBookmarkKeepsRecoveryEvenWhenMetadataIsReadable() throws {
        let dir = try TempDir()
        var entry = FolderEntry(path: dir.url.path(percentEncoded: false))
        entry.needsAuthorization = true
        #expect(FolderStore.state(entry) == .needsAuthorization)
        entry.needsAuthorization = false
        #expect(FolderStore.state(entry) == .available)
        let file = try dir.file("not-a-folder")
        #expect(FolderStore.state(FolderEntry(path: file.path(percentEncoded: false))) == .missing)
    }
}
