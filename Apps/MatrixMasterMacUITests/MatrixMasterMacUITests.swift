import XCTest
#if os(macOS)
import AppKit
#endif

final class MatrixMasterMacUITests: XCTestCase {
    private static let appBundleIdentifier = "com.matrixmaster.mac"

    override class func setUp() {
        super.setUp()
        terminateStaleMatrixMasterProcesses()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        Self.terminateStaleMatrixMasterProcesses()
    }

    override func tearDownWithError() throws {
        Self.terminateStaleMatrixMasterProcesses()
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: Self.appBundleIdentifier)
        app.launch()
        return app
    }

    func testLaunchShowsWindow() {
        let app = launchApp()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 3))
    }

    func testShellExposesAccessibilityIdentifiers() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["run-sample-solve"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["solve-homogeneous-toggle"].waitForExistence(timeout: 3))
    }

    func testSolveResultShowsReuseActions() {
        let app = launchApp()

        let runButton = app.buttons["run-sample-solve"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 3))
        runButton.tap()

        XCTAssertTrue(app.buttons["reuse-payload-0-to-analyze"].waitForExistence(timeout: 3))
    }

    func testResultSurfaceDoesNotBleedAcrossTabs() {
        let app = launchApp()

        app.staticTexts["Analyze"].firstMatch.click()
        let runButton = app.buttons["run-sample-analyze"]
        XCTAssertTrue(runButton.waitForExistence(timeout: 3))
        runButton.tap()
        XCTAssertTrue(app.staticTexts["result-answer-text"].waitForExistence(timeout: 3))

        app.staticTexts["Operate"].firstMatch.click()
        XCTAssertTrue(app.descendants(matching: .any)["operate-kind-picker"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["result-answer-text"].firstMatch.exists)
    }

    func testOperateAnalyzeAndSpacesExposeRandomizeButton() {
        let app = launchApp()

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
        let app = launchApp()

        app.staticTexts["Library"].firstMatch.click()
        XCTAssertTrue(app.buttons["vector-editor-action-Randomize"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["library-save-draft-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["library-export-button"].waitForExistence(timeout: 3))
    }

    func testSpacesPresetEditorsExposePolynomialAndMatrixEntryFields() {
        let app = launchApp()

        app.staticTexts["Spaces"].firstMatch.click()

        let presetPicker = app.popUpButtons.element(boundBy: 1)
        XCTAssertTrue(presetPicker.waitForExistence(timeout: 3))

        presetPicker.click()
        selectMenuOption(named: "spaces-preset-option-polynomialSpace", in: app)
        XCTAssertTrue(app.textFields["polynomial-element-0-coeff-0"].waitForExistence(timeout: 3))

        app.popUpButtons.element(boundBy: 1).click()
        selectMenuOption(named: "spaces-preset-option-matrixSpace", in: app)
        XCTAssertTrue(app.textFields["matrix-space-element-0-cell-0-0"].waitForExistence(timeout: 3))
    }

    private func selectMenuOption(
        named option: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let identifiedElement = app.descendants(matching: .any)[option].firstMatch
        if identifiedElement.waitForExistence(timeout: 1) {
            identifiedElement.click()
            return
        }

        let buttonOption = app.buttons[option].firstMatch
        if buttonOption.waitForExistence(timeout: 1) {
            buttonOption.click()
            return
        }

        let menuItem = app.menuItems[option].firstMatch
        if menuItem.waitForExistence(timeout: 1) {
            menuItem.click()
            return
        }

        let staticOption = app.staticTexts[option].firstMatch
        if staticOption.waitForExistence(timeout: 1) {
            staticOption.click()
            return
        }

        let partialMenuItem = app.menuItems.matching(NSPredicate(format: "label CONTAINS %@", option)).firstMatch
        if partialMenuItem.waitForExistence(timeout: 1) {
            partialMenuItem.click()
            return
        }

        let partialStaticText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", option)).firstMatch
        if partialStaticText.waitForExistence(timeout: 1) {
            partialStaticText.click()
            return
        }

        XCTFail("Could not select menu option \(option).", file: file, line: line)
    }

    private static func terminateStaleMatrixMasterProcesses() {
        #if os(macOS)
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let runningApplications = NSRunningApplication.runningApplications(withBundleIdentifier: appBundleIdentifier)
            guard !runningApplications.isEmpty else {
                return
            }

            for runningApplication in runningApplications {
                if !runningApplication.terminate() {
                    _ = runningApplication.forceTerminate()
                }
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }

        for runningApplication in NSRunningApplication.runningApplications(withBundleIdentifier: appBundleIdentifier) {
            _ = runningApplication.forceTerminate()
        }
        #endif
    }
}
