import XCTest

final class MatrixMasterMacUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsWindow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 3))
    }

    func testShellExposesAccessibilityIdentifiers() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["run-sample-solve"].waitForExistence(timeout: 3))
    }
}
