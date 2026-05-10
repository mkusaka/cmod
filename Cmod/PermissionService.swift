import ApplicationServices

struct PermissionService {
    func currentStatus(prompt: Bool) -> PermissionAccessState {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options) ? .granted : .missing
    }
}
