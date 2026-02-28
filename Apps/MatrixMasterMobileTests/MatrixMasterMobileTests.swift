import XCTest
@testable import MatrixMasterMobile

final class MatrixMasterMobileTests: XCTestCase {
    func testDefaultDestinationIsSolve() {
        XCTAssertEqual(MobileShellDefaults.defaultDestination.rawValue, "solve")
    }
}
