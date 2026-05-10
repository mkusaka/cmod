import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let runtime = CmodRuntime.shared
    private var menuBarController: MenuBarController?

    func applicationWillFinishLaunching(_: Notification) {
        guard !runtime.configuration.isUITesting else {
            return
        }

        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_: Notification) {
        menuBarController = MenuBarController(runtime: runtime)
        runtime.start()
    }

    func applicationWillTerminate(_: Notification) {
        runtime.stop()
    }
}
