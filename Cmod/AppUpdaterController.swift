import AppKit
import CmodSparkle

@MainActor
final class AppUpdaterController: NSObject {
    private(set) var updaterController: SPUStandardUpdaterController
    private var didStart = false

    var updater: SPUUpdater {
        updaterController.updater
    }

    override init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    func start() {
        guard !didStart else {
            return
        }

        do {
            try updater.start()
            didStart = true
        } catch {
            NSLog("Cmod Sparkle updater failed to start: %@", error.localizedDescription)
        }
    }

    @objc
    func checkForUpdates(_ sender: Any?) {
        updaterController.checkForUpdates(sender)
    }
}
