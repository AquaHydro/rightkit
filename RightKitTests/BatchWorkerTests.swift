import Foundation
import Testing
@testable import RightKitCore

@Suite struct BatchWorkerTests {
    @Test func failedItemRemainsAvailableForRetry() throws {
        let dir = try TempDir()
        let a = try dir.file("a.txt")
        let b = try dir.file("b.txt")
        let c = try dir.file("c.txt")
        let target = try dir.folder("target")
        let outcome = BatchWorker.run([a, b, c], measure: false, progress: OperationProgress()) { item, progress in
            if item == b { throw FileEngineError.posix(EACCES) }
            _ = try FileEngine.transfer(item, to: target, mode: .move, progress: progress)
        }
        #expect(outcome.succeeded == 2 && outcome.failed == 1 && !outcome.cancelled)
        #expect(outcome.remaining == [b])
        #expect(dir.names("target") == ["a.txt", "c.txt"])
        #expect(FileManager.default.fileExists(atPath: b.path))
    }

    @Test func cancellationKeepsCurrentAndUnprocessedItems() throws {
        let dir = try TempDir()
        let a = try dir.file("a.txt")
        let b = try dir.file("b.txt")
        let c = try dir.file("c.txt")
        let target = try dir.folder("target")
        let progress = OperationProgress()
        let outcome = BatchWorker.run([a, b, c], measure: false, progress: progress) { item, progress in
            if item == b {
                progress.cancel()
                throw FileEngineError.cancelled
            }
            _ = try FileEngine.transfer(item, to: target, mode: .move, progress: progress)
        }
        #expect(outcome.succeeded == 1 && outcome.failed == 0 && outcome.cancelled)
        #expect(outcome.remaining == [b, c])
        #expect(dir.names("target") == ["a.txt"])
        #expect(FileManager.default.fileExists(atPath: b.path) && FileManager.default.fileExists(atPath: c.path))
    }

    @Test func successfulPasteHasNoRemainingItems() throws {
        let dir = try TempDir()
        let file = try dir.file("a.txt")
        let target = try dir.folder("target")
        let outcome = BatchWorker.run([file], measure: false, progress: OperationProgress()) { item, progress in
            _ = try FileEngine.transfer(item, to: target, mode: .move, progress: progress)
        }
        #expect(outcome.succeeded == 1 && outcome.remaining.isEmpty)
    }
}
