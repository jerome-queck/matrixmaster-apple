import Foundation
import MatrixDomain
import MatrixExact
import MatrixNumeric
import MatrixPersistence

@MainActor
public final class MatrixMasterFeatureCoordinator: ObservableObject {
    @Published public var selectedMode: MatrixMasterMathMode
    @Published public var syncState: MatrixMasterSyncState
    @Published public private(set) var lastResult: MatrixMasterComputationResult?

    private let exactEngine: any MatrixExactComputing
    private let numericEngine: any MatrixNumericComputing
    private let snapshotStore: any WorkspaceSnapshotStoring

    public init(
        selectedMode: MatrixMasterMathMode = .exact,
        syncState: MatrixMasterSyncState = .localOnly,
        exactEngine: any MatrixExactComputing = StubMatrixExactEngine(),
        numericEngine: any MatrixNumericComputing = StubMatrixNumericEngine(),
        snapshotStore: any WorkspaceSnapshotStoring = InMemoryWorkspaceSnapshotStore()
    ) {
        self.selectedMode = selectedMode
        self.syncState = syncState
        self.exactEngine = exactEngine
        self.numericEngine = numericEngine
        self.snapshotStore = snapshotStore
    }

    public func restoreLatestSnapshot() async {
        guard let snapshot = await snapshotStore.loadLatestSnapshot() else {
            return
        }
        selectedMode = snapshot.selectedMode
        syncState = .synced
    }

    public func runQuickComputation(for destination: MatrixMasterDestination) async {
        let request = MatrixMasterComputationRequest(
            destination: destination,
            mode: selectedMode,
            inputSummary: "Bootstrap sample input"
        )

        do {
            let result: MatrixMasterComputationResult
            switch selectedMode {
            case .exact:
                result = try await exactEngine.compute(request)
            case .numeric:
                result = try await numericEngine.compute(request)
            }

            lastResult = result
            syncState = .syncing

            let snapshot = MatrixMasterShellSnapshot(
                selectedDestination: destination,
                selectedMode: selectedMode,
                updatedAt: Date()
            )
            await snapshotStore.saveSnapshot(snapshot)
            syncState = .synced
        } catch {
            lastResult = MatrixMasterComputationResult(
                answer: "Computation failed",
                diagnostics: [error.localizedDescription],
                steps: []
            )
            syncState = .needsAttention
        }
    }
}
