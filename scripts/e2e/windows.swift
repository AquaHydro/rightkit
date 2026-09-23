// 列出某个进程在屏幕上的窗口：编号、标题、尺寸。用于只截 RightKit 自己的窗口。
import CoreGraphics
import Foundation

let owner = CommandLine.arguments.dropFirst().first ?? "RightKit"
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
for window in list where window[kCGWindowOwnerName as String] as? String == owner {
    let bounds = window[kCGWindowBounds as String] as? [String: Double] ?? [:]
    let number = window[kCGWindowNumber as String] as? Int ?? 0
    let name = window[kCGWindowName as String] as? String ?? ""
    let layer = window[kCGWindowLayer as String] as? Int ?? 0
    print("\(number)\t\(layer)\t\(Int(bounds["Width"] ?? 0))x\(Int(bounds["Height"] ?? 0))\t\(name)")
}
