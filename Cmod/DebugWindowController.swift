import AppKit
import SwiftUI

@MainActor
final class DebugWindowController {
    private var window: NSWindow?

    func show(state: CmodState) {
        if let window {
            present(window)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 180),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cmod Diagnostics"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: ContentView(state: state))
        window.center()
        self.window = window
        present(window)
    }

    private func present(_ window: NSWindow) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
