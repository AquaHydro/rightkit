import Foundation
import Observation

/// 正在进行的耗时操作。超过 1 秒才显示进度窗口，结束后自动关闭（F-075）。
@MainActor @Observable
final class ProgressCenter {
    struct Item: Identifiable {
        let id = UUID()
        let title: String
        let progress: OperationProgress
    }

    private(set) var items: [UUID: Item] = [:]
    private let windows: WindowOpener

    init(windows: WindowOpener) { self.windows = windows }

    func begin(_ title: String) -> Item {
        let item = Item(title: title, progress: OperationProgress())
        items[item.id] = item
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard let self, self.items[item.id] != nil else { return }
            self.windows.open(id: WindowID.progress, value: item.id)
        }
        return item
    }

    func end(_ item: Item) {
        items[item.id] = nil
    }
}
