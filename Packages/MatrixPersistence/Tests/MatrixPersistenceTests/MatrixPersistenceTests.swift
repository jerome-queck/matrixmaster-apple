import XCTest
import MatrixDomain
@testable import MatrixPersistence

final class MatrixPersistenceTests: XCTestCase {
    func testInMemoryStoreRoundTrip() async {
        let store = InMemoryWorkspaceSnapshotStore()
        let snapshot = MatrixMasterShellSnapshot(
            selectedDestination: .library,
            selectedMode: .numeric,
            updatedAt: Date(timeIntervalSince1970: 500)
        )

        await store.saveSnapshot(snapshot)
        let restored = await store.loadLatestSnapshot()

        XCTAssertEqual(restored, snapshot)
    }
}
