import Carbon.HIToolbox
import CoreGraphics

enum CommandKeySide: Equatable {
    case left
    case right
}

enum CommandEventKind: Equatable {
    case flagsChanged
    case keyDown
    case otherInput
}

struct CommandEventSample: Equatable {
    let kind: CommandEventKind
    let keyCode: CGKeyCode?

    nonisolated static func flagsChanged(_ keyCode: CGKeyCode) -> Self {
        Self(kind: .flagsChanged, keyCode: keyCode)
    }

    nonisolated static func keyDown(_ keyCode: CGKeyCode) -> Self {
        Self(kind: .keyDown, keyCode: keyCode)
    }

    nonisolated static let otherInput = Self(kind: .otherInput, keyCode: nil)
}

enum InputModeAction: Equatable {
    case switchToEnglish
    case switchToKana

    var menuLabel: String {
        switch self {
        case .switchToEnglish:
            "English"
        case .switchToKana:
            "Kana"
        }
    }
}

struct CommandKeyDetector {
    private var leftCommandDown = false
    private var rightCommandDown = false
    private var candidateSide: CommandKeySide?
    private var commandWasUsedWithOtherInput = false

    mutating func handle(_ event: CommandEventSample) -> InputModeAction? {
        switch event.kind {
        case .flagsChanged:
            guard let keyCode = event.keyCode else {
                return nil
            }

            guard let side = Self.commandSide(for: keyCode) else {
                markCommandAsModifiedIfNeeded()
                return nil
            }

            return toggleCommand(side)

        case .keyDown, .otherInput:
            markCommandAsModifiedIfNeeded()
            return nil
        }
    }

    private mutating func toggleCommand(_ side: CommandKeySide) -> InputModeAction? {
        if isDown(side) {
            setDown(false, for: side)
            return finishCommandIfNeeded(side)
        }

        setDown(true, for: side)

        if candidateSide == nil, !otherCommandIsDown(than: side) {
            candidateSide = side
            commandWasUsedWithOtherInput = false
        } else {
            commandWasUsedWithOtherInput = true
        }

        return nil
    }

    private mutating func finishCommandIfNeeded(_ side: CommandKeySide) -> InputModeAction? {
        defer {
            if !leftCommandDown, !rightCommandDown {
                candidateSide = nil
                commandWasUsedWithOtherInput = false
            }
        }

        guard
            candidateSide == side,
            !commandWasUsedWithOtherInput,
            !otherCommandIsDown(than: side)
        else {
            return nil
        }

        switch side {
        case .left:
            return .switchToEnglish
        case .right:
            return .switchToKana
        }
    }

    private mutating func markCommandAsModifiedIfNeeded() {
        guard leftCommandDown || rightCommandDown else {
            return
        }

        commandWasUsedWithOtherInput = true
    }

    private func isDown(_ side: CommandKeySide) -> Bool {
        switch side {
        case .left:
            leftCommandDown
        case .right:
            rightCommandDown
        }
    }

    private mutating func setDown(_ isDown: Bool, for side: CommandKeySide) {
        switch side {
        case .left:
            leftCommandDown = isDown
        case .right:
            rightCommandDown = isDown
        }
    }

    private func otherCommandIsDown(than side: CommandKeySide) -> Bool {
        switch side {
        case .left:
            rightCommandDown
        case .right:
            leftCommandDown
        }
    }

    private static func commandSide(for keyCode: CGKeyCode) -> CommandKeySide? {
        switch Int(keyCode) {
        case kVK_Command:
            .left
        case kVK_RightCommand:
            .right
        default:
            nil
        }
    }
}
