import Carbon.HIToolbox
import CoreGraphics
import Foundation

private nonisolated func cmodEventTapCallback(
    proxy _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let eventTap = Unmanaged<GlobalCommandKeyEventTap>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        Task { @MainActor in
            eventTap.reenable()
        }
        return Unmanaged.passUnretained(event)
    }

    guard let sample = CommandEventSample(type: type, event: event) else {
        return Unmanaged.passUnretained(event)
    }

    Task { @MainActor in
        eventTap.handle(sample)
    }

    return Unmanaged.passUnretained(event)
}

@MainActor
final class GlobalCommandKeyEventTap {
    private let inputSwitcher: any InputSwitching
    private let onAction: (InputModeAction) -> Void
    private let onMonitoringChanged: (Bool, String) -> Void
    private var detector = CommandKeyDetector()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(
        inputSwitcher: any InputSwitching,
        onAction: @escaping (InputModeAction) -> Void,
        onMonitoringChanged: @escaping (Bool, String) -> Void
    ) {
        self.inputSwitcher = inputSwitcher
        self.onAction = onAction
        self.onMonitoringChanged = onMonitoringChanged
    }

    func start() -> Bool {
        guard eventTap == nil else {
            return true
        }

        let mask = Self.mask(for: [
            .flagsChanged,
            .keyDown,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
        ])

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: cmodEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
            CFMachPortInvalidate(eventTap)
            return false
        }

        self.eventTap = eventTap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        onMonitoringChanged(true, "Keyboard monitoring is active")
        return true
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }

        onMonitoringChanged(false, "Keyboard monitoring is stopped")
    }

    fileprivate func reenable() {
        guard let eventTap else {
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
        onMonitoringChanged(true, "Keyboard monitoring was re-enabled")
    }

    fileprivate func handle(_ sample: CommandEventSample) {
        guard let action = detector.handle(sample) else {
            return
        }

        inputSwitcher.switchInput(for: action)
        onAction(action)
    }

    private static func mask(for eventTypes: [CGEventType]) -> CGEventMask {
        eventTypes.reduce(CGEventMask(0)) { mask, eventType in
            mask | (CGEventMask(1) << CGEventMask(eventType.rawValue))
        }
    }
}

private extension CommandEventSample {
    nonisolated init?(type: CGEventType, event: CGEvent) {
        switch type {
        case .flagsChanged:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            self = .flagsChanged(keyCode)
        case .keyDown:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            self = .keyDown(keyCode)
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            self = .otherInput
        default:
            return nil
        }
    }
}
