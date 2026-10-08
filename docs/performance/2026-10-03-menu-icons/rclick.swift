import AppKit
import ApplicationServices
let a = CommandLine.arguments
let p = CGPoint(x: Double(a[1])!, y: Double(a[2])!)
let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first!
let app = AXUIElementCreateApplication(finder.processIdentifier)
func menuOpen() -> Int {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    return list.contains { ($0[kCGWindowOwnerPID as String] as? Int32) == finder.processIdentifier && ($0[kCGWindowLayer as String] as? Int) == 101 } ? 2 : 0
}
let src = CGEventSource(stateID: .hidSystemState)
CGEvent(mouseEventSource: src, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
usleep(150_000)
let t0 = Date()
CGEvent(mouseEventSource: src, mouseType: .rightMouseDown, mouseCursorPosition: p, mouseButton: .right)?.post(tap: .cghidEventTap)
CGEvent(mouseEventSource: src, mouseType: .rightMouseUp, mouseCursorPosition: p, mouseButton: .right)?.post(tap: .cghidEventTap)
var state = 0
while Date().timeIntervalSince(t0) < 3 { state = menuOpen(); if state > 0 { break }; usleep(1000) }
let ms = Date().timeIntervalSince(t0) * 1000
print(String(format: "visible_ms=%.1f rightkit=%@", ms, state == 2 ? "yes" : "no"))
