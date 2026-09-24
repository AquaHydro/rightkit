import Foundation
import Testing
@testable import RightKitCore

@Suite struct TemplateLibraryTests {
    @Test func importStoresIndependentCopyWithRequestedName() throws {
        let dir = try TempDir()
        let source = try dir.file("source/report.txt", "original")
        let library = try dir.folder("library")

        let template = try TemplateLibrary.importTemplate(
            from: source,
            name: "周报",
            into: library,
            progress: OperationProgress()
        )

        try Data("changed".utf8).write(to: source)
        #expect(template.name == "周报")
        #expect(template.fileExtension == "txt")
        #expect(try String(contentsOf: library.appending(path: template.storedFileName), encoding: .utf8) == "original")
        #expect(libraryContents(library).count == 1)
        #expect(!libraryContents(library).contains { $0.hasPrefix(FileEngine.tempPrefix) })
    }

    @Test func missingSourceFailsWithoutLeavingTemplate() throws {
        let dir = try TempDir()
        let library = try dir.folder("library")

        #expect(throws: (any Error).self) {
            try TemplateLibrary.importTemplate(
                from: dir.url.appending(path: "missing.txt"),
                into: library,
                progress: OperationProgress()
            )
        }
        #expect(libraryContents(library).isEmpty)
    }

    @Test func cancelledImportDoesNotCopyOrLeavePartialTemplate() throws {
        let dir = try TempDir()
        let source = try dir.file("large.bin", String(repeating: "x", count: 1_000_000))
        let library = try dir.folder("library")
        let progress = OperationProgress()
        progress.cancel()

        #expect(throws: FileEngineError.cancelled) {
            try TemplateLibrary.importTemplate(from: source, into: library, progress: progress)
        }
        #expect(libraryContents(library).isEmpty)
    }

    @Test func cancellingAsyncImportDoesNotCommitTemplate() async throws {
        let dir = try TempDir()
        let source = try dir.file("large.bin", String(repeating: "x", count: 1_000_000))
        let library = try dir.folder("library")
        let task = Task {
            try await TemplateLibrary.importTemplate(from: source, into: library)
        }
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("取消后的导入不应成功")
        } catch is CancellationError {
        } catch FileEngineError.cancelled {
        } catch {
            Issue.record("取消应返回取消错误，实际为：\(error)")
        }
        #expect(libraryContents(library).isEmpty)
    }

    @Test func cancellationAfterCopyRemovesCompletedTemplate() async throws {
        let dir = try TempDir()
        let source = try dir.file("template.txt", "complete")
        let library = try dir.folder("library")
        let gate = ImportReturnGate()
        let task = Task {
            try await TemplateLibrary.importTemplate(from: source, into: library, _beforeReturningForTesting: {
                await gate.pauseBeforeReturn()
            })
        }

        await gate.waitUntilPaused()
        #expect(libraryContents(library).count == 1, "复制完成但尚未返回给界面")
        task.cancel()
        await gate.resume()

        do {
            _ = try await task.value
            Issue.record("复制完成后取消也不应提交模板")
        } catch is CancellationError {
        } catch {
            Issue.record("复制完成后取消应返回 CancellationError，实际为：\(error)")
        }
        #expect(libraryContents(library).isEmpty, "取消会回滚已复制但尚未加入设置的副本")
    }

    @Test func repeatedImportsUseIndependentStoredFiles() throws {
        let dir = try TempDir()
        let source = try dir.file("template.md", "# Template")
        let library = try dir.folder("library")

        let first = try TemplateLibrary.importTemplate(from: source, into: library, progress: OperationProgress())
        let second = try TemplateLibrary.importTemplate(from: source, into: library, progress: OperationProgress())

        #expect(first.storedFileName != second.storedFileName)
        #expect(libraryContents(library).sorted() == [first.storedFileName, second.storedFileName].sorted())
    }

    private func libraryContents(_ library: URL) -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: library.path(percentEncoded: false))) ?? []
    }
}

private actor ImportReturnGate {
    private var paused = false
    private var pauseWaiters: [CheckedContinuation<Void, Never>] = []
    private var resumeWaiter: CheckedContinuation<Void, Never>?

    func pauseBeforeReturn() async {
        paused = true
        pauseWaiters.forEach { $0.resume() }
        pauseWaiters.removeAll()
        await withCheckedContinuation { resumeWaiter = $0 }
    }

    func waitUntilPaused() async {
        guard !paused else { return }
        await withCheckedContinuation { pauseWaiters.append($0) }
    }

    func resume() {
        resumeWaiter?.resume()
        resumeWaiter = nil
    }
}
