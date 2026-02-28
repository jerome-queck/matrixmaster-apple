import XCTest
import MatrixDomain
@testable import MatrixUI

final class MatrixUITests: XCTestCase {
    func testPlaceholderCanBeConstructed() {
        let view = MatrixMasterDestinationPlaceholder(
            destination: .solve,
            mode: .exact,
            lastResult: nil
        )
        XCTAssertNotNil(view)
    }
}
