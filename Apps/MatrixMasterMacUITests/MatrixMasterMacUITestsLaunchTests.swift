import XCTest
#if os(macOS)
import AppKit
#endif

final class MatrixMasterMacUITestsLaunchTests: XCTestCase {
    private static let appBundleIdentifier = "com.matrixmaster.mac"

    func testLaunchShowsWindow() throws {
        terminateStaleMatrixMasterProcesses()
        let app = XCUIApplication(bundleIdentifier: Self.appBundleIdentifier)
        app.launch()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 3))
    }

    private func terminateStaleMatrixMasterProcesses() {
        #if os(macOS)
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let runningApplications = NSRunningApplication.runningApplications(withBundleIdentifier: Self.appBundleIdentifier)
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

        for runningApplication in NSRunningApplication.runningApplications(withBundleIdentifier: Self.appBundleIdentifier) {
            _ = runningApplication.forceTerminate()
        }
        #endif
    }
}
