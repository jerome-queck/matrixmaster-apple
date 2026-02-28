import XCTest
import MatrixDomain
@testable import MatrixFeatures

@MainActor
final class MatrixFeaturesTests: XCTestCase {
    func testCoordinatorRunsSampleComputation() async {
        let coordinator = MatrixMasterFeatureCoordinator()

        await coordinator.runQuickComputation(for: .solve)

        XCTAssertNotNil(coordinator.lastResult)
        XCTAssertEqual(coordinator.syncState, .synced)
    }

    func testCoordinatorSupportsNumericMode() async {
        let coordinator = MatrixMasterFeatureCoordinator(selectedMode: .numeric)

        await coordinator.runQuickComputation(for: .analyze)

        XCTAssertTrue(coordinator.lastResult?.answer.contains("Numeric") == true)
    }
}
