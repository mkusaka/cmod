import CmodSparkle
import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: CmodState

    private let appUpdater: AppUpdaterController
    private let launchAtLoginController: LaunchAtLoginController
    private let refreshPermissions: () -> Void

    @State private var automaticallyChecksForUpdates: Bool
    @State private var automaticallyDownloadsUpdates: Bool
    @State private var launchAtLoginStatus: LaunchAtLoginStatus
    @State private var launchAtLoginErrorMessage: String?

    init(
        state: CmodState,
        appUpdater: AppUpdaterController,
        launchAtLoginController: LaunchAtLoginController,
        refreshPermissions: @escaping () -> Void,
    ) {
        self.state = state
        self.appUpdater = appUpdater
        self.launchAtLoginController = launchAtLoginController
        self.refreshPermissions = refreshPermissions
        _automaticallyChecksForUpdates = State(initialValue: appUpdater.updater.automaticallyChecksForUpdates)
        _automaticallyDownloadsUpdates = State(initialValue: appUpdater.updater.automaticallyDownloadsUpdates)
        _launchAtLoginStatus = State(initialValue: launchAtLoginController.status)
    }

    var body: some View {
        TabView {
            Form {
                Section("Startup") {
                    Toggle(
                        "Launch at Login",
                        isOn: Binding(
                            get: { launchAtLoginStatus.isRegistered },
                            set: { newValue in
                                setLaunchAtLoginEnabled(newValue)
                            },
                        ),
                    )

                    LabeledContent("Login Item", value: launchAtLoginStatus.displayLabel)

                    if launchAtLoginStatus == .requiresApproval {
                        Button {
                            launchAtLoginController.openSystemSettingsLoginItems()
                        } label: {
                            Label("Open Login Items Settings", systemImage: "gear")
                        }
                    }

                    if let launchAtLoginErrorMessage {
                        Text(launchAtLoginErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

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
                    LabeledContent("Launch at Login", value: launchAtLoginStatus.displayLabel)
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
        .frame(width: 500, height: 380)
    }

    private func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        do {
            launchAtLoginStatus = try launchAtLoginController.setEnabled(isEnabled)
            launchAtLoginErrorMessage = nil
        } catch {
            launchAtLoginStatus = launchAtLoginController.status
            launchAtLoginErrorMessage = error.localizedDescription
        }
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
        launchAtLoginController: LaunchAtLoginController(),
        refreshPermissions: {},
    )
}
