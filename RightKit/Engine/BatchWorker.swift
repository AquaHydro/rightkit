import Foundation

/// 后台逐项执行，保留失败和取消后尚未处理的项目，供剪切粘贴重试。
enum BatchWorker {
    struct Outcome: Sendable {
        var succeeded = 0
        var failed = 0
        var remaining: [URL] = []
        var cancelled = false
    }

    static func run(_ items: [URL], measure: Bool, progress: OperationProgress,
                    work: @Sendable (URL, OperationProgress) throws -> Void) -> Outcome {
        if measure {
            progress.addTotal(items.reduce(0) { $0 + FileEngine.size(of: $1) })
        } else {
            progress.addTotal(Int64(items.count))
        }

        var outcome = Outcome()
        for (index, item) in items.enumerated() {
            if progress.isCancelled {
                outcome.remaining.append(contentsOf: items[index...])
                break
            }
            progress.setCurrent(item.lastPathComponent)
            do {
                try work(item, progress)
                outcome.succeeded += 1
            } catch FileEngineError.cancelled {
                outcome.remaining.append(contentsOf: items[index...])
                break
            } catch {
                outcome.failed += 1
                outcome.remaining.append(item)
            }
            if !measure { progress.addCompleted(1) }
        }
        outcome.cancelled = progress.isCancelled
        return outcome
    }
}
