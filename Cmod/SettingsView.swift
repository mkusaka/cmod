import CmodSparkle
import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: CmodState

    private let appUpdater: AppUpdaterController
    private let refreshPermissions: () -> Void

    @State private var automaticallyChecksForUpdates: Bool
    @State private var automaticallyDownloadsUpdates: Bool

    init(
        state: CmodState,
        appUpdater: AppUpdaterController,
        refreshPermissions: @escaping () -> Void,
    ) {
        self.state = state
        self.appUpdater = appUpdater
        self.refreshPermissions = refreshPermissions
        _automaticallyChecksForUpdates = State(initialValue: appUpdater.updater.automaticallyChecksForUpdates)
        _automaticallyDownloadsUpdates = State(initialValue: appUpdater.updater.automaticallyDownloadsUpdates)
    }

    var body: some View {
        TabView {
            Form {
                Section("Updates") {
                    Toggle("Automatically check for updates", isOn: $automaticallyChecksForUpdates)
                        .onChange(of: automaticallyChecksForUpdates) { _, newValue in
                            appUpdater.updater.automaticallyChecksForUpdates = newValue
                        }

                    Toggle("Automatically download updates", isOn: $automaticallyDownloadsUpdates)
                        .disabled(!automaticallyChecksForUpdates)
                        .onChange(of: automaticallyDownloadsUpdates) { _, newValue in
                            appUpdater.updater.automaticallyDownloadsUpdates = newValue
                        }

                    Button {
                        appUpdater.checkForUpdates(nil)
                    } label: {
                        Label("Check for Updates...", systemImage: "arrow.clockwise")
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            Form {
                Section("Status") {
                    LabeledContent("Version", value: BuildInfo.displayVersion)
                    LabeledContent("Monitoring", value: state.monitoringActive ? "Active" : "Inactive")
                    LabeledContent("Accessibility", value: state.accessibilityStatus.menuLabel)
                    LabeledContent("Last Switch", value: state.lastAction?.menuLabel ?? "None")
                }

                Section("Permissions") {
                    Button {
                        refreshPermissions()
                    } label: {
                        Label("Refresh Permissions", systemImage: "lock.shield")
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("Status", systemImage: "checkmark.shield")
            }
        }
        .frame(width: 500, height: 320)
    }
}

#Preview {
    SettingsView(
        state: {
            let state = CmodState()
            state.setAccessibilityStatus(.granted)
            state.setMonitoringActive(true, message: "Keyboard monitoring is active")
            return state
        }(),
        appUpdater: AppUpdaterController(),
        refreshPermissions: {},
    )
}
