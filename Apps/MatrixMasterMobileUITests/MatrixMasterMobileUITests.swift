import XCTest

final class MatrixMasterMobileUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsRootTabView() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.otherElements["mobile-root-tab-view"].waitForExistence(timeout: 3))
    }

    func testSolveSurfaceExposesAccessibleMatrixCellLabel() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.textFields["Matrix entry row 1 column 1"].waitForExistence(timeout: 3))
    }
}
