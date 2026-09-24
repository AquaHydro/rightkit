import Foundation

@main
struct TransferBenchmark {
    static func main() throws {
        let fileCount = CommandLine.arguments.dropFirst().first.flatMap(Int.init) ?? 10_000
        guard (1...100_000).contains(fileCount) else {
            fputs("Expected a file count between 1 and 100000.\n", stderr)
            exit(2)
        }

        let root = FileManager.default.temporaryDirectory.appending(path: "rightkit-benchmark-\(UUID().uuidString)")
        let source = root.appending(path: "source")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let bytes = Data(repeating: 0x41, count: 1_024)
        for index in 0..<fileCount {
            try bytes.write(to: source.appending(path: String(format: "%06d.dat", index)))
        }

        for iteration in 1...3 {
            let target = root.appending(path: "target-\(iteration)")
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
            let start = ProcessInfo.processInfo.systemUptime
            let total = FileEngine.size(of: source)
            let scan = ProcessInfo.processInfo.systemUptime
            _ = try FileEngine.transfer(source, to: target, mode: .copy, progress: nil)
            let copied = ProcessInfo.processInfo.systemUptime
            print("iteration=\(iteration) files=\(fileCount) bytes=\(total) scan_ms=\(Int((scan - start) * 1000)) copy_ms=\(Int((copied - scan) * 1000))")
        }
    }
}
