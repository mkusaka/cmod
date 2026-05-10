import XCTest

final class CmodUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesAsMenuBarApp() {
        let app = XCUIApplication()
        defer {
            if app.state != .notRunning {
                app.terminate()
            }
        }

        app.launch()

        let didLaunch = app.wait(for: .runningBackground, timeout: 5)
            || app.wait(for: .runningForeground, timeout: 5)

        XCTAssertTrue(didLaunch)
    }
}
