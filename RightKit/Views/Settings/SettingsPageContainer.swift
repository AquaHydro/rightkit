import AppKit
import Observation
import SwiftUI

/// A settings page stays alive between visits, but its work only belongs to the active page.
@MainActor @Observable
final class SettingsPageActivity {
    private(set) var activationRevision = 0
    var importTask: Task<Void, Never>?

    func activate() { activationRevision += 1 }

    func deactivate() { importTask?.cancel() }
}

private struct SettingsPageActivityKey: EnvironmentKey {
    static let defaultValue: SettingsPageActivity? = nil
}

extension EnvironmentValues {
    var settingsPageActivity: SettingsPageActivity? {
        get { self[SettingsPageActivityKey.self] }
        set { self[SettingsPageActivityKey.self] = newValue }
    }
}

/// Only the selected page is in the native view tree. Cached hosts retain their controls,
/// without exposing inactive controls to hit testing, keyboard navigation or accessibility.
@MainActor
final class SettingsPageContainer<Key: Hashable>: NSView {
    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .group }
    override func accessibilityChildren() -> [Any]? {
        // SwiftUI's representable is an accessibility boundary. Explicitly expose only
        // its attached native host, never the detached cached pages.
        NSAccessibility.unignoredChildren(from: subviews)
    }

    struct Page {
        let view: NSView
        let activity: SettingsPageActivity
    }

    private(set) var pages: [Key: Page] = [:]
    private(set) var selection: Key?
    var makePage: ((Key, SettingsPageActivity) -> NSView)?
    private weak var observedWindow: NSWindow?
    private var isClosed = false

    func select(_ key: Key) {
        guard !isClosed else { selection = key; return }
        guard selection != key || pages[key] == nil else { return }
        detachSelectedPage()
        selection = key
        if pages[key] == nil, let makePage {
            let activity = SettingsPageActivity()
            pages[key] = Page(view: makePage(key, activity), activity: activity)
        }
        guard let page = pages[key] else { return }
        page.activity.activate()
        page.view.frame = bounds
        page.view.autoresizingMask = [.width, .height]
        addSubview(page.view)
    }

    private func detachSelectedPage() {
        guard let selection, let page = pages[selection] else { return }
        page.activity.deactivate()
        // The field editor is owned by the window and can otherwise outlive a detached page.
        // Keep focus in the toolbar when selection came from its segmented picker.
        if let window, let responder = window.firstResponder as? NSView {
            let editorOwner = (responder as? NSTextView)?.delegate as? NSView
            if responder === page.view || responder.isDescendant(of: page.view)
                || editorOwner?.isDescendant(of: page.view) == true {
                window.makeFirstResponder(window)
            }
        }
        page.view.removeFromSuperview()
    }

    func releasePages() {
        detachSelectedPage()
        for page in pages.values { page.activity.deactivate() }
        pages.removeAll()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard observedWindow !== window else { return }
        stopObservingWindow()
        observedWindow = window
        guard let window else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose),
                                               name: NSWindow.willCloseNotification, object: window)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeVisible),
                                               name: NSWindow.didChangeOcclusionStateNotification, object: window)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeVisible),
                                               name: NSWindow.didBecomeKeyNotification, object: window)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        isClosed = true
        releasePages()
        // Keep only the weak selector-based reopen observers while the Window retains
        // its content. Reinstall the close observer on the next presentation.
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: observedWindow)
    }

    /// A reopened window may stay behind Finder when activation is refused, so rebuild as
    /// soon as it is visible instead of waiting for it to become key.
    @objc private func windowDidBecomeVisible(_ notification: Notification) {
        guard isClosed, observedWindow?.isVisible == true else { return }
        isClosed = false
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose),
                                               name: NSWindow.willCloseNotification, object: observedWindow)
        if let selection { select(selection) }
    }

    private func stopObservingWindow() {
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: observedWindow)
        NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: observedWindow)
        NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeOcclusionStateNotification, object: observedWindow)
        observedWindow = nil
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
