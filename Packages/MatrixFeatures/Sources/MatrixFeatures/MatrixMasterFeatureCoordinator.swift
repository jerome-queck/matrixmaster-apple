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
    @Published public var analyzeMatrixPropertiesSelection: MatrixAnalyzeMatrixPropertiesSelection
    @Published public var linearMapDefinitionKind: MatrixLinearMapDefinitionKind
    @Published public var spacesKind: MatrixSpacesKind
    @Published public var spacesPresetKind: MatrixSpacesPresetKind
    @Published public var spacesOutputSelection: MatrixSpacesOutputSelection
    @Published public var spacesPolynomialDegree: Int
    @Published public var spacesMatrixRowCount: Int
    @Published public var spacesMatrixColumnCount: Int
    @Published public var operateKind: MatrixOperateKind
    @Published public var operateScalarToken: String
    @Published public var operateExponent: Int
    @Published public var operateExpression: String
    @Published public private(set) var lastResult: MatrixMasterComputationResult?
    @Published public private(set) var destinationResults: [MatrixMasterDestination: MatrixMasterComputationResult]
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
    private var isSynchronizingLinearMapInputs = false

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
        analyzeMatrixPropertiesSelection: MatrixAnalyzeMatrixPropertiesSelection = .all,
        linearMapDefinitionKind: MatrixLinearMapDefinitionKind = .matrix,
        spacesKind: MatrixSpacesKind = .basisTestExtract,
        spacesPresetKind: MatrixSpacesPresetKind = .none,
        spacesOutputSelection: MatrixSpacesOutputSelection = .all,
        spacesPolynomialDegree: Int = 2,
        spacesMatrixRowCount: Int = 2,
        spacesMatrixColumnCount: Int = 2,
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
        self.analyzeMatrixPropertiesSelection = analyzeMatrixPropertiesSelection
        self.linearMapDefinitionKind = linearMapDefinitionKind
        self.spacesKind = spacesKind
        self.spacesPresetKind = spacesPresetKind
        self.spacesOutputSelection = spacesOutputSelection
        self.spacesPolynomialDegree = max(0, spacesPolynomialDegree)
        self.spacesMatrixRowCount = max(1, spacesMatrixRowCount)
        self.spacesMatrixColumnCount = max(1, spacesMatrixColumnCount)
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
        self.destinationResults = [:]
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

        if destination == .analyze,
           analyzeKind == .matrixProperties,
           !analyzeMatrixPropertiesSelection.hasAnySelection {
            let message = "Select at least one Analyze output before running."
            inputValidationMessage = message
            let validationResult = MatrixMasterComputationResult(
                answer: "Input validation failed",
                diagnostics: [message],
                steps: ["Enable at least one Analyze output and run again."]
            )
            destinationResults[destination] = validationResult
            lastResult = validationResult
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
            return
        }

        if destination == .spaces,
           !spacesOutputSelection.hasAnySelection {
            let message = "Select at least one Spaces output before running."
            inputValidationMessage = message
            let validationResult = MatrixMasterComputationResult(
                answer: "Input validation failed",
                diagnostics: [message],
                steps: ["Enable at least one Spaces output and run again."]
            )
            destinationResults[destination] = validationResult
            lastResult = validationResult
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
            return
        }

        do {
            try validateInputs(for: destination)
        } catch {
            let message = validationMessage(for: error)
            inputValidationMessage = message
            let validationResult = MatrixMasterComputationResult(
                answer: "Input validation failed",
                diagnostics: [message],
                steps: ["Correct the highlighted input and run again."]
            )
            destinationResults[destination] = validationResult
            lastResult = validationResult
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
            analyzeMatrixPropertiesSelection: analyzeMatrixPropertiesSelectionForRequest(destination: destination),
            spacesKind: spacesKindForRequest(destination: destination),
            spacesPresetKind: spacesPresetKindForRequest(destination: destination),
            spacesOutputSelection: spacesOutputSelectionForRequest(destination: destination),
            spacesPolynomialDegree: spacesPolynomialDegreeForRequest(destination: destination),
            spacesMatrixRowCount: spacesMatrixRowCountForRequest(destination: destination),
            spacesMatrixColumnCount: spacesMatrixColumnCountForRequest(destination: destination),
            linearMapDefinitionKind: linearMapDefinitionKindForRequest(destination: destination)
        )

        do {
            let mode = selectedMode
            let exactEngine = self.exactEngine
            let numericEngine = self.numericEngine
            let computedResult = try await Task.detached(priority: .userInitiated) {
                switch mode {
                case .exact:
                    return try await exactEngine.compute(request)
                case .numeric:
                    return try await numericEngine.compute(request)
                }
            }.value

            var enrichedResult = computedResult
            enrichedResult = enrichResultForPresentation(
                enrichedResult,
                destination: destination
            )

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

            destinationResults[destination] = enrichedResult
            lastResult = enrichedResult
        } catch {
            let failureResult = MatrixMasterComputationResult(
                answer: "Computation failed",
                diagnostics: [error.localizedDescription],
                steps: []
            )
            destinationResults[destination] = failureResult
            lastResult = failureResult
            try? await syncCoordinator.markNeedsAttention()
            syncState = await syncCoordinator.currentState()
        }
    }

    public func result(for destination: MatrixMasterDestination) -> MatrixMasterComputationResult? {
        destinationResults[destination]
    }

    public func didSelectDestination(_ destination: MatrixMasterDestination) {
        inputValidationMessage = nil
        persistenceMessage = nil
        reuseMessage = nil
        libraryMessage = nil
        lastResult = destinationResults[destination]
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

    public func synchronizeAnalyzeLinearMapFromBasis() {
        guard analyzeKind == .linearMaps else {
            return
        }
        guard !isSynchronizingLinearMapInputs else {
            return
        }

        isSynchronizingLinearMapInputs = true
        defer { isSynchronizingLinearMapInputs = false }

        let domainDimension = max(1, basisDraft.vectorCount)
        let codomainDimension = max(1, secondaryBasisDraft.vectorCount)

        synchronizeLinearMapBasis(&basisDraft, squareDimension: domainDimension, namePrefix: "b")
        synchronizeLinearMapBasis(&secondaryBasisDraft, squareDimension: codomainDimension, namePrefix: "g")
        resizeMatrix(&matrixDraft, rows: codomainDimension, columns: domainDimension)
        resizeMatrix(&secondaryMatrixDraft, rows: codomainDimension, columns: domainDimension)
    }

    public func synchronizeAnalyzeLinearMapFromMatrix() {
        guard analyzeKind == .linearMaps else {
            return
        }
        guard !isSynchronizingLinearMapInputs else {
            return
        }

        isSynchronizingLinearMapInputs = true
        defer { isSynchronizingLinearMapInputs = false }

        let domainDimension = max(1, matrixDraft.columns)
        let codomainDimension = max(1, matrixDraft.rows)

        synchronizeLinearMapBasis(&basisDraft, squareDimension: domainDimension, namePrefix: "b")
        synchronizeLinearMapBasis(&secondaryBasisDraft, squareDimension: codomainDimension, namePrefix: "g")
        resizeMatrix(&secondaryMatrixDraft, rows: codomainDimension, columns: domainDimension)
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

    public func applySpacesPresetToPrimarySet() {
        applySpacesPreset(toPrimary: true, toSecondary: false)
    }

    public func applySpacesPresetToSecondarySet() {
        applySpacesPreset(toPrimary: false, toSecondary: true)
    }

    public func applySpacesPresetToBothSets() {
        applySpacesPreset(toPrimary: true, toSecondary: true)
    }

    public var spacesPresetSummary: String {
        switch spacesPresetKind {
        case .none:
            return MatrixSpacesPresetKind.none.title
        case .polynomialSpace:
            return "P\(subscriptNumber(max(0, spacesPolynomialDegree)))(F)"
        case .matrixSpace:
            return "M\(subscriptNumber(max(1, spacesMatrixRowCount)))×\(subscriptNumber(max(1, spacesMatrixColumnCount)))(F)"
        }
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
            if analyzeKind == .linearMaps {
                return "Analyze \(analyzeKind.title), definition: \(linearMapDefinitionKind.title), map matrix: \(matrixDraft.rows)x\(matrixDraft.columns), image matrix: \(secondaryMatrixDraft.rows)x\(secondaryMatrixDraft.columns), domain basis vectors: \(basisDraft.vectorCount), codomain basis vectors: \(secondaryBasisDraft.vectorCount), mode: \(selectedMode.rawValue)"
            }

            return "Analyze \(analyzeKind.title), matrix \(matrixDraft.rows)x\(matrixDraft.columns), basis vectors: \(basisDraft.vectorCount), vector dimension: \(vectorDraft.dimension), mode: \(selectedMode.rawValue)"
        case .spaces:
            return "Spaces \(spacesKind.title), U vectors: \(basisDraft.vectorCount), W vectors: \(secondaryBasisDraft.vectorCount), dimension: \(basisDraft.dimension), preset: \(spacesPresetSummary), mode: \(selectedMode.rawValue)"
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
            switch analyzeKind {
            case .matrixProperties, .linearMaps:
                return matrixDraft.entries
            case .spanMembership, .independence, .coordinates:
                return nil
            }
        case .spaces, .library:
            return nil
        }
    }

    private func secondaryMatrixEntriesForRequest(destination: MatrixMasterDestination) -> [[String]]? {
        switch destination {
        case .operate:
            return secondaryMatrixDraft.entries
        case .analyze:
            return analyzeKind == .linearMaps ? secondaryMatrixDraft.entries : nil
        case .solve, .spaces, .library:
            return nil
        }
    }

    private func vectorEntriesForRequest(destination: MatrixMasterDestination) -> [String]? {
        switch destination {
        case .operate:
            return vectorDraft.entries
        case .analyze:
            switch analyzeKind {
            case .spanMembership, .coordinates:
                return vectorDraft.entries
            case .matrixProperties, .independence, .linearMaps:
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
        switch destination {
        case .spaces:
            return secondaryBasisDraft.vectors.map(\.entries)
        case .analyze:
            return analyzeKind == .linearMaps ? secondaryBasisDraft.vectors.map(\.entries) : nil
        case .solve, .operate, .library:
            return nil
        }
    }

    private func analyzeKindForRequest(destination: MatrixMasterDestination) -> MatrixAnalyzeKind? {
        guard destination == .analyze else {
            return nil
        }

        return analyzeKind
    }

    private func analyzeMatrixPropertiesSelectionForRequest(
        destination: MatrixMasterDestination
    ) -> MatrixAnalyzeMatrixPropertiesSelection? {
        guard destination == .analyze, analyzeKind == .matrixProperties else {
            return nil
        }
        return analyzeMatrixPropertiesSelection
    }

    private func spacesKindForRequest(destination: MatrixMasterDestination) -> MatrixSpacesKind? {
        guard destination == .spaces else {
            return nil
        }

        return spacesKind
    }

    private func spacesPresetKindForRequest(destination: MatrixMasterDestination) -> MatrixSpacesPresetKind? {
        guard destination == .spaces else {
            return nil
        }

        return spacesPresetKind
    }

    private func spacesOutputSelectionForRequest(destination: MatrixMasterDestination) -> MatrixSpacesOutputSelection? {
        guard destination == .spaces else {
            return nil
        }

        return spacesOutputSelection
    }

    private func spacesPolynomialDegreeForRequest(destination: MatrixMasterDestination) -> Int? {
        guard destination == .spaces, spacesPresetKind == .polynomialSpace else {
            return nil
        }

        return max(0, spacesPolynomialDegree)
    }

    private func spacesMatrixRowCountForRequest(destination: MatrixMasterDestination) -> Int? {
        guard destination == .spaces, spacesPresetKind == .matrixSpace else {
            return nil
        }

        return max(1, spacesMatrixRowCount)
    }

    private func spacesMatrixColumnCountForRequest(destination: MatrixMasterDestination) -> Int? {
        guard destination == .spaces, spacesPresetKind == .matrixSpace else {
            return nil
        }

        return max(1, spacesMatrixColumnCount)
    }

    private func linearMapDefinitionKindForRequest(destination: MatrixMasterDestination) -> MatrixLinearMapDefinitionKind? {
        guard destination == .analyze, analyzeKind == .linearMaps else {
            return nil
        }

        return linearMapDefinitionKind
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
        case .linearMaps:
            _ = try basisDraft.validatedVectors()
            _ = try secondaryBasisDraft.validatedVectors()

            switch linearMapDefinitionKind {
            case .matrix:
                _ = try matrixDraft.validatedEntries()
            case .basisImages:
                _ = try secondaryMatrixDraft.validatedEntries()
            }
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

    private func applySpacesPreset(toPrimary: Bool, toSecondary: Bool) {
        guard spacesPresetKind != .none else {
            return
        }

        let vectors = spacesPresetVectors()
        guard !vectors.isEmpty else {
            return
        }

        let presetLabel = spacesPresetSummary
        if toPrimary {
            basisDraft = BasisDraftInput(
                name: toSecondary ? "U (\(presetLabel))" : basisDraft.name,
                vectors: vectors
            )
        }
        if toSecondary {
            secondaryBasisDraft = BasisDraftInput(
                name: "W (\(presetLabel))",
                vectors: vectors
            )
        }
    }

    private func spacesPresetVectors() -> [VectorDraftInput] {
        switch spacesPresetKind {
        case .none:
            return []
        case .polynomialSpace:
            let degree = max(0, spacesPolynomialDegree)
            let dimension = degree + 1
            return canonicalBasisVectors(
                dimension: dimension,
                names: (0...degree).map(polynomialBasisLabel(forDegree:))
            )
        case .matrixSpace:
            let rows = max(1, spacesMatrixRowCount)
            let columns = max(1, spacesMatrixColumnCount)
            let dimension = rows * columns

            var names: [String] = []
            names.reserveCapacity(dimension)
            for row in 1...rows {
                for column in 1...columns {
                    names.append("E\(row)\(column)")
                }
            }

            return canonicalBasisVectors(dimension: dimension, names: names)
        }
    }

    private func canonicalBasisVectors(dimension: Int, names: [String]) -> [VectorDraftInput] {
        let safeDimension = max(1, dimension)
        var vectors: [VectorDraftInput] = []
        vectors.reserveCapacity(safeDimension)

        for index in 0..<safeDimension {
            var entries = Array(repeating: "0", count: safeDimension)
            entries[index] = "1"
            let name = index < names.count ? names[index] : "e\(index + 1)"
            vectors.append(VectorDraftInput(name: name, entries: entries))
        }

        return vectors
    }

    private func polynomialBasisLabel(forDegree degree: Int) -> String {
        switch degree {
        case 0:
            return "1"
        case 1:
            return "x"
        default:
            return "x\(superscriptNumber(degree))"
        }
    }

    private func superscriptNumber(_ number: Int) -> String {
        String(String(number).map { Self.superscriptDigitMap[$0] ?? $0 })
    }

    private func subscriptNumber(_ number: Int) -> String {
        String(String(number).map { Self.subscriptDigitMap[$0] ?? $0 })
    }

    private func enrichResultForPresentation(
        _ result: MatrixMasterComputationResult,
        destination: MatrixMasterDestination
    ) -> MatrixMasterComputationResult {
        var enriched = result
        var panels = enriched.rowReductionPanels

        if (destination == .solve || destination == .analyze),
           panels == nil {
            panels = rowReductionPanels(for: result, destination: destination)
        }
        enriched.rowReductionPanels = panels

        if enriched.structuredObjects.isEmpty {
            enriched.structuredObjects = structuredObjects(
                from: result,
                destination: destination,
                rowReductionPanels: panels
            )
        } else {
            enriched.structuredObjects = deduplicatedStructuredObjects(
                enriched.structuredObjects,
                rowReductionPanels: panels
            )
        }

        enriched.structuredObjects = Array(enriched.structuredObjects.prefix(6))
        enriched.answer = compactAnswerText(
            enriched.answer,
            destination: destination,
            rowReductionPanels: panels
        )
        enriched.diagnostics = Array(deduplicatedDisplayLines(enriched.diagnostics).prefix(14))
        enriched.steps = Array(deduplicatedDisplayLines(enriched.steps).prefix(28))

        if destination == .spaces {
            enriched = applyingSpacesOutputSelection(enriched, selection: spacesOutputSelection)
        }

        return enriched
    }

    private func applyingSpacesOutputSelection(
        _ result: MatrixMasterComputationResult,
        selection: MatrixSpacesOutputSelection
    ) -> MatrixMasterComputationResult {
        var filtered = result

        if !selection.includeConclusion {
            filtered.answer = "Conclusion hidden by output selection."
        }
        if !selection.includeMathObjects {
            filtered.structuredObjects = []
            filtered.rowReductionPanels = nil
        }
        if !selection.includeDiagnostics {
            filtered.diagnostics = []
        }
        if !selection.includeSteps {
            filtered.steps = []
        }

        return filtered
    }

    private func structuredObjects(
        from result: MatrixMasterComputationResult,
        destination: MatrixMasterDestination,
        rowReductionPanels: MatrixRowReductionPanels?
    ) -> [MatrixMathObject] {
        var objects: [MatrixMathObject] = []
        for payload in result.reusablePayloads {
            switch payload {
            case let .matrix(matrixPayload):
                if destination == .solve,
                   matrixPayload.source.localizedCaseInsensitiveContains("solve coefficient matrix"),
                   let augmentedEntries = solveAugmentedEntries() {
                    objects.append(
                        .matrix(
                            MatrixMathMatrixObject(
                                label: "Solve augmented matrix [A|b]",
                                entries: augmentedEntries
                            )
                        )
                    )
                    continue
                }
                objects.append(
                    .matrix(
                        MatrixMathMatrixObject(
                            label: matrixPayload.source,
                            entries: matrixPayload.entries
                        )
                    )
                )
            case let .vector(vectorPayload):
                switch (destination, spacesPresetKind) {
                case (.spaces, .polynomialSpace):
                    objects.append(
                        .polynomial(
                            MatrixMathPolynomialObject(
                                label: vectorPayload.name.isEmpty ? vectorPayload.source : vectorPayload.name,
                                coefficients: vectorPayload.entries
                            )
                        )
                    )
                case (.spaces, .matrixSpace):
                    if let matrixEntries = matrixEntriesFromVector(
                        entries: vectorPayload.entries,
                        rows: max(1, spacesMatrixRowCount),
                        columns: max(1, spacesMatrixColumnCount)
                    ) {
                        objects.append(
                            .matrix(
                                MatrixMathMatrixObject(
                                    label: vectorPayload.name.isEmpty ? vectorPayload.source : vectorPayload.name,
                                    entries: matrixEntries
                                )
                            )
                        )
                    } else {
                        objects.append(
                            .vector(
                                MatrixMathVectorObject(
                                    label: vectorPayload.name.isEmpty ? vectorPayload.source : vectorPayload.name,
                                    entries: vectorPayload.entries
                                )
                            )
                        )
                    }
                default:
                    objects.append(
                        .vector(
                            MatrixMathVectorObject(
                                label: vectorPayload.name.isEmpty ? vectorPayload.source : vectorPayload.name,
                                entries: vectorPayload.entries
                            )
                        )
                    )
                }
            }
        }

        if objects.isEmpty {
            objects = fallbackStructuredObjects(for: destination)
        }

        return deduplicatedStructuredObjects(objects, rowReductionPanels: rowReductionPanels)
    }

    private func compactAnswerText(
        _ answer: String,
        destination: MatrixMasterDestination,
        rowReductionPanels: MatrixRowReductionPanels?
    ) -> String {
        let segments = answer
            .replacingOccurrences(of: "\n", with: " | ")
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !segments.isEmpty else {
            return answer
        }

        var compact: [String] = []
        for segment in segments {
            let lower = segment.lowercased()

            if segment.contains("[[") && segment.contains("]]") {
                if let stripped = strippingInlineMatrixLiteral(from: segment),
                   !stripped.isEmpty,
                   !compact.contains(where: { $0.caseInsensitiveCompare(stripped) == .orderedSame }) {
                    compact.append(stripped)
                }
                continue
            }
            if let rowReductionPanels,
               (lower.contains("rref") || lower.contains("ref")),
               matrixLiteralEntries(in: segment) == rowReductionPanels.rrefEntries
                || matrixLiteralEntries(in: segment) == rowReductionPanels.refEntries {
                continue
            }
            if destination == .analyze && lower.contains("inverse(a) = [[") {
                continue
            }
            if destination == .analyze && lower.contains("inverse(a): available") {
                compact.append("A^-1")
                continue
            }
            if compact.contains(where: { $0.caseInsensitiveCompare(segment) == .orderedSame }) {
                continue
            }
            compact.append(segment)
        }

        if compact.isEmpty {
            if destination == .operate {
                return "Result shown below."
            }
            return segments.joined(separator: " | ")
        }

        return compact.joined(separator: " | ")
    }

    private func strippingInlineMatrixLiteral(from segment: String) -> String? {
        guard let start = segment.range(of: "[["),
              let end = segment.range(of: "]]", options: .backwards),
              start.lowerBound < end.upperBound else {
            return nil
        }

        let prefixRaw = segment[..<start.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixLower = prefixRaw.lowercased()
        if prefixLower.contains("inverse(a)") || prefixLower.contains("a^-1") {
            return "A^-1"
        }

        let prefix = prefixRaw
        let suffix = segment[end.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var combined = [String]()
        if !prefix.isEmpty {
            combined.append(String(prefix))
        }
        if !suffix.isEmpty {
            combined.append(String(suffix))
        }

        var output = combined.joined(separator: " ")
        while let last = output.last, last == "=" || last == ":" || last == "-" {
            output.removeLast()
            output = output.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return output.isEmpty ? "Result shown below." : output
    }

    private func deduplicatedDisplayLines(_ lines: [String]) -> [String] {
        var output: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }

            if trimmed.contains("[[") && trimmed.contains("]]") {
                continue
            }

            if output.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                continue
            }
            output.append(trimmed)
        }
        return output
    }

    private func deduplicatedStructuredObjects(
        _ objects: [MatrixMathObject],
        rowReductionPanels: MatrixRowReductionPanels?
    ) -> [MatrixMathObject] {
        var deduplicated: [MatrixMathObject] = []
        var signatures: Set<String> = []

        for object in objects {
            if shouldHideObjectAsRowPanelDuplicate(object, rowReductionPanels: rowReductionPanels) {
                continue
            }

            let signature = objectSignature(object)
            if signatures.insert(signature).inserted {
                deduplicated.append(object)
            }
        }

        return deduplicated
    }

    private func shouldHideObjectAsRowPanelDuplicate(
        _ object: MatrixMathObject,
        rowReductionPanels: MatrixRowReductionPanels?
    ) -> Bool {
        guard let rowReductionPanels else {
            return false
        }
        guard case let .matrix(matrixObject) = object else {
            return false
        }

        return matrixObject.entries == rowReductionPanels.refEntries
            || matrixObject.entries == rowReductionPanels.rrefEntries
    }

    private func objectSignature(_ object: MatrixMathObject) -> String {
        switch object {
        case let .matrix(matrixObject):
            return "matrix::\(matrixEntriesSignature(matrixObject.entries))"
        case let .vector(vectorObject):
            return "vector::\(vectorObject.entries.joined(separator: "|"))"
        case let .polynomial(polynomialObject):
            return "polynomial::\(polynomialObject.variableSymbol)::\(polynomialObject.coefficients.joined(separator: "|"))"
        }
    }

    private func matrixEntriesSignature(_ entries: [[String]]) -> String {
        entries
            .map { row in row.joined(separator: ",") }
            .joined(separator: ";")
    }

    private func matrixLiteralEntries(in text: String) -> [[String]]? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("[["),
              trimmed.contains("]]") else {
            return nil
        }

        guard let start = trimmed.range(of: "[["),
              let end = trimmed.range(of: "]]", options: .backwards),
              start.lowerBound < end.upperBound else {
            return nil
        }

        let literal = String(trimmed[start.lowerBound..<end.upperBound])
        var working = literal
        working.removeFirst(2)
        working.removeLast(2)

        let rows = working.components(separatedBy: "], [")
        let parsed = rows.map { row in
            row
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        guard let firstCount = parsed.first?.count,
              firstCount > 0,
              parsed.allSatisfy({ $0.count == firstCount }) else {
            return nil
        }

        return parsed
    }

    private func fallbackStructuredObjects(for destination: MatrixMasterDestination) -> [MatrixMathObject] {
        switch destination {
        case .solve:
            if let entries = solveAugmentedEntries() {
                return [
                    .matrix(
                        MatrixMathMatrixObject(
                            label: "Solve augmented matrix [A|b]",
                            entries: entries
                        )
                    )
                ]
            }
            return []
        case .operate, .analyze:
            return [
                .matrix(
                    MatrixMathMatrixObject(
                        label: "Input matrix",
                        entries: matrixDraft.entries
                    )
                )
            ]
        case .spaces:
            return spacesFallbackStructuredObjects()
        case .library:
            return [
                .vector(
                    MatrixMathVectorObject(
                        label: vectorDraft.name.isEmpty ? "Draft vector" : vectorDraft.name,
                        entries: vectorDraft.entries
                    )
                )
            ]
        }
    }

    private func spacesFallbackStructuredObjects() -> [MatrixMathObject] {
        switch spacesPresetKind {
        case .none:
            return basisDraft.vectors.prefix(3).map { vector in
                .vector(
                    MatrixMathVectorObject(
                        label: vector.name.isEmpty ? "Space vector" : vector.name,
                        entries: vector.entries
                    )
                )
            }
        case .polynomialSpace:
            return basisDraft.vectors.prefix(3).map { vector in
                .polynomial(
                    MatrixMathPolynomialObject(
                        label: vector.name.isEmpty ? "Polynomial" : vector.name,
                        coefficients: vector.entries
                    )
                )
            }
        case .matrixSpace:
            return basisDraft.vectors.prefix(3).map { vector in
                if let entries = matrixEntriesFromVector(
                    entries: vector.entries,
                    rows: max(1, spacesMatrixRowCount),
                    columns: max(1, spacesMatrixColumnCount)
                ) {
                    return .matrix(
                        MatrixMathMatrixObject(
                            label: vector.name.isEmpty ? "Matrix element" : vector.name,
                            entries: entries
                        )
                    )
                }
                return .vector(
                    MatrixMathVectorObject(
                        label: vector.name.isEmpty ? "Space vector" : vector.name,
                        entries: vector.entries
                    )
                )
            }
        }
    }

    private func rowReductionPanels(
        for result: MatrixMasterComputationResult,
        destination: MatrixMasterDestination
    ) -> MatrixRowReductionPanels? {
        if destination == .analyze,
           analyzeKind == .matrixProperties,
           !analyzeMatrixPropertiesSelection.includeRowReductionPanels {
            return nil
        }

        guard let eliminationSource = eliminationSourceEntries(for: destination) else {
            return nil
        }

        if let rrefPayload = rrefEntries(in: result) {
            if var computed = MatrixRowReductionPreviewBuilder.build(
                sourceEntries: eliminationSource.entries,
                mode: selectedMode,
                sourceLabel: eliminationSource.label,
                separatorAfterColumn: eliminationSource.separatorAfterColumn
            ) {
                computed.rrefEntries = rrefPayload.entries
                return computed
            }

            return MatrixRowReductionPanels(
                sourceLabel: rrefPayload.label,
                refEntries: rrefPayload.entries,
                rrefEntries: rrefPayload.entries,
                separatorAfterColumn: eliminationSource.separatorAfterColumn
            )
        }

        return MatrixRowReductionPreviewBuilder.build(
            sourceEntries: eliminationSource.entries,
            mode: selectedMode,
            sourceLabel: eliminationSource.label,
            separatorAfterColumn: eliminationSource.separatorAfterColumn
        )
    }

    private func eliminationSourceEntries(
        for destination: MatrixMasterDestination
    ) -> (label: String, entries: [[String]], separatorAfterColumn: Int?)? {
        switch destination {
        case .solve:
            guard let entries = solveAugmentedEntries() else {
                return nil
            }
            return ("Solve augmented matrix [A|b]", entries, max(1, matrixDraft.columns - 1))
        case .analyze:
            switch analyzeKind {
            case .matrixProperties:
                return ("Analyze matrix", matrixDraft.entries, nil)
            case .spanMembership, .coordinates, .independence:
                guard let basisMatrix = basisAsMatrixEntries(basisDraft) else {
                    return nil
                }
                return ("Analyze basis matrix", basisMatrix, nil)
            case .linearMaps:
                switch linearMapDefinitionKind {
                case .matrix:
                    return ("Linear maps matrix A", matrixDraft.entries, nil)
                case .basisImages:
                    return ("Linear maps image matrix Y", secondaryMatrixDraft.entries, nil)
                }
            }
        case .operate, .spaces, .library:
            return nil
        }
    }

    private func solveAugmentedEntries() -> [[String]]? {
        guard matrixDraft.columns >= 2 else {
            return nil
        }
        return matrixDraft.entries
    }

    private func solveCoefficientEntries() -> [[String]]? {
        guard matrixDraft.columns >= 2 else {
            return nil
        }
        return matrixDraft.entries.map { row in
            Array(row.dropLast())
        }
    }

    private func basisAsMatrixEntries(_ basis: BasisDraftInput) -> [[String]]? {
        guard let firstVector = basis.vectors.first else {
            return nil
        }
        let rowCount = firstVector.entries.count
        let columnCount = basis.vectors.count
        guard rowCount > 0, columnCount > 0 else {
            return nil
        }

        var matrix = Array(
            repeating: Array(repeating: "0", count: columnCount),
            count: rowCount
        )

        for column in 0..<columnCount {
            let vector = basis.vectors[column]
            guard vector.entries.count == rowCount else {
                return nil
            }
            for row in 0..<rowCount {
                matrix[row][column] = vector.entries[row]
            }
        }

        return matrix
    }

    private func matrixEntriesFromVector(
        entries: [String],
        rows: Int,
        columns: Int
    ) -> [[String]]? {
        let safeRows = max(1, rows)
        let safeColumns = max(1, columns)
        guard entries.count == safeRows * safeColumns else {
            return nil
        }

        var matrix: [[String]] = []
        matrix.reserveCapacity(safeRows)
        for row in 0..<safeRows {
            let start = row * safeColumns
            let end = start + safeColumns
            matrix.append(Array(entries[start..<end]))
        }
        return matrix
    }

    private func rrefEntries(
        in result: MatrixMasterComputationResult
    ) -> (label: String, entries: [[String]])? {
        for payload in result.reusablePayloads {
            guard case let .matrix(matrixPayload) = payload else {
                continue
            }

            if matrixPayload.source.localizedCaseInsensitiveContains("rref") {
                return (matrixPayload.source, matrixPayload.entries)
            }
        }
        return nil
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

        let libraryResult = MatrixMasterComputationResult(
            answer: answer,
            diagnostics: diagnostics,
            steps: steps
        )
        destinationResults[.library] = libraryResult
        lastResult = libraryResult
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

    private func synchronizeLinearMapBasis(
        _ basis: inout BasisDraftInput,
        squareDimension: Int,
        namePrefix: String
    ) {
        let safeDimension = max(1, squareDimension)

        while basis.vectorCount < safeDimension {
            basis.addVector(named: "\(namePrefix)\(basis.vectorCount + 1)")
        }
        while basis.vectorCount > safeDimension {
            basis.removeLastVector()
        }

        basis.alignVectors(to: safeDimension)
    }

    private func resizeMatrix(_ matrix: inout MatrixDraftInput, rows: Int, columns: Int) {
        let safeRows = max(1, rows)
        let safeColumns = max(1, columns)

        while matrix.rows < safeRows {
            matrix.addRow()
        }
        while matrix.rows > safeRows {
            matrix.removeLastRow()
        }
        while matrix.columns < safeColumns {
            matrix.addColumn()
        }
        while matrix.columns > safeColumns {
            matrix.removeLastColumn()
        }
    }

    private static let superscriptDigitMap: [Character: Character] = [
        "-": "⁻",
        "0": "⁰",
        "1": "¹",
        "2": "²",
        "3": "³",
        "4": "⁴",
        "5": "⁵",
        "6": "⁶",
        "7": "⁷",
        "8": "⁸",
        "9": "⁹"
    ]

    private static let subscriptDigitMap: [Character: Character] = [
        "0": "₀",
        "1": "₁",
        "2": "₂",
        "3": "₃",
        "4": "₄",
        "5": "₅",
        "6": "₆",
        "7": "₇",
        "8": "₈",
        "9": "₉"
    ]
}

private enum MatrixRowReductionPreviewBuilder {
    private static let tolerance: Double = 1.0e-9

    static func build(
        sourceEntries: [[String]],
        mode: MatrixMasterMathMode,
        sourceLabel: String,
        separatorAfterColumn: Int? = nil
    ) -> MatrixRowReductionPanels? {
        guard let parsed = parse(sourceEntries: sourceEntries) else {
            return nil
        }

        var ref = parsed
        let pivotColumns = forwardElimination(matrix: &ref)
        var rref = ref
        backwardElimination(matrix: &rref, pivotColumns: pivotColumns)

        return MatrixRowReductionPanels(
            sourceLabel: sourceLabel,
            refEntries: stringify(ref, mode: mode),
            rrefEntries: stringify(rref, mode: mode),
            separatorAfterColumn: separatorAfterColumn
        )
    }

    private static func parse(sourceEntries: [[String]]) -> [[Double]]? {
        guard let first = sourceEntries.first, !first.isEmpty else {
            return nil
        }

        guard sourceEntries.allSatisfy({ $0.count == first.count }) else {
            return nil
        }

        var matrix: [[Double]] = []
        matrix.reserveCapacity(sourceEntries.count)
        for row in sourceEntries {
            var parsedRow: [Double] = []
            parsedRow.reserveCapacity(row.count)
            for token in row {
                guard let value = parseToken(token) else {
                    return nil
                }
                parsedRow.append(value)
            }
            matrix.append(parsedRow)
        }
        return matrix
    }

    private static func parseToken(_ token: String) -> Double? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if trimmed.contains("/") {
            let parts = trimmed.split(separator: "/", omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let numerator = Double(parts[0]),
                  let denominator = Double(parts[1]),
                  abs(denominator) > tolerance else {
                return nil
            }
            return numerator / denominator
        }

        return Double(trimmed)
    }

    private static func forwardElimination(matrix: inout [[Double]]) -> [Int] {
        guard let columnCount = matrix.first?.count else {
            return []
        }

        var pivotColumns: [Int] = []
        var pivotRow = 0

        for column in 0..<columnCount where pivotRow < matrix.count {
            guard let pivotIndex = bestPivotRow(
                in: matrix,
                column: column,
                fromRow: pivotRow
            ),
            abs(matrix[pivotIndex][column]) > tolerance else {
                continue
            }

            if pivotIndex != pivotRow {
                matrix.swapAt(pivotIndex, pivotRow)
            }

            let pivot = matrix[pivotRow][column]
            for inner in column..<columnCount {
                matrix[pivotRow][inner] /= pivot
                if abs(matrix[pivotRow][inner]) < tolerance {
                    matrix[pivotRow][inner] = 0
                }
            }

            for row in (pivotRow + 1)..<matrix.count {
                let factor = matrix[row][column]
                if abs(factor) <= tolerance {
                    continue
                }
                for inner in column..<columnCount {
                    matrix[row][inner] -= factor * matrix[pivotRow][inner]
                    if abs(matrix[row][inner]) < tolerance {
                        matrix[row][inner] = 0
                    }
                }
            }

            pivotColumns.append(column)
            pivotRow += 1
        }

        return pivotColumns
    }

    private static func backwardElimination(matrix: inout [[Double]], pivotColumns: [Int]) {
        guard !pivotColumns.isEmpty else {
            return
        }

        for pivotRow in stride(from: pivotColumns.count - 1, through: 0, by: -1) {
            let pivotColumn = pivotColumns[pivotRow]
            guard pivotRow < matrix.count else {
                continue
            }

            for row in 0..<pivotRow {
                let factor = matrix[row][pivotColumn]
                if abs(factor) <= tolerance {
                    continue
                }

                for inner in pivotColumn..<matrix[row].count {
                    matrix[row][inner] -= factor * matrix[pivotRow][inner]
                    if abs(matrix[row][inner]) < tolerance {
                        matrix[row][inner] = 0
                    }
                }
            }
        }
    }

    private static func bestPivotRow(
        in matrix: [[Double]],
        column: Int,
        fromRow startRow: Int
    ) -> Int? {
        guard startRow < matrix.count else {
            return nil
        }

        var bestIndex: Int?
        var bestMagnitude: Double = 0

        for row in startRow..<matrix.count {
            let magnitude = abs(matrix[row][column])
            if magnitude > bestMagnitude {
                bestMagnitude = magnitude
                bestIndex = row
            }
        }

        return bestIndex
    }

    private static func stringify(_ matrix: [[Double]], mode: MatrixMasterMathMode) -> [[String]] {
        matrix.map { row in
            row.map { value in
                format(value: value, mode: mode)
            }
        }
    }

    private static func format(value: Double, mode: MatrixMasterMathMode) -> String {
        if abs(value) < tolerance {
            return "0"
        }

        let rounded = round(value)
        if abs(value - rounded) < tolerance {
            return String(Int(rounded))
        }

        if mode == .exact, let fraction = bestFractionApproximation(for: value, maxDenominator: 1024) {
            return fraction
        }

        return String(format: "%.6g", value)
    }

    private static func bestFractionApproximation(for value: Double, maxDenominator: Int) -> String? {
        var bestNumerator = 0
        var bestDenominator = 1
        var bestError = Double.greatestFiniteMagnitude

        for denominator in 1...max(1, maxDenominator) {
            let numerator = Int((value * Double(denominator)).rounded())
            let candidate = Double(numerator) / Double(denominator)
            let error = abs(value - candidate)
            if error < bestError {
                bestError = error
                bestNumerator = numerator
                bestDenominator = denominator
            }
        }

        let divisor = gcd(abs(bestNumerator), bestDenominator)
        let normalizedNumerator = bestNumerator / divisor
        let normalizedDenominator = bestDenominator / divisor
        if normalizedDenominator == 1 {
            return String(normalizedNumerator)
        }
        return "\(normalizedNumerator)/\(normalizedDenominator)"
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var x = a
        var y = b
        while y != 0 {
            let remainder = x % y
            x = y
            y = remainder
        }
        return max(1, x)
    }
}
