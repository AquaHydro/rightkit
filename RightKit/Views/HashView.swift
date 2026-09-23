import RightKitCore
import SwiftUI

/// F-049 哈希窗口：主程序后台流式计算，关窗即取消。
struct HashView: View {
    let url: URL
    @State private var state = LoadState.computing

    enum LoadState {
        case computing
        case done(FileHashes)
        case failed(String)
    }

    private var size: String {
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(url.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Spacer()
                Text(size)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            switch state {
            case .computing:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(L("正在计算哈希…")).foregroundStyle(.secondary)
                }
                .frame(width: 560, alignment: .leading)
            case .done(let hashes):
                Form {
                    ForEach(FileHashes.Algorithm.allCases, id: \.self) { algorithm in
                        HashRow(algorithm: algorithm, value: hashes.value(algorithm))
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
                .frame(width: 560)
                .fixedSize(horizontal: false, vertical: true)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 560, alignment: .leading)
            }
        }
        .padding(20)
        .animation(.default, value: stateKey)
        .task(id: url) { await compute() }
    }

    private var stateKey: Int {
        switch state {
        case .computing: 0
        case .done: 1
        case .failed: 2
        }
    }

    private func compute() async {
        state = .computing
        let url = self.url
        let task = Task.detached(priority: .userInitiated) { () -> Result<FileHashes, Tools.HashError> in
            Result { () throws(Tools.HashError) -> FileHashes in try Tools.hashFile(url) }
        }
        let result = await withTaskCancellationHandler { await task.value } onCancel: { task.cancel() }
        switch result {
        case .success(let hashes): state = .done(hashes)
        case .failure(.notAFile): state = .failed(L("仅支持为文件计算哈希。"))
        case .failure(.cancelled): break
        case .failure: state = .failed(L("无法读取文件。"))
        }
    }
}

private struct HashRow: View {
    let algorithm: FileHashes.Algorithm
    let value: String
    @State private var copied = false

    var body: some View {
        LabeledContent {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(copied ? L("已拷贝") : L("拷贝")) {
                    Pasteboard.copyLines([value])
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        copied = false
                    }
                }
                .buttonStyle(.bordered)
                .contentTransition(.opacity)
            }
        } label: {
            Text(algorithm.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
