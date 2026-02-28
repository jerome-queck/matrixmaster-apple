import XCTest

final class MatrixMasterMobileUITestsLaunchTests: XCTestCase {
    func testLaunchPerformance() throws {
        let app = XCUIApplication()

#if targetEnvironment(simulator)
        // Simulator launch metric loops are flaky and can be SIGKILLed.
        app.launch()
        XCTAssertTrue(app.otherElements["mobile-root-tab-view"].waitForExistence(timeout: 5))
#else
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
#endif
    }
}
