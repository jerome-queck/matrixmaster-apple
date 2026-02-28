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
    @Published public var secondaryMatrixDraft: MatrixDraftInput
    @Published public var vectorDraft: VectorDraftInput
    @Published public var secondaryVectorDraft: VectorDraftInput
    @Published public var basisDraft: BasisDraftInput
    @Published public var secondaryBasisDraft: BasisDraftInput
    @Published public var analyzeKind: MatrixAnalyzeKind
    @Published public var spacesKind: MatrixSpacesKind
    @Published public var operateKind: MatrixOperateKind
    @Published public var operateScalarToken: String
    @Published public var operateExponent: Int
    @Published public var operateExpression: String
    @Published public private(set) var lastResult: MatrixMasterComputationResult?
    @Published public private(set) var inputValidationMessage: String?
    @Published public private(set) var persistenceMessage: String?
    @Published public private(set) var reuseMessage: String?
    @Published public private(set) var libraryMessage: String?
    @Published public private(set) var libraryVectors: [MatrixLibraryVectorItem]
    @Published public private(set) var libraryHistory: [MatrixLibraryHistoryEntry]

    private let exactEngine: any MatrixExactComputing
    private let numericEngine: any MatrixNumericComputing
    private let snapshotStore: any WorkspaceSnapshotStoring
    private let syncCoordinator: any WorkspaceSyncCoordinating
    private let libraryStore: any LibraryCatalogStoring
    private let libraryExportURL: URL
    private let fileManager: FileManager

    public init(
        selectedMode: MatrixMasterMathMode = .exact,
        syncState: MatrixMasterSyncState = .localOnly,
        matrixDraft: MatrixDraftInput = MatrixDraftInput(),
        secondaryMatrixDraft: MatrixDraftInput = MatrixDraftInput(),
        vectorDraft: VectorDraftInput = VectorDraftInput(name: "v1"),
        secondaryVectorDraft: VectorDraftInput = VectorDraftInput(name: "v2"),
        basisDraft: BasisDraftInput = BasisDraftInput(),
        secondaryBasisDraft: BasisDraftInput = BasisDraftInput(name: "W"),
        analyzeKind: MatrixAnalyzeKind = .matrixProperties,
        spacesKind: MatrixSpacesKind = .basisTestExtract,
        operateKind: MatrixOperateKind = .matrixAdd,
        operateScalarToken: String = "2",
        operateExponent: Int = 2,
        operateExpression: String = "A * B",
        exactEngine: any MatrixExactComputing = MatrixExactEngine(),
        numericEngine: any MatrixNumericComputing = StubMatrixNumericEngine(),
        snapshotStore: any WorkspaceSnapshotStoring = InMemoryWorkspaceSnapshotStore(),
        syncCoordinator: any WorkspaceSyncCoordinating = InMemoryWorkspaceSyncCoordinator(),
        libraryStore: any LibraryCatalogStoring = InMemoryLibraryCatalogStore(),
        libraryExportURL: URL = MatrixWorkspaceFileLocations.defaultLibraryExportURL(),
        fileManager: FileManager = .default
    ) {
        self.selectedMode = selectedMode
        self.syncState = syncState
        self.matrixDraft = matrixDraft
        self.secondaryMatrixDraft = secondaryMatrixDraft
        self.vectorDraft = vectorDraft
        self.secondaryVectorDraft = secondaryVectorDraft
        self.basisDraft = basisDraft
        self.secondaryBasisDraft = secondaryBasisDraft
        self.analyzeKind = analyzeKind
        self.spacesKind = spacesKind
        self.operateKind = operateKind
        self.operateScalarToken = operateScalarToken
        self.operateExponent = max(1, operateExponent)
        self.operateExpression = operateExpression
        self.exactEngine = exactEngine
        self.numericEngine = numericEngine
        self.snapshotStore = snapshotStore
        self.syncCoordinator = syncCoordinator
        self.libraryStore = libraryStore
        self.libraryExportURL = libraryExportURL
        self.fileManager = fileManager
        self.libraryMessage = nil
        self.libraryVectors = []
        self.libraryHistory = []
    }

    public static func foundationCoordinator(
        snapshotURL: URL = MatrixWorkspaceFileLocations.defaultSnapshotURL(),
        syncStatusURL: URL = MatrixWorkspaceFileLocations.defaultSyncStatusURL(),
        libraryCatalogURL: URL = MatrixWorkspaceFileLocations.defaultLibraryCatalogURL(),
        libraryExportURL: URL = MatrixWorkspaceFileLocations.defaultLibraryExportURL()
    ) -> MatrixMasterFeatureCoordinator {
        let snapshotStore: any WorkspaceSnapshotStoring = FileWorkspaceSnapshotStore(fileURL: snapshotURL)
        let libraryStore: any LibraryCatalogStoring = FileLibraryCatalogStore(fileURL: libraryCatalogURL)

        let syncCoordinator: any WorkspaceSyncCoordinating
        do {
            syncCoordinator = try FileWorkspaceSyncCoordinator(fileURL: syncStatusURL)
        } catch {
            let fallback = WorkspaceSyncSnapshot(state: .needsAttention)
            syncCoordinator = InMemoryWorkspaceSyncCoordinator(initialSnapshot: fallback)
        }

        return MatrixMasterFeatureCoordinator(
            snapshotStore: snapshotStore,
            syncCoordinator: syncCoordinator,
            libraryStore: libraryStore,
            libraryExportURL: libraryExportURL
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

        await refreshLibrary()
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
        reuseMessage = nil
        libraryMessage = nil

        if destination == .library {
            await runLibrarySummary()
            return
        }

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
            inputSummary: inputSummary(for: destination),
            matrixEntries: matrixEntriesForRequest(destination: destination),
            secondaryMatrixEntries: secondaryMatrixEntriesForRequest(destination: destination),
            vectorEntries: vectorEntriesForRequest(destination: destination),
            secondaryVectorEntries: secondaryVectorEntriesForRequest(destination: destination),
            scalarToken: scalarTokenForRequest(destination: destination),
            exponent: exponentForRequest(destination: destination),
            operateKind: operateKindForRequest(destination: destination),
            expression: expressionForRequest(destination: destination),
            basisVectors: basisVectorsForRequest(destination: destination),
            secondaryBasisVectors: secondaryBasisVectorsForRequest(destination: destination),
            analyzeKind: analyzeKindForRequest(destination: destination),
            spacesKind: spacesKindForRequest(destination: destination)
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

    public func applyReusePayload(_ payload: MatrixMasterReusablePayload, into destination: MatrixMasterDestination) {
        switch payload {
        case let .matrix(matrixPayload):
            matrixDraft = MatrixDraftInput(entries: matrixPayload.entries)
            reuseMessage = "Prefilled \(destination.title) matrix input from \(matrixPayload.source)."
        case let .vector(vectorPayload):
            vectorDraft = VectorDraftInput(name: vectorPayload.name, entries: vectorPayload.entries)
            reuseMessage = "Prefilled \(destination.title) vector input from \(vectorPayload.source)."
        }
    }

    public func refreshLibrary() async {
        do {
            libraryVectors = try await libraryStore.loadVectors()
            libraryHistory = try await libraryStore.loadHistory(limit: 25)
        } catch {
            let message = "Could not load Library catalog: \(error.localizedDescription)"
            persistenceMessage = message
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
        }
    }

    public func saveCurrentVectorDraftToLibrary() async {
        inputValidationMessage = nil
        persistenceMessage = nil
        libraryMessage = nil

        do {
            let validatedEntries = try vectorDraft.validatedEntries(vectorIndex: 0)
            let savedItem = try await libraryStore.saveVector(
                name: vectorDraft.name,
                entries: validatedEntries
            )
            try await libraryStore.appendHistory(
                MatrixLibraryHistoryEntry(
                    title: "Saved vector",
                    detail: "\(savedItem.name) (\(savedItem.entries.count) entries)."
                )
            )
            await refreshLibrary()
            libraryMessage = "Saved \(savedItem.name) to Library."
            await recordSyncWriteForLibrary()
        } catch {
            let message = validationMessage(for: error)
            inputValidationMessage = message
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
        }
    }

    public func loadLibraryVectorIntoDraft(_ item: MatrixLibraryVectorItem) {
        vectorDraft = VectorDraftInput(name: item.name, entries: item.entries)
        libraryMessage = "Loaded \(item.name) into the vector draft."

        Task {
            try? await libraryStore.appendHistory(
                MatrixLibraryHistoryEntry(
                    title: "Loaded vector",
                    detail: "\(item.name) into draft."
                )
            )
            await refreshLibrary()
        }
    }

    public func deleteLibraryVector(_ item: MatrixLibraryVectorItem) async {
        do {
            try await libraryStore.deleteVector(id: item.id)
            try await libraryStore.appendHistory(
                MatrixLibraryHistoryEntry(
                    title: "Deleted vector",
                    detail: "\(item.name) removed."
                )
            )
            await refreshLibrary()
            libraryMessage = "Deleted \(item.name) from Library."
            await recordSyncWriteForLibrary()
        } catch {
            let message = "Could not delete Library vector: \(error.localizedDescription)"
            persistenceMessage = message
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
        }
    }

    public func exportLibraryCatalog() async {
        do {
            let data = try await libraryStore.exportSnapshotData()
            let parent = libraryExportURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
            try data.write(to: libraryExportURL, options: .atomic)

            try await libraryStore.appendHistory(
                MatrixLibraryHistoryEntry(
                    title: "Exported library",
                    detail: libraryExportURL.lastPathComponent
                )
            )
            await refreshLibrary()
            libraryMessage = "Exported Library catalog to \(libraryExportURL.path)."
        } catch {
            let message = "Could not export Library catalog: \(error.localizedDescription)"
            persistenceMessage = message
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
        }
    }

    public var libraryExportPath: String {
        libraryExportURL.path
    }

    private func validateInputs(for destination: MatrixMasterDestination) throws {
        switch destination {
        case .solve:
            _ = try matrixDraft.validatedEntries()
        case .analyze:
            try validateAnalyzeInputs()
        case .spaces:
            try validateSpacesInputs()
        case .operate:
            _ = try matrixDraft.validatedEntries()
            try validateOperateInputs()
        case .library:
            _ = try vectorDraft.validatedEntries(vectorIndex: 0)
        }
    }

    private func inputSummary(for destination: MatrixMasterDestination) -> String {
        switch destination {
        case .solve:
            return "Matrix \(matrixDraft.rows)x\(matrixDraft.columns), mode: \(selectedMode.rawValue)"
        case .analyze:
            return "Analyze \(analyzeKind.title), matrix \(matrixDraft.rows)x\(matrixDraft.columns), basis vectors: \(basisDraft.vectorCount), vector dimension: \(vectorDraft.dimension), mode: \(selectedMode.rawValue)"
        case .spaces:
            return "Spaces \(spacesKind.title), U vectors: \(basisDraft.vectorCount), W vectors: \(secondaryBasisDraft.vectorCount), dimension: \(basisDraft.dimension), mode: \(selectedMode.rawValue)"
        case .operate:
            return "Operate \(operateKind.title), matrix \(matrixDraft.rows)x\(matrixDraft.columns), mode: \(selectedMode.rawValue)"
        case .library:
            return "Vector dimension \(vectorDraft.dimension), mode: \(selectedMode.rawValue)"
        }
    }

    private func matrixEntriesForRequest(destination: MatrixMasterDestination) -> [[String]]? {
        switch destination {
        case .solve, .operate:
            return matrixDraft.entries
        case .analyze:
            return analyzeKind == .matrixProperties ? matrixDraft.entries : nil
        case .spaces, .library:
            return nil
        }
    }

    private func secondaryMatrixEntriesForRequest(destination: MatrixMasterDestination) -> [[String]]? {
        guard destination == .operate else {
            return nil
        }

        return secondaryMatrixDraft.entries
    }

    private func vectorEntriesForRequest(destination: MatrixMasterDestination) -> [String]? {
        switch destination {
        case .operate:
            return vectorDraft.entries
        case .analyze:
            switch analyzeKind {
            case .spanMembership, .coordinates:
                return vectorDraft.entries
            case .matrixProperties, .independence:
                return nil
            }
        case .solve, .spaces, .library:
            return nil
        }
    }

    private func secondaryVectorEntriesForRequest(destination: MatrixMasterDestination) -> [String]? {
        guard destination == .operate else {
            return nil
        }

        return secondaryVectorDraft.entries
    }

    private func scalarTokenForRequest(destination: MatrixMasterDestination) -> String? {
        guard destination == .operate else {
            return nil
        }

        return operateScalarToken
    }

    private func exponentForRequest(destination: MatrixMasterDestination) -> Int? {
        guard destination == .operate else {
            return nil
        }

        return max(1, operateExponent)
    }

    private func operateKindForRequest(destination: MatrixMasterDestination) -> MatrixOperateKind? {
        guard destination == .operate else {
            return nil
        }

        return operateKind
    }

    private func expressionForRequest(destination: MatrixMasterDestination) -> String? {
        guard destination == .operate else {
            return nil
        }

        return operateExpression
    }

    private func basisVectorsForRequest(destination: MatrixMasterDestination) -> [[String]]? {
        guard destination == .analyze || destination == .spaces else {
            return nil
        }

        return basisDraft.vectors.map(\.entries)
    }

    private func secondaryBasisVectorsForRequest(destination: MatrixMasterDestination) -> [[String]]? {
        guard destination == .spaces else {
            return nil
        }

        return secondaryBasisDraft.vectors.map(\.entries)
    }

    private func analyzeKindForRequest(destination: MatrixMasterDestination) -> MatrixAnalyzeKind? {
        guard destination == .analyze else {
            return nil
        }

        return analyzeKind
    }

    private func spacesKindForRequest(destination: MatrixMasterDestination) -> MatrixSpacesKind? {
        guard destination == .spaces else {
            return nil
        }

        return spacesKind
    }

    private func validateOperateInputs() throws {
        switch operateKind {
        case .matrixAdd, .matrixSubtract, .matrixMultiply:
            _ = try secondaryMatrixDraft.validatedEntries()
        case .matrixVectorProduct:
            _ = try vectorDraft.validatedEntries(vectorIndex: 0)
        case .vectorAdd:
            _ = try vectorDraft.validatedEntries(vectorIndex: 0)
            _ = try secondaryVectorDraft.validatedEntries(vectorIndex: 1)
        case .scalarVectorMultiply:
            _ = try vectorDraft.validatedEntries(vectorIndex: 0)
            if let issue = MatrixInputTokenValidator.issue(for: operateScalarToken) {
                switch issue {
                case .empty:
                    throw MatrixInputValidationError.emptyVectorEntry(vectorIndex: 0, entryIndex: 0)
                case .invalid:
                    throw MatrixInputValidationError.invalidVectorEntry(
                        vectorIndex: 0,
                        entryIndex: 0,
                        value: operateScalarToken
                    )
                case .zeroDenominator:
                    throw MatrixInputValidationError.zeroDenominatorVectorEntry(
                        vectorIndex: 0,
                        entryIndex: 0,
                        value: operateScalarToken
                    )
                }
            }
        case .power:
            operateExponent = max(1, operateExponent)
        case .expression, .transpose, .trace:
            break
        }
    }

    private func validateAnalyzeInputs() throws {
        switch analyzeKind {
        case .matrixProperties:
            _ = try matrixDraft.validatedEntries()
            _ = try basisDraft.validatedVectors()
        case .spanMembership, .coordinates:
            _ = try basisDraft.validatedVectors()
            _ = try vectorDraft.validatedEntries(vectorIndex: 0)
        case .independence:
            _ = try basisDraft.validatedVectors()
        }
    }

    private func validateSpacesInputs() throws {
        let basisVectors = try basisDraft.validatedVectors()
        let primaryDimension = basisVectors.first?.count ?? 0

        switch spacesKind {
        case .basisTestExtract, .basisExtendPrune:
            return
        case .subspaceSum, .subspaceIntersection, .directSumCheck:
            let secondaryVectors = try secondaryBasisDraft.validatedVectors()
            let secondaryDimension = secondaryVectors.first?.count ?? 0
            guard secondaryDimension == primaryDimension else {
                throw MatrixInputValidationError.inconsistentVectorLength(
                    expected: primaryDimension,
                    actual: secondaryDimension,
                    vectorIndex: 0
                )
            }
        }
    }

    private func runLibrarySummary() async {
        await refreshLibrary()

        let answer = "Library vectors: \(libraryVectors.count) | Recent history: \(libraryHistory.count)"
        var diagnostics: [String] = [
            "Sync state: \(syncState.title).",
            "Export path: \(libraryExportURL.path)."
        ]

        if let latestVector = libraryVectors.first {
            diagnostics.append("Latest vector: \(latestVector.name) (\(latestVector.entries.count) entries).")
        }

        let steps = [
            "Use Save Draft to persist the current vector.",
            "Use Load to restore a saved vector into the draft editor.",
            "Use Export to write the Library snapshot as JSON."
        ]

        lastResult = MatrixMasterComputationResult(
            answer: answer,
            diagnostics: diagnostics,
            steps: steps
        )
    }

    private func recordSyncWriteForLibrary() async {
        do {
            try await syncCoordinator.recordLocalWrite()

            let syncSnapshot = await syncCoordinator.currentSnapshot()
            if syncSnapshot.isCloudAvailable {
                try await syncCoordinator.markRemoteConverged()
            }

            syncState = await syncCoordinator.currentState()
        } catch {
            persistenceMessage = "Could not update sync state: \(error.localizedDescription)"
            syncState = .needsAttention
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
