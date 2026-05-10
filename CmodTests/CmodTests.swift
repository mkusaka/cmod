//
//  CmodTests.swift
//  CmodTests
//
//  Created by masatomo.kusaka on 2026/05/10.
//

import Testing
@testable import Cmod

struct CmodTests {
    @Test func leftCommandTapSwitchesToEnglish() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == .switchToEnglish)
    }

    @Test func rightCommandTapSwitchesToKana() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(54)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == .switchToKana)
    }

    @Test func commandShortcutDoesNotSwitchInput() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.keyDown(8)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
    }

    @Test func commandClickDoesNotSwitchInput() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.otherInput) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
    }

    @Test func overlappingCommandKeysDoNotSwitchInput() {
        var detector = CommandKeyDetector()

        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == nil)
        #expect(detector.handle(.flagsChanged(55)) == nil)
        #expect(detector.handle(.flagsChanged(54)) == nil)
    }
}
