import Foundation
import MatrixDomain

public protocol WorkspaceSnapshotStoring: Sendable {
    func loadLatestSnapshot() async -> MatrixMasterShellSnapshot?
    func saveSnapshot(_ snapshot: MatrixMasterShellSnapshot) async
}

public actor InMemoryWorkspaceSnapshotStore: WorkspaceSnapshotStoring {
    private var latestSnapshot: MatrixMasterShellSnapshot?

    public init() {}

    public func loadLatestSnapshot() async -> MatrixMasterShellSnapshot? {
        latestSnapshot
    }

    public func saveSnapshot(_ snapshot: MatrixMasterShellSnapshot) async {
        latestSnapshot = snapshot
    }
}
