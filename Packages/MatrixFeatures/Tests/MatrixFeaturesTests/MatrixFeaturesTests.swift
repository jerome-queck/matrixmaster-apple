import Foundation
import XCTest
import MatrixDomain
import MatrixPersistence
@testable import MatrixFeatures

@MainActor
final class MatrixFeaturesTests: XCTestCase {
    func testCoordinatorRunsSampleComputation() async {
        let coordinator = MatrixMasterFeatureCoordinator()

        await coordinator.runQuickComputation(for: .solve)

        XCTAssertNotNil(coordinator.lastResult)
        XCTAssertEqual(coordinator.syncState, .localOnly)
        XCTAssertNil(coordinator.inputValidationMessage)
    }

    func testCoordinatorSupportsNumericMode() async {
        let coordinator = MatrixMasterFeatureCoordinator(selectedMode: .numeric)

        await coordinator.runQuickComputation(for: .analyze)

        XCTAssertTrue(coordinator.lastResult?.answer.contains("Numeric") == true)
    }

    func testCoordinatorRejectsInvalidInputBeforeComputation() async {
        var invalidDraft = MatrixDraftInput(rows: 1, columns: 1)
        invalidDraft.setValue("1/0", row: 0, column: 0)
        let coordinator = MatrixMasterFeatureCoordinator(matrixDraft: invalidDraft)

        await coordinator.runQuickComputation(for: .solve)

        XCTAssertEqual(coordinator.syncState, .needsAttention)
        XCTAssertEqual(coordinator.lastResult?.answer, "Input validation failed")
        XCTAssertTrue(coordinator.inputValidationMessage?.contains("zero denominator") == true)
    }

    func testCoordinatorRestoresSnapshotMode() async throws {
        let snapshotStore = InMemoryWorkspaceSnapshotStore()
        try await snapshotStore.saveSnapshot(
            MatrixMasterShellSnapshot(
                selectedDestination: .operate,
                selectedMode: .numeric,
                updatedAt: Date(timeIntervalSince1970: 900)
            )
        )

        let coordinator = MatrixMasterFeatureCoordinator(snapshotStore: snapshotStore)

        await coordinator.restoreLatestSnapshot()

        XCTAssertEqual(coordinator.selectedMode, .numeric)
    }

    func testCoordinatorConvergesWhenCloudIsAvailable() async {
        let syncCoordinator = InMemoryWorkspaceSyncCoordinator()
        let coordinator = MatrixMasterFeatureCoordinator(syncCoordinator: syncCoordinator)

        await coordinator.setCloudAvailability(true)
        await coordinator.runQuickComputation(for: .solve)

        XCTAssertEqual(coordinator.syncState, .synced)
        let snapshot = await syncCoordinator.currentSnapshot()
        XCTAssertEqual(snapshot.pendingWrites, 0)
    }
}
