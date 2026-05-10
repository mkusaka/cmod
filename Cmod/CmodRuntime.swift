import Foundation

@MainActor
final class CmodRuntime {
    static let shared = CmodRuntime()

    let state: CmodState
    let appUpdater: AppUpdaterController

    private let permissionService: PermissionService
    private let eventTap: GlobalCommandKeyEventTap
    private let settingsWindowController: SettingsWindowController

    private init() {
        state = CmodState()
        appUpdater = AppUpdaterController()
        permissionService = PermissionService()
        settingsWindowController = SettingsWindowController()
        eventTap = GlobalCommandKeyEventTap(
            inputSwitcher: TISInputSwitcher(),
            onAction: { [state] action in
                state.record(action: action)
            },
            onMonitoringChanged: { [state] isActive, message in
                state.setMonitoringActive(isActive, message: message)
            },
        )
    }

    func start() {
        refreshPermissionStatus(prompt: true)
        appUpdater.start()

        let started = eventTap.start()
        if !started {
            state.setMonitoringActive(
                false,
                message: "Keyboard monitoring is unavailable. Check Input Monitoring and Accessibility permissions.",
            )
        }
    }

    func stop() {
        eventTap.stop()
    }

    func refreshPermissionStatus(prompt: Bool) {
        let status = permissionService.currentStatus(prompt: prompt)
        state.setAccessibilityStatus(status)
    }

    func showSettings() {
        settingsWindowController.show(runtime: self)
    }
}
