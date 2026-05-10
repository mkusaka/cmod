import AppKit
import Combine

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let runtime: CmodRuntime
    private let menu = NSMenu()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let monitoringItem = NSMenuItem(title: "Monitoring: Unknown", action: nil, keyEquivalent: "")
    private let accessibilityItem = NSMenuItem(title: "Accessibility: Unknown", action: nil, keyEquivalent: "")
    private let lastActionItem = NSMenuItem(title: "Last Switch: None", action: nil, keyEquivalent: "")
    private var cancellables: Set<AnyCancellable> = []

    init(runtime: CmodRuntime) {
        self.runtime = runtime
        super.init()
        configureStatusItem()
        configureMenu()
        bindState()
        refreshMenuState()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = StatusBarIcon.make()
            button.imagePosition = .imageOnly
            button.toolTip = "Cmod input switcher"
            button.setAccessibilityLabel("Cmod input switcher")
        }
        statusItem.menu = menu
    }

    private func configureMenu() {
        menu.delegate = self

        let aboutItem = NSMenuItem(title: "About Cmod", action: #selector(showAboutPanel), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ",",
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let refreshItem = NSMenuItem(
            title: "Refresh Permission Status",
            action: #selector(refreshPermissionStatus),
            keyEquivalent: "",
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        monitoringItem.isEnabled = false
        accessibilityItem.isEnabled = false
        lastActionItem.isEnabled = false
        menu.addItem(monitoringItem)
        menu.addItem(accessibilityItem)
        menu.addItem(lastActionItem)
        menu.addItem(.separator())

        let checkForUpdatesItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(AppUpdaterController.checkForUpdates(_:)),
            keyEquivalent: "",
        )
        checkForUpdatesItem.target = runtime.appUpdater
        menu.addItem(checkForUpdatesItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Cmod", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func bindState() {
        runtime.state.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshMenuState()
            }
        }
        .store(in: &cancellables)
    }

    func menuNeedsUpdate(_: NSMenu) {
        refreshMenuState()
    }

    @objc
    private func refreshPermissionStatus() {
        runtime.refreshPermissionStatus(prompt: true)
        refreshMenuState()
    }

    @objc
    private func showSettings() {
        runtime.showSettings()
    }

    @objc
    private func showAboutPanel() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationVersion: BuildInfo.displayVersion,
            .version: "",
        ])
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }

    private func refreshMenuState() {
        monitoringItem.title = runtime.state.monitoringActive ? "Monitoring: Active" : "Monitoring: Inactive"
        accessibilityItem.title = "Accessibility: \(runtime.state.accessibilityStatus.menuLabel)"
        if let lastAction = runtime.state.lastAction {
            lastActionItem.title = "Last Switch: \(lastAction.menuLabel)"
        } else {
            lastActionItem.title = "Last Switch: None"
        }
    }
}
