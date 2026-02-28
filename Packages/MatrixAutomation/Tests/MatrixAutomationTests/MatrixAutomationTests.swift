import XCTest
@testable import MatrixAutomation

final class MatrixAutomationTests: XCTestCase {
    func testDefaultActionsCoversAllDestinations() {
        let provider = DefaultMatrixAutomationProvider()
        let actions = provider.defaultActions()
        XCTAssertEqual(actions.count, 4)
        XCTAssertEqual(actions.map(\.id), ["solve", "operate", "analyze", "library"])
    }
}
