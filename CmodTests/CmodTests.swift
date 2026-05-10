//
//  CmodTests.swift
//  CmodTests
//
//  Created by masatomo.kusaka on 2026/05/10.
//

import Testing
@testable import Cmod

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
}
