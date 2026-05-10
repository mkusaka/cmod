import Combine
import Foundation

@MainActor
final class CmodState: ObservableObject {
    @Published private(set) var accessibilityStatus: PermissionAccessState = .unknown
    @Published private(set) var monitoringActive = false
    @Published private(set) var monitoringMessage = "Not started"
    @Published private(set) var lastAction: InputModeAction?

    var statusSummary: String {
        if monitoringActive {
            "Monitoring left and right Command keys"
        } else {
            monitoringMessage
        }
    }

    func setAccessibilityStatus(_ status: PermissionAccessState) {
        accessibilityStatus = status
    }

    func setMonitoringActive(_ isActive: Bool, message: String) {
        monitoringActive = isActive
        monitoringMessage = message
    }

    func record(action: InputModeAction) {
        lastAction = action
    }
}

enum PermissionAccessState: String {
    case granted
    case missing
    case unknown

    var menuLabel: String {
        switch self {
        case .granted:
            "Granted"
        case .missing:
            "Missing"
        case .unknown:
            "Unknown"
        }
    }
}
