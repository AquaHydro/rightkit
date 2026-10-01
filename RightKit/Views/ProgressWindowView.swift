import RightKitCore
import SwiftUI

/// F-075 进度窗口。操作结束时自动关闭。
struct ProgressWindowView: View {
    @Environment(ProgressCenter.self) private var center
    @Environment(\.dismiss) private var dismiss
    let id: UUID

    var body: some View {
        Group {
            if let item = center.items[id] {
                TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                    let snapshot = item.progress.snapshot
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.headline)
                        ProgressView(value: snapshot.fraction)
                        HStack(alignment: .firstTextBaseline) {
                            Text(snapshot.currentName)
                                .font(.callout.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button(L("取消")) { item.progress.cancel() }
                                .keyboardShortcut(.cancelAction)
                                .disabled(snapshot.isCancelled)
                        }
                    }
                }
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
        .padding(20)
        .frame(width: 400)
        .onChange(of: center.items[id] == nil) { _, finished in
            if finished { dismiss() }
        }
    }
}
