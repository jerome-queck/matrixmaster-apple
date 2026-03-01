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
        XCTAssertTrue(app.switches["Homogeneous system (A x = 0)"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["solution-vector-entry-0"].waitForExistence(timeout: 3))
    }

    func testSolveResultShowsReuseActions() {
        let app = XCUIApplication()
        app.launch()

        let runButton = app.buttons["run-sample-solve"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 3))
        runButton.tap()

        XCTAssertTrue(app.buttons["reuse-payload-0-to-analyze"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["REF / RREF Panels"].waitForExistence(timeout: 3))
    }

    func testResultSurfaceDoesNotBleedAcrossTabs() {
        let app = XCUIApplication()
        app.launch()

        openDestination(named: "Analyze", in: app)
        let runButton = app.buttons["run-sample-analyze"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 3))
        runButton.tap()
        XCTAssertTrue(app.staticTexts["REF / RREF Panels"].waitForExistence(timeout: 3))

        openDestination(named: "Operate", in: app)
        XCTAssertTrue(app.buttons["operate-kind-picker"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["REF / RREF Panels"].firstMatch.exists)
    }

    func testOperateAnalyzeAndSpacesExposeRandomizeButton() {
        let app = XCUIApplication()
        app.launch()

        openDestination(named: "Operate", in: app)
        XCTAssertTrue(app.buttons["matrix-editor-action-Randomize"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["operate-kind-picker"].waitForExistence(timeout: 3))

        openDestination(named: "Analyze", in: app)
        XCTAssertTrue(app.buttons["matrix-editor-action-Randomize"].waitForExistence(timeout: 3))

        openDestination(named: "Spaces", in: app)
        XCTAssertTrue(app.buttons["spaces-kind-picker"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["vector-editor-action-Randomize"].waitForExistence(timeout: 3))
    }

    func testLibrarySurfaceExposesCatalogActions() {
        let app = XCUIApplication()
        app.launch()

        openDestination(named: "Library", in: app)
        XCTAssertTrue(app.buttons["vector-editor-action-Randomize"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["library-save-draft-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["library-export-button"].waitForExistence(timeout: 3))
    }

    func testSpacesPresetEditorsExposePolynomialAndMatrixEntryFields() {
        let app = XCUIApplication()
        app.launch()

        openDestination(named: "Spaces", in: app)

        let presetPicker = app.buttons["spaces-preset-picker"].firstMatch
        XCTAssertTrue(presetPicker.waitForExistence(timeout: 3))

        presetPicker.tap()
        selectMenuOption(
            named: "spaces-preset-option-polynomialSpace",
            in: app,
            file: #filePath,
            line: #line
        )
        XCTAssertTrue(app.textFields["polynomial-element-0-coeff-0"].waitForExistence(timeout: 3))

        presetPicker.tap()
        selectMenuOption(
            named: "spaces-preset-option-matrixSpace",
            in: app,
            file: #filePath,
            line: #line
        )
        XCTAssertTrue(app.textFields["matrix-space-element-0-cell-0-0"].waitForExistence(timeout: 3))
    }

    private func openDestination(
        named destination: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let tabButton = app.tabBars.buttons[destination]
        if tabButton.waitForExistence(timeout: 1) {
            tabButton.tap()
            return
        }

        let plainButton = app.buttons[destination].firstMatch
        if plainButton.waitForExistence(timeout: 1) {
            plainButton.tap()
            return
        }

        let cell = app.cells[destination].firstMatch
        if cell.waitForExistence(timeout: 1) {
            cell.tap()
            return
        }

        XCTFail("Could not find destination control for \(destination).", file: file, line: line)
    }

    private func selectMenuOption(
        named option: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let identifiedOption = app.descendants(matching: .any)[option].firstMatch
        if identifiedOption.waitForExistence(timeout: 1) {
            identifiedOption.tap()
            return
        }

        let buttonOption = app.buttons[option].firstMatch
        if buttonOption.waitForExistence(timeout: 1) {
            buttonOption.tap()
            return
        }

        let staticOption = app.staticTexts[option].firstMatch
        if staticOption.waitForExistence(timeout: 1) {
            staticOption.tap()
            return
        }

        XCTFail("Could not select menu option \(option).", file: file, line: line)
    }
}
