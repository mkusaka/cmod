import ApplicationServices

struct PermissionService {
    func currentStatus(prompt: Bool) -> PermissionAccessState {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options) ? .granted : .missing
    }
}
