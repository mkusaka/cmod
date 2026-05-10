import Carbon.HIToolbox
import CoreGraphics

protocol InputSwitching {
    func switchInput(for action: InputModeAction)
}

struct JISInputSwitcher: InputSwitching {
    func switchInput(for action: InputModeAction) {
        let keyCode: CGKeyCode
        switch action {
        case .switchToEnglish:
            keyCode = CGKeyCode(kVK_JIS_Eisu)
        case .switchToKana:
            keyCode = CGKeyCode(kVK_JIS_Kana)
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
