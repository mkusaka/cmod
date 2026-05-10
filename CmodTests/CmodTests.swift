//
//  CmodTests.swift
//  CmodTests
//
//  Created by masatomo.kusaka on 2026/05/10.
//

@testable import Cmod
import Testing

struct CmodTests {
    @Test @MainActor func `left command tap switches to english`() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == .switchToEnglish)
    }

    @Test @MainActor func `right command tap switches to kana`() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(54)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == .switchToKana)
    }

    @Test @MainActor func `command shortcut does not switch input`() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.keyDown(8)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
    }

    @Test @MainActor func `command click does not switch input`() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.otherInput) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
    }

    @Test @MainActor func `overlapping command keys do not switch input`() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == nil)
    }

    @Test func `release version build version matches workflow scheme`() {
        #expect(ReleaseVersion.buildVersion(for: "0.0.1") == 1)
        #expect(ReleaseVersion.buildVersion(for: "0.1.2") == 102)
        #expect(ReleaseVersion.buildVersion(for: "1.2.3") == 10203)
        #expect(ReleaseVersion.buildVersion(for: "1.2.3.4") == nil)
        #expect(ReleaseVersion.buildVersion(for: "1.x.3") == nil)
    }

    @Test func `build info contains version and commit hash`() {
        #expect(!BuildInfo.version.isEmpty)
        #expect(!BuildInfo.gitCommitHash.isEmpty)
        #expect(BuildInfo.gitCommitHash != "unknown")
        #expect(BuildInfo.gitCommitHashFull != "unknown")
        #expect(BuildInfo.gitCommitHashFull.count >= BuildInfo.gitCommitHash.count)
        #expect(BuildInfo.displayVersion.contains(BuildInfo.version))
        #expect(BuildInfo.displayVersion.contains(BuildInfo.gitCommitHash))
    }
}
