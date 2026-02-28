import XCTest
@testable import MatrixDomain

final class MatrixDomainTests: XCTestCase {
    func testDestinationsExposeExpectedOrder() {
        XCTAssertEqual(MatrixMasterDestination.allCases.map(\.rawValue), ["solve", "operate", "analyze", "library"])
    }

    func testShellSnapshotRoundTrip() throws {
        let snapshot = MatrixMasterShellSnapshot(
            selectedDestination: .analyze,
            selectedMode: .numeric,
            updatedAt: Date(timeIntervalSince1970: 42)
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(MatrixMasterShellSnapshot.self, from: data)
        XCTAssertEqual(decoded, snapshot)
    }
}
