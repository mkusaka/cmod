//
//  CmodTests.swift
//  CmodTests
//
//  Created by masatomo.kusaka on 2026/05/10.
//

@testable import Cmod
import Testing

struct CmodTests {
    @Test @MainActor func leftCommandTapSwitchesToEnglish() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == .switchToEnglish)
    }

    @Test @MainActor func rightCommandTapSwitchesToKana() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(54)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == .switchToKana)
    }

    @Test @MainActor func commandShortcutDoesNotSwitchInput() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.keyDown(8)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
    }

    @Test @MainActor func commandClickDoesNotSwitchInput() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.otherInput) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
    }

    @Test @MainActor func overlappingCommandKeysDoNotSwitchInput() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == nil)
    }

    @Test func releaseVersionBuildVersionMatchesWorkflowScheme() {
        #expect(ReleaseVersion.buildVersion(for: "0.0.1") == 1)
        #expect(ReleaseVersion.buildVersion(for: "0.1.2") == 102)
        #expect(ReleaseVersion.buildVersion(for: "1.2.3") == 10203)
        #expect(ReleaseVersion.buildVersion(for: "1.2.3.4") == nil)
        #expect(ReleaseVersion.buildVersion(for: "1.x.3") == nil)
    }

    @Test func buildInfoContainsVersionAndCommitHash() {
        #expect(!BuildInfo.version.isEmpty)
        #expect(!BuildInfo.gitCommitHash.isEmpty)
        #expect(BuildInfo.gitCommitHash != "unknown")
        #expect(BuildInfo.gitCommitHashFull != "unknown")
        #expect(BuildInfo.gitCommitHashFull.count >= BuildInfo.gitCommitHash.count)
        #expect(BuildInfo.displayVersion.contains(BuildInfo.version))
        #expect(BuildInfo.displayVersion.contains(BuildInfo.gitCommitHash))
    }

    @Test @MainActor func googleJapaneseInputSourcesArePreferred() {
        let sources = [
            inputSource(id: "com.apple.keylayout.ABC", name: "ABC"),
            inputSource(id: "com.google.inputmethod.Japanese.Roman", name: "Alphanumeric (Google)"),
            inputSource(id: "com.google.inputmethod.Japanese.base", name: "Hiragana (Google)"),
            inputSource(id: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese", name: "Hiragana"),
        ]

        #expect(
            InputSourceResolver.preferredID(for: .switchToEnglish, from: sources)
                == "com.google.inputmethod.Japanese.Roman",
        )
        #expect(
            InputSourceResolver.preferredID(for: .switchToKana, from: sources)
                == "com.google.inputmethod.Japanese.base",
        )
    }

    @Test @MainActor func appleInputSourcesAreFallbacks() {
        let sources = [
            inputSource(id: "com.apple.keylayout.ABC", name: "ABC"),
            inputSource(id: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese", name: "Hiragana"),
        ]

        #expect(
            InputSourceResolver.preferredID(for: .switchToEnglish, from: sources)
                == "com.apple.keylayout.ABC",
        )
        #expect(
            InputSourceResolver.preferredID(for: .switchToKana, from: sources)
                == "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
        )
    }

    @Test @MainActor func unavailableInputSourcesAreIgnored() {
        let sources = [
            inputSource(id: "com.google.inputmethod.Japanese.Roman", name: "Alphanumeric (Google)", isEnabled: false),
            inputSource(id: "com.google.inputmethod.Japanese.base", name: "Hiragana (Google)", isSelectCapable: false),
            inputSource(id: "com.apple.keylayout.ABC", name: "ABC"),
            inputSource(id: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese", name: "Hiragana"),
        ]

        #expect(
            InputSourceResolver.preferredID(for: .switchToEnglish, from: sources)
                == "com.apple.keylayout.ABC",
        )
        #expect(
            InputSourceResolver.preferredID(for: .switchToKana, from: sources)
                == "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
        )
    }

    @Test @MainActor func enablingLaunchAtLoginRegistersMainAppLoginItem() throws {
        let service = FakeLoginItemService(status: .notRegistered)
        let controller = LaunchAtLoginController(service: service)

        let status = try controller.setEnabled(true)

        #expect(status == .enabled)
        #expect(service.registerCallCount == 1)
        #expect(service.unregisterCallCount == 0)
    }

    @Test @MainActor func disablingLaunchAtLoginUnregistersMainAppLoginItem() throws {
        let service = FakeLoginItemService(status: .enabled)
        let controller = LaunchAtLoginController(service: service)

        let status = try controller.setEnabled(false)

        #expect(status == .notRegistered)
        #expect(service.registerCallCount == 0)
        #expect(service.unregisterCallCount == 1)
    }

    @Test @MainActor func launchAtLoginRequiresApprovalStaysRegistered() throws {
        let service = FakeLoginItemService(status: .requiresApproval)
        let controller = LaunchAtLoginController(service: service)

        let status = try controller.setEnabled(true)

        #expect(status == .requiresApproval)
        #expect(status.isRegistered)
        #expect(service.registerCallCount == 0)
        #expect(service.unregisterCallCount == 0)
    }

    @Test @MainActor func launchAtLoginSettingsPanelCanBeOpened() {
        let service = FakeLoginItemService(status: .requiresApproval)
        let controller = LaunchAtLoginController(service: service)

        controller.openSystemSettingsLoginItems()

        #expect(service.openSettingsCallCount == 1)
    }

    private func inputSource(
        id: String,
        name: String,
        isSelectCapable: Bool = true,
        isEnabled: Bool = true,
    ) -> InputSourceDescriptor {
        InputSourceDescriptor(
            id: id,
            localizedName: name,
            isSelectCapable: isSelectCapable,
            isEnabled: isEnabled,
        )
    }
}

@MainActor
private final class FakeLoginItemService: LoginItemServicing {
    var status: LaunchAtLoginStatus
    var registerCallCount = 0
    var unregisterCallCount = 0
    var openSettingsCallCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        status = .notRegistered
    }

    func openSystemSettingsLoginItems() {
        openSettingsCallCount += 1
    }
}
