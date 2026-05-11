import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound

    var isRegistered: Bool {
        switch self {
        case .enabled, .requiresApproval:
            true
        case .notRegistered, .notFound:
            false
        }
    }

    var displayLabel: String {
        switch self {
        case .notRegistered:
            "Off"
        case .enabled:
            "Enabled"
        case .requiresApproval:
            "Needs Approval"
        case .notFound:
            "Unavailable"
        }
    }
}

@MainActor
protocol LoginItemServicing: AnyObject {
    var status: LaunchAtLoginStatus { get }

    func register() throws
    func unregister() throws
    func openSystemSettingsLoginItems()
}

@MainActor
final class LaunchAtLoginController {
    private let service: any LoginItemServicing

    init(service: any LoginItemServicing = MainAppLoginItemService()) {
        self.service = service
    }

    var status: LaunchAtLoginStatus {
        service.status
    }

    @discardableResult
    func setEnabled(_ isEnabled: Bool) throws -> LaunchAtLoginStatus {
        let currentStatus = status

        if isEnabled {
            switch currentStatus {
            case .enabled, .requiresApproval:
                return currentStatus
            case .notRegistered, .notFound:
                try service.register()
            }
        } else {
            switch currentStatus {
            case .notRegistered, .notFound:
                return currentStatus
            case .enabled, .requiresApproval:
                try service.unregister()
            }
        }

        return status
    }

    func openSystemSettingsLoginItems() {
        service.openSystemSettingsLoginItems()
    }
}

@MainActor
private final class MainAppLoginItemService: LoginItemServicing {
    var status: LaunchAtLoginStatus {
        LaunchAtLoginStatus(SMAppService.mainApp.status)
    }

    func register() throws {
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        try SMAppService.mainApp.unregister()
    }

    func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

private extension LaunchAtLoginStatus {
    init(_ status: SMAppService.Status) {
        switch status {
        case .notRegistered:
            self = .notRegistered
        case .enabled:
            self = .enabled
        case .requiresApproval:
            self = .requiresApproval
        case .notFound:
            self = .notFound
        @unknown default:
            self = .notFound
        }
    }
}
