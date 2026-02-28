import Foundation
import MatrixDomain
import MatrixExact
import MatrixNumeric
import MatrixPersistence

@MainActor
public final class MatrixMasterFeatureCoordinator: ObservableObject {
    @Published public var selectedMode: MatrixMasterMathMode
    @Published public var syncState: MatrixMasterSyncState
    @Published public var matrixDraft: MatrixDraftInput
    @Published public var vectorDraft: VectorDraftInput
    @Published public var basisDraft: BasisDraftInput
    @Published public private(set) var lastResult: MatrixMasterComputationResult?
    @Published public private(set) var inputValidationMessage: String?
    @Published public private(set) var persistenceMessage: String?

    private let exactEngine: any MatrixExactComputing
    private let numericEngine: any MatrixNumericComputing
    private let snapshotStore: any WorkspaceSnapshotStoring
    private let syncCoordinator: any WorkspaceSyncCoordinating

    public init(
        selectedMode: MatrixMasterMathMode = .exact,
        syncState: MatrixMasterSyncState = .localOnly,
        matrixDraft: MatrixDraftInput = MatrixDraftInput(),
        vectorDraft: VectorDraftInput = VectorDraftInput(name: "v1"),
        basisDraft: BasisDraftInput = BasisDraftInput(),
        exactEngine: any MatrixExactComputing = StubMatrixExactEngine(),
        numericEngine: any MatrixNumericComputing = StubMatrixNumericEngine(),
        snapshotStore: any WorkspaceSnapshotStoring = InMemoryWorkspaceSnapshotStore(),
        syncCoordinator: any WorkspaceSyncCoordinating = InMemoryWorkspaceSyncCoordinator()
    ) {
        self.selectedMode = selectedMode
        self.syncState = syncState
        self.matrixDraft = matrixDraft
        self.vectorDraft = vectorDraft
        self.basisDraft = basisDraft
        self.exactEngine = exactEngine
        self.numericEngine = numericEngine
        self.snapshotStore = snapshotStore
        self.syncCoordinator = syncCoordinator
    }

    public static func foundationCoordinator(
        snapshotURL: URL = MatrixWorkspaceFileLocations.defaultSnapshotURL(),
        syncStatusURL: URL = MatrixWorkspaceFileLocations.defaultSyncStatusURL()
    ) -> MatrixMasterFeatureCoordinator {
        let snapshotStore: any WorkspaceSnapshotStoring = FileWorkspaceSnapshotStore(fileURL: snapshotURL)

        let syncCoordinator: any WorkspaceSyncCoordinating
        do {
            syncCoordinator = try FileWorkspaceSyncCoordinator(fileURL: syncStatusURL)
        } catch {
            let fallback = WorkspaceSyncSnapshot(state: .needsAttention)
            syncCoordinator = InMemoryWorkspaceSyncCoordinator(initialSnapshot: fallback)
        }

        return MatrixMasterFeatureCoordinator(
            snapshotStore: snapshotStore,
            syncCoordinator: syncCoordinator
        )
    }

    public func restoreLatestSnapshot() async {
        do {
            if let snapshot = try await snapshotStore.loadLatestSnapshot() {
                selectedMode = snapshot.selectedMode
            }
        } catch {
            let message = "Could not load local workspace snapshot: \(error.localizedDescription)"
            persistenceMessage = message
            try? await syncCoordinator.markNeedsAttention()
        }

        syncState = await syncCoordinator.currentState()
    }

    public func setCloudAvailability(_ isCloudAvailable: Bool) async {
        do {
            try await syncCoordinator.setCloudAvailable(isCloudAvailable)
            syncState = await syncCoordinator.currentState()
        } catch {
            let message = "Could not update cloud availability: \(error.localizedDescription)"
            persistenceMessage = message
            syncState = .needsAttention
        }
    }

    public func runQuickComputation(for destination: MatrixMasterDestination) async {
        inputValidationMessage = nil
        persistenceMessage = nil

        do {
            try validateInputs(for: destination)
        } catch {
            let message = validationMessage(for: error)
            inputValidationMessage = message
            lastResult = MatrixMasterComputationResult(
                answer: "Input validation failed",
                diagnostics: [message],
                steps: ["Correct the highlighted input and run again."]
            )
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
            return
        }

        let request = MatrixMasterComputationRequest(
            destination: destination,
            mode: selectedMode,
            inputSummary: inputSummary(for: destination)
        )

        do {
            let computedResult: MatrixMasterComputationResult
            switch selectedMode {
            case .exact:
                computedResult = try await exactEngine.compute(request)
            case .numeric:
                computedResult = try await numericEngine.compute(request)
            }

            var enrichedResult = computedResult

            let snapshot = MatrixMasterShellSnapshot(
                selectedDestination: destination,
                selectedMode: selectedMode,
                updatedAt: Date()
            )

            do {
                try await snapshotStore.saveSnapshot(snapshot)
            } catch {
                let message = "Could not save local workspace snapshot: \(error.localizedDescription)"
                persistenceMessage = message
                enrichedResult.diagnostics.append(message)
                try? await syncCoordinator.markNeedsAttention()
                syncState = await syncCoordinator.currentState()
            }

            do {
                try await syncCoordinator.recordLocalWrite()

                let syncSnapshot = await syncCoordinator.currentSnapshot()
                if syncSnapshot.isCloudAvailable {
                    try await syncCoordinator.markRemoteConverged()
                }

                syncState = await syncCoordinator.currentState()
            } catch {
                let message = "Could not update sync state: \(error.localizedDescription)"
                persistenceMessage = message
                enrichedResult.diagnostics.append(message)
                syncState = .needsAttention
            }

            lastResult = enrichedResult
        } catch {
            lastResult = MatrixMasterComputationResult(
                answer: "Computation failed",
                diagnostics: [error.localizedDescription],
                steps: []
            )
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
        }
    }

    private func validateInputs(for destination: MatrixMasterDestination) throws {
        switch destination {
        case .solve, .operate, .analyze:
            _ = try matrixDraft.validatedEntries()
        case .library:
            _ = try vectorDraft.validatedEntries(vectorIndex: 0)
        }

        if destination == .analyze {
            _ = try basisDraft.validatedVectors()
        }
    }

    private func inputSummary(for destination: MatrixMasterDestination) -> String {
        switch destination {
        case .solve, .operate, .analyze:
            return "Matrix \(matrixDraft.rows)x\(matrixDraft.columns), basis vectors: \(basisDraft.vectorCount), mode: \(selectedMode.rawValue)"
        case .library:
            return "Vector dimension \(vectorDraft.dimension), mode: \(selectedMode.rawValue)"
        }
    }

    private func validationMessage(for error: Error) -> String {
        if let validationError = error as? MatrixInputValidationError,
           let description = validationError.errorDescription {
            return description
        }

        return error.localizedDescription
    }
}
