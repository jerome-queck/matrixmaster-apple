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
        XCTAssertTrue(app.descendants(matching: .any)["solve-homogeneous-toggle"].waitForExistence(timeout: 3))
    }

    func testSolveResultShowsReuseActions() {
        let app = XCUIApplication()
        app.launch()

        let runButton = app.buttons["run-sample-solve"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 3))
        runButton.tap()

        XCTAssertTrue(app.buttons["reuse-payload-0-to-analyze"].waitForExistence(timeout: 3))
    }

    func testOperateAnalyzeAndSpacesExposeRandomizeButton() {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts["Operate"].firstMatch.click()
        XCTAssertTrue(app.buttons["matrix-editor-action-Randomize"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["operate-kind-picker"].waitForExistence(timeout: 3))

        app.staticTexts["Analyze"].firstMatch.click()
        XCTAssertTrue(app.buttons["matrix-editor-action-Randomize"].waitForExistence(timeout: 3))

        app.staticTexts["Spaces"].firstMatch.click()
        XCTAssertTrue(app.descendants(matching: .any)["spaces-kind-picker"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["vector-editor-action-Randomize"].waitForExistence(timeout: 3))
    }

    func testLibrarySurfaceExposesCatalogActions() {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts["Library"].firstMatch.click()
        XCTAssertTrue(app.buttons["vector-editor-action-Randomize"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["library-save-draft-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["library-export-button"].waitForExistence(timeout: 3))
    }
}
