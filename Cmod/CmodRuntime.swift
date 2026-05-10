import Foundation

struct CmodConfiguration {
    let isUITesting: Bool

    nonisolated init(processInfo: ProcessInfo = .processInfo) {
        isUITesting = processInfo.arguments.contains("-uiTesting")
    }
}

@MainActor
final class CmodRuntime {
    static let shared = CmodRuntime()

    let configuration: CmodConfiguration
    let state: CmodState
    let appUpdater: AppUpdaterController

    private let permissionService: PermissionService
    private let eventTap: GlobalCommandKeyEventTap?
    private let settingsWindowController: SettingsWindowController

    private init(configuration: CmodConfiguration = CmodConfiguration()) {
        self.configuration = configuration
        state = CmodState()
        appUpdater = AppUpdaterController()
        permissionService = PermissionService()
        settingsWindowController = SettingsWindowController()

        if configuration.isUITesting {
            eventTap = nil
        } else {
            eventTap = GlobalCommandKeyEventTap(
                inputSwitcher: JISInputSwitcher(),
                onAction: { [state] action in
                    state.record(action: action)
                },
                onMonitoringChanged: { [state] isActive, message in
                    state.setMonitoringActive(isActive, message: message)
                }
            )
        }
    }

    func start() {
        refreshPermissionStatus(prompt: !configuration.isUITesting)
        appUpdater.start()

        guard let eventTap else {
            state.setMonitoringActive(false, message: "UI testing mode")
            return
        }

        let started = eventTap.start()
        if !started {
            state.setMonitoringActive(
                false,
                message: "Keyboard monitoring is unavailable. Check Input Monitoring and Accessibility permissions."
            )
        }
    }

    func stop() {
        eventTap?.stop()
    }

    func refreshPermissionStatus(prompt: Bool) {
        let status = permissionService.currentStatus(prompt: prompt)
        state.setAccessibilityStatus(status)
    }

    func showSettings() {
        settingsWindowController.show(runtime: self)
    }
}
