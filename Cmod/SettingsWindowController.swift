import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?

    func show(runtime: CmodRuntime) {
        let rootView = SettingsView(
            state: runtime.state,
            appUpdater: runtime.appUpdater,
            launchAtLoginController: runtime.launchAtLoginController,
            refreshPermissions: { [weak runtime] in
                runtime?.refreshPermissionStatus(prompt: true)
            },
        )

        if let window {
            window.contentViewController = NSHostingController(rootView: rootView)
            present(window)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false,
        )
        window.title = "Cmod Settings"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: rootView)
        window.center()
        self.window = window
        present(window)
    }

    private func present(_ window: NSWindow) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
