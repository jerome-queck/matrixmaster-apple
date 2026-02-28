import Foundation
import XCTest
import MatrixDomain
@testable import MatrixPersistence

final class MatrixPersistenceTests: XCTestCase {
    func testInMemoryStoreRoundTrip() async throws {
        let store = InMemoryWorkspaceSnapshotStore()
        let snapshot = MatrixMasterShellSnapshot(
            selectedDestination: .library,
            selectedMode: .numeric,
            updatedAt: Date(timeIntervalSince1970: 500)
        )

        try await store.saveSnapshot(snapshot)
        let restored = try await store.loadLatestSnapshot()

        XCTAssertEqual(restored, snapshot)
    }

    func testWorkspaceDocumentCodecRoundTrip() throws {
        let codec = JSONWorkspaceDocumentCodec()
        let snapshot = MatrixMasterShellSnapshot(
            selectedDestination: .solve,
            selectedMode: .exact,
            updatedAt: Date(timeIntervalSince1970: 100)
        )
        let document = MatrixWorkspaceDocument(snapshot: snapshot)

        let encoded = try codec.encode(document)
        let decoded = try codec.decode(encoded)

        XCTAssertEqual(decoded.snapshot, snapshot)
        XCTAssertEqual(decoded.schemaVersion, MatrixWorkspaceDocument.currentSchemaVersion)
        XCTAssertEqual(MatrixWorkspaceDocument.fileExtension, "mmws")
        XCTAssertEqual(MatrixWorkspaceDocument.utTypeIdentifier, "com.matrixmaster.workspace")
    }

    func testWorkspaceDocumentCodecRejectsUnsupportedVersion() throws {
        let codec = JSONWorkspaceDocumentCodec()
        let unsupportedDocument = MatrixWorkspaceDocument(
            schemaVersion: 2,
            workspaceID: UUID(),
            savedAt: Date(timeIntervalSince1970: 200),
            snapshot: MatrixMasterShellSnapshot(
                selectedDestination: .analyze,
                selectedMode: .numeric,
                updatedAt: Date(timeIntervalSince1970: 201)
            )
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedUnsupported = try encoder.encode(unsupportedDocument)

        XCTAssertThrowsError(try codec.decode(encodedUnsupported)) { error in
            XCTAssertEqual(error as? WorkspaceDocumentCodecError, .unsupportedSchemaVersion(2))
        }
    }

    func testFileWorkspaceSnapshotStoreRoundTrip() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MatrixMasterTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = tempDirectory
            .appendingPathComponent("LatestWorkspace")
            .appendingPathExtension(MatrixWorkspaceDocument.fileExtension)

        let store = FileWorkspaceSnapshotStore(fileURL: fileURL)
        let snapshot = MatrixMasterShellSnapshot(
            selectedDestination: .operate,
            selectedMode: .numeric,
            updatedAt: Date(timeIntervalSince1970: 600)
        )

        try await store.saveSnapshot(snapshot)
        let restored = try await store.loadLatestSnapshot()

        XCTAssertEqual(restored, snapshot)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testSyncCoordinatorTracksPendingWritesAndCloudAvailability() async throws {
        let coordinator = InMemoryWorkspaceSyncCoordinator()

        let initialState = await coordinator.currentState()
        let initialSnapshot = await coordinator.currentSnapshot()
        XCTAssertEqual(initialState, .localOnly)
        XCTAssertEqual(initialSnapshot.pendingWrites, 0)

        try await coordinator.recordLocalWrite()
        var snapshot = await coordinator.currentSnapshot()
        XCTAssertEqual(snapshot.state, .localOnly)
        XCTAssertEqual(snapshot.pendingWrites, 1)

        try await coordinator.setCloudAvailable(true)
        snapshot = await coordinator.currentSnapshot()
        XCTAssertEqual(snapshot.state, .syncing)

        try await coordinator.markRemoteConverged()
        snapshot = await coordinator.currentSnapshot()
        XCTAssertEqual(snapshot.state, .synced)
        XCTAssertEqual(snapshot.pendingWrites, 0)
    }

    func testFileSyncCoordinatorPersistsSnapshot() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MatrixMasterSyncTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let syncURL = tempDirectory
            .appendingPathComponent("SyncStatus")
            .appendingPathExtension("json")

        let coordinator = try FileWorkspaceSyncCoordinator(fileURL: syncURL)
        try await coordinator.recordLocalWrite()

        var snapshot = await coordinator.currentSnapshot()
        XCTAssertEqual(snapshot.pendingWrites, 1)
        XCTAssertEqual(snapshot.state, .localOnly)

        let restoredCoordinator = try FileWorkspaceSyncCoordinator(fileURL: syncURL)
        snapshot = await restoredCoordinator.currentSnapshot()
        XCTAssertEqual(snapshot.pendingWrites, 1)

        try await restoredCoordinator.setCloudAvailable(true)
        try await restoredCoordinator.markRemoteConverged()

        let convergedCoordinator = try FileWorkspaceSyncCoordinator(fileURL: syncURL)
        let convergedSnapshot = await convergedCoordinator.currentSnapshot()
        XCTAssertEqual(convergedSnapshot.state, .synced)
        XCTAssertEqual(convergedSnapshot.pendingWrites, 0)
    }
}
