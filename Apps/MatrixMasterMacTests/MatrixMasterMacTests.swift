import XCTest
@testable import MatrixMasterMac

final class MatrixMasterMacTests: XCTestCase {
    func testDefaultDestinationIsSolve() {
        XCTAssertEqual(MacShellDefaults.defaultDestination.rawValue, "solve")
    }
}
