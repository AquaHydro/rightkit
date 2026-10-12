import AppKit
import SwiftUI
import Testing

@Suite(.serialized) @MainActor
struct SettingsPageContainerTests {
    @Test func createsOnlyVisitedPagesAndRetainsTheNativeFormControls() throws {
        _ = NSApplication.shared
        let container = SettingsPageContainer<Int>(frame: NSRect(x: 0, y: 0, width: 640, height: 620))
        let window = window(containing: container)
        defer { window.close() }
        var created: [Int] = []
        var fields: [Int: NSTextField] = [:]
        container.makePage = { key, activity in
            created.append(key)
            let host = NSHostingView(rootView: Form {
                TestTextField { fields[key] = $0 }
            }.formStyle(.grouped).environment(\.settingsPageActivity, activity))
            host.sizingOptions = []
            host.sceneBridgingOptions = []
            return host
        }

        container.select(0)
        container.layoutSubtreeIfNeeded()
        #expect(created == [0])
        let firstHost = try #require(container.pages[0]?.view)
        let field = try #require(fields[0])
        field.stringValue = "retained edit"
        #expect(window.makeFirstResponder(field))

        container.select(1)
        container.layoutSubtreeIfNeeded()
        #expect(created == [0, 1])
        #expect(firstHost.superview == nil)
        #expect(firstHost.window == nil)
        #expect(container.subviews.count == 1)
        // The outgoing page's field editor must no longer be the first responder.
        #expect(window.firstResponder === window)

        container.select(0)
        container.layoutSubtreeIfNeeded()
        #expect(created == [0, 1])
        #expect(container.pages[0]?.view === firstHost)
        #expect(fields[0] === field)
        #expect(field.stringValue == "retained edit")
        #expect(field.window === window)
        #expect(container.pages[0]?.activity.activationRevision == 2)
    }

    @Test func accessibilityBoundaryExposesOnlyTheAttachedPage() {
        _ = NSApplication.shared
        let container = SettingsPageContainer<Int>(frame: NSRect(x: 0, y: 0, width: 640, height: 620))
        let window = window(containing: container)
        defer { window.close() }
        container.makePage = { key, _ in
            let field = NSTextField(string: "Page \(key)")
            field.setAccessibilityElement(true)
            field.setAccessibilityIdentifier("settings-field-\(key)")
            return field
        }
        container.select(0)
        #expect(accessibilityIdentifiers(in: container) == ["settings-field-0"])
        container.select(1)
        #expect(accessibilityIdentifiers(in: container) == ["settings-field-1"])
        container.select(0)
        #expect(accessibilityIdentifiers(in: container) == ["settings-field-0"])
        container.releasePages()
        #expect(accessibilityIdentifiers(in: container).isEmpty)
    }

    @Test func switchingAndClosingCancelPageWorkAndCloseReleasesEveryHost() async throws {
        _ = NSApplication.shared
        let container = SettingsPageContainer<Int>()
        let window = window(containing: container)
        var created = 0
        container.makePage = { _, _ in created += 1; return NSHostingView(rootView: Form { Text("Page") }) }
        container.select(0)
        let firstActivity = try #require(container.pages[0]?.activity)
        let firstTask = Task<Void, Never> { try? await Task.sleep(for: .seconds(60)) }
        firstActivity.importTask = firstTask
        weak let firstHost = container.pages[0]?.view

        container.select(1)
        #expect(firstTask.isCancelled)
        let secondTask = Task<Void, Never> { try? await Task.sleep(for: .seconds(60)) }
        container.pages[1]?.activity.importTask = secondTask
        window.close()
        #expect(secondTask.isCancelled)
        #expect(container.pages.isEmpty)
        #expect(container.subviews.isEmpty)
        // NSHostingView drains render/update work on the following main run loop.
        try await Task.sleep(for: .milliseconds(50))
        #expect(firstHost == nil)

        // A SwiftUI Window may reopen the same content instance. Recreate just its tab.
        NotificationCenter.default.post(name: NSWindow.didBecomeKeyNotification, object: window)
        #expect(created == 3)
        #expect(container.pages.count == 1)
        #expect(container.pages[1] != nil)
        window.close()
    }

    @Test func releasingForLanguageRebuildCancelsTasks() throws {
        let container = SettingsPageContainer<Int>()
        container.makePage = { _, _ in NSHostingView(rootView: Text("Page")) }
        container.select(0)
        let activity = try #require(container.pages[0]?.activity)
        let task = Task<Void, Never> { try? await Task.sleep(for: .seconds(60)) }
        activity.importTask = task
        container.releasePages()
        #expect(task.isCancelled)
        #expect(container.pages.isEmpty)
        #expect(container.subviews.isEmpty)
    }

    private func window(containing view: NSView) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 620),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        return window
    }

    private func accessibilityIdentifiers(in element: any NSAccessibilityProtocol, depth: Int = 0) -> Set<String> {
        guard depth < 30 else { return [] }
        var identifiers: Set<String> = []
        if let identifier = element.accessibilityIdentifier() { identifiers.insert(identifier) }
        for child in element.accessibilityChildren() ?? [] {
            if let child = child as? any NSAccessibilityProtocol {
                identifiers.formUnion(accessibilityIdentifiers(in: child, depth: depth + 1))
            }
        }
        return identifiers
    }
}

private struct TestTextField: NSViewRepresentable {
    let created: (NSTextField) -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: "initial")
        created(field)
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {}
}
