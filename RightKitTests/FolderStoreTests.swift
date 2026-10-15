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

    /// F-084：只有 `-54` 才换成完全磁盘访问提示，包在外层错误里也要认出来。
    @Test func otherAppDataDeniedMatchesOnlyPermErr() {
        let denied = NSError(domain: NSOSStatusErrorDomain, code: -54)
        #expect(FolderStore.isOtherAppDataDenied(denied))
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError,
                              userInfo: [NSUnderlyingErrorKey: denied])
        #expect(FolderStore.isOtherAppDataDenied(wrapped))
        #expect(!FolderStore.isOtherAppDataDenied(NSError(domain: NSOSStatusErrorDomain, code: -10814)))
        #expect(!FolderStore.isOtherAppDataDenied(NSError(domain: NSPOSIXErrorDomain, code: -54)))
        #expect(!FolderStore.isOtherAppDataDenied(CocoaError(.fileReadNoPermission)))
    }
}
