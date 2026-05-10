import Carbon.HIToolbox
import CoreGraphics
import Foundation

protocol InputSwitching {
    func switchInput(for action: InputModeAction)
}

struct TISInputSwitcher: InputSwitching {
    func switchInput(for action: InputModeAction) {
        if let source = preferredInputSource(for: action) {
            let status = TISSelectInputSource(source)
            if status == noErr {
                return
            }
        }

        JISKeyEventInputSwitcher().switchInput(for: action)
    }

    private func preferredInputSource(for action: InputModeAction) -> TISInputSource? {
        let sources = selectableInputSources()
        let descriptors = sources.map(\.descriptor)
        guard let preferredID = InputSourceResolver.preferredID(for: action, from: descriptors) else {
            return nil
        }

        return sources.first { $0.descriptor.id == preferredID }?.source
    }

    private func selectableInputSources() -> [ResolvedInputSource] {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        return sources.compactMap { (source: TISInputSource) -> ResolvedInputSource? in
            guard
                let descriptor = InputSourceDescriptor(source: source),
                descriptor.isEnabled,
                descriptor.isSelectCapable
            else {
                return nil
            }

            return ResolvedInputSource(source: source, descriptor: descriptor)
        }
    }
}

struct InputSourceDescriptor: Equatable {
    let id: String
    let localizedName: String
    let isSelectCapable: Bool
    let isEnabled: Bool
}

enum InputSourceResolver {
    private static let englishPreferredIDs = [
        "com.google.inputmethod.Japanese.Roman",
        "com.apple.keylayout.ABC",
        "com.apple.keylayout.US",
    ]

    private static let kanaPreferredIDs = [
        "com.google.inputmethod.Japanese.base",
        "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
    ]

    static func preferredID(for action: InputModeAction, from sources: [InputSourceDescriptor]) -> String? {
        let candidates = sources.filter { $0.isEnabled && $0.isSelectCapable }
        let preferredIDs = switch action {
        case .switchToEnglish:
            englishPreferredIDs
        case .switchToKana:
            kanaPreferredIDs
        }

        for preferredID in preferredIDs where candidates.contains(where: { $0.id == preferredID }) {
            return preferredID
        }

        return fallbackID(for: action, from: candidates)
    }

    private static func fallbackID(for action: InputModeAction, from sources: [InputSourceDescriptor]) -> String? {
        switch action {
        case .switchToEnglish:
            sources.first {
                $0.id.hasPrefix("com.apple.keylayout.") && englishish($0)
            }?.id
        case .switchToKana:
            sources.first {
                $0.id.localizedCaseInsensitiveContains("Japanese")
                    && $0.localizedName.localizedCaseInsensitiveContains("Hiragana")
            }?.id
        }
    }

    private static func englishish(_ source: InputSourceDescriptor) -> Bool {
        source.id.localizedCaseInsensitiveContains("ABC")
            || source.id.localizedCaseInsensitiveContains("US")
            || source.localizedName.localizedCaseInsensitiveContains("ABC")
            || source.localizedName.localizedCaseInsensitiveContains("U.S.")
            || source.localizedName.localizedCaseInsensitiveContains("English")
    }
}

private struct ResolvedInputSource {
    let source: TISInputSource
    let descriptor: InputSourceDescriptor
}

private extension InputSourceDescriptor {
    init?(source: TISInputSource) {
        guard let id = source.stringProperty(kTISPropertyInputSourceID) else {
            return nil
        }

        self.init(
            id: id,
            localizedName: source.stringProperty(kTISPropertyLocalizedName) ?? "",
            isSelectCapable: source.boolProperty(kTISPropertyInputSourceIsSelectCapable),
            isEnabled: source.boolProperty(kTISPropertyInputSourceIsEnabled),
        )
    }
}

private extension TISInputSource {
    func stringProperty(_ key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(self, key) else {
            return nil
        }

        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    func boolProperty(_ key: CFString) -> Bool {
        guard let pointer = TISGetInputSourceProperty(self, key) else {
            return false
        }

        let value = Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue()
        return CFBooleanGetValue(value)
    }
}

private struct JISKeyEventInputSwitcher: InputSwitching {
    func switchInput(for action: InputModeAction) {
        let keyCode = switch action {
        case .switchToEnglish:
            CGKeyCode(kVK_JIS_Eisu)
        case .switchToKana:
            CGKeyCode(kVK_JIS_Kana)
        }

        post(keyCode: keyCode, keyDown: true)
        post(keyCode: keyCode, keyDown: false)
    }

    private func post(keyCode: CGKeyCode, keyDown: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else {
            return
        }

        event.flags = []
        event.post(tap: .cghidEventTap)
    }
}
