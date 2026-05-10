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
}
