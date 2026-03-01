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

    func testCoordinatorNumericSolveNoLongerUsesPendingPlaceholder() async {
        var solveDraft = MatrixDraftInput(rows: 2, columns: 3)
        solveDraft.setValue("1", row: 0, column: 0)
        solveDraft.setValue("1", row: 0, column: 1)
        solveDraft.setValue("2", row: 0, column: 2)
        solveDraft.setValue("2", row: 1, column: 0)
        solveDraft.setValue("-1", row: 1, column: 1)
        solveDraft.setValue("0", row: 1, column: 2)

        let coordinator = MatrixMasterFeatureCoordinator(
            selectedMode: .numeric,
            matrixDraft: solveDraft
        )

        await coordinator.runQuickComputation(for: .solve)

        XCTAssertTrue(coordinator.lastResult?.answer.contains("Unique solution") == true)
        XCTAssertFalse(coordinator.lastResult?.answer.contains("pending") == true)
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

    func testCoordinatorAppliesSolveReusePayloadsAcrossDestinations() async throws {
        var solveDraft = MatrixDraftInput(rows: 2, columns: 3)
        solveDraft.setValue("1", row: 0, column: 0)
        solveDraft.setValue("1", row: 0, column: 1)
        solveDraft.setValue("2", row: 0, column: 2)
        solveDraft.setValue("2", row: 1, column: 0)
        solveDraft.setValue("-1", row: 1, column: 1)
        solveDraft.setValue("0", row: 1, column: 2)

        let coordinator = MatrixMasterFeatureCoordinator(matrixDraft: solveDraft)
        await coordinator.runQuickComputation(for: .solve)

        guard let result = coordinator.lastResult else {
            return XCTFail("Expected solve result.")
        }

        guard let matrixPayload = result.reusablePayloads.first(where: {
            if case .matrix = $0 { return true }
            return false
        }) else {
            return XCTFail("Expected matrix payload.")
        }

        guard let vectorPayload = result.reusablePayloads.first(where: {
            if case .vector = $0 { return true }
            return false
        }) else {
            return XCTFail("Expected vector payload.")
        }

        coordinator.applyReusePayload(matrixPayload, into: .analyze)
        XCTAssertEqual(coordinator.matrixDraft.rows, 2)
        XCTAssertEqual(coordinator.matrixDraft.columns, 2)
        XCTAssertEqual(coordinator.matrixDraft.value(atRow: 1, column: 0), "2")
        XCTAssertTrue(coordinator.reuseMessage?.contains("Analyze") == true)

        coordinator.applyReusePayload(vectorPayload, into: .operate)
        XCTAssertEqual(coordinator.vectorDraft.name, "Solve solution")
        XCTAssertEqual(coordinator.vectorDraft.entries, ["2/3", "4/3"])
        XCTAssertTrue(coordinator.reuseMessage?.contains("Operate") == true)

        coordinator.applyReusePayload(vectorPayload, into: .library)
        XCTAssertEqual(coordinator.vectorDraft.name, "Solve solution")
        XCTAssertTrue(coordinator.reuseMessage?.contains("Library") == true)
    }

    func testCoordinatorAnalyzeProducesReusableMatrixPayloads() async {
        var draft = MatrixDraftInput(rows: 2, columns: 2)
        draft.setValue("1", row: 0, column: 0)
        draft.setValue("2", row: 0, column: 1)
        draft.setValue("3", row: 1, column: 0)
        draft.setValue("4", row: 1, column: 1)

        let coordinator = MatrixMasterFeatureCoordinator(matrixDraft: draft)
        await coordinator.runQuickComputation(for: .analyze)

        guard let result = coordinator.lastResult else {
            return XCTFail("Expected analyze result.")
        }

        XCTAssertTrue(result.answer.contains("det(A) = -2"))
        XCTAssertTrue(result.answer.contains("dim Col(A) = 2"))
        XCTAssertTrue(result.answer.contains("dim Row(A) = 2"))
        XCTAssertTrue(result.answer.contains("dim Null(A) = 0"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case .matrix(let payload) = $0 {
                return payload.source.contains("Analyze")
            }
            return false
        }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Rank-nullity check: 2 + 0 = 2") }))
    }

    func testCoordinatorAnalyzeMatrixPropertiesRespectsSelection() async {
        var draft = MatrixDraftInput(rows: 2, columns: 2)
        draft.setValue("1", row: 0, column: 0)
        draft.setValue("2", row: 0, column: 1)
        draft.setValue("3", row: 1, column: 0)
        draft.setValue("5", row: 1, column: 1)

        let selection = MatrixAnalyzeMatrixPropertiesSelection(
            includeRankNullity: false,
            includeColumnSpaceBasis: false,
            includeRowSpaceBasis: false,
            includeNullSpaceBasis: false,
            includeDeterminant: true,
            includeTrace: false,
            includeInverse: false,
            includeRowReductionPanels: false
        )

        let coordinator = MatrixMasterFeatureCoordinator(
            matrixDraft: draft,
            analyzeMatrixPropertiesSelection: selection
        )

        await coordinator.runQuickComputation(for: .analyze)

        guard let result = coordinator.lastResult else {
            return XCTFail("Expected analyze result.")
        }

        XCTAssertTrue(result.answer.contains("det(A) = -1"))
        XCTAssertFalse(result.answer.contains("trace(A)"))
        XCTAssertFalse(result.answer.contains("rank(A)"))
        XCTAssertNil(result.rowReductionPanels)
    }

    func testCoordinatorAnalyzeMatrixPropertiesRequiresAtLeastOneOutputSelection() async {
        let selection = MatrixAnalyzeMatrixPropertiesSelection(
            includeRankNullity: false,
            includeColumnSpaceBasis: false,
            includeRowSpaceBasis: false,
            includeNullSpaceBasis: false,
            includeDeterminant: false,
            includeTrace: false,
            includeInverse: false,
            includeRowReductionPanels: false
        )

        let coordinator = MatrixMasterFeatureCoordinator(
            analyzeMatrixPropertiesSelection: selection
        )

        await coordinator.runQuickComputation(for: .analyze)

        XCTAssertEqual(coordinator.lastResult?.answer, "Input validation failed")
        XCTAssertTrue(coordinator.inputValidationMessage?.contains("Select at least one Analyze output") == true)
    }

    func testCoordinatorAnalyzeSpanMembershipUsesBasisAndTargetVector() async {
        let basis = BasisDraftInput(vectors: [
            VectorDraftInput(name: "b1", entries: ["1", "0"]),
            VectorDraftInput(name: "b2", entries: ["0", "1"])
        ])
        let target = VectorDraftInput(name: "x", entries: ["3", "4"])
        let coordinator = MatrixMasterFeatureCoordinator(
            vectorDraft: target,
            basisDraft: basis,
            analyzeKind: .spanMembership
        )

        await coordinator.runQuickComputation(for: .analyze)

        XCTAssertTrue(coordinator.lastResult?.answer.contains("in span(B)") == true)
        XCTAssertTrue(coordinator.lastResult?.answer.contains("c1") == true)
        XCTAssertTrue(
            coordinator.lastResult?.reusablePayloads.contains(where: {
                if case let .vector(payload) = $0 {
                    return payload.source == "Analyze span witness coefficients"
                }
                return false
            }) == true
        )
    }

    func testCoordinatorAnalyzeCoordinatesReturnsCoordinateVector() async {
        let basis = BasisDraftInput(vectors: [
            VectorDraftInput(name: "b1", entries: ["1", "0"]),
            VectorDraftInput(name: "b2", entries: ["0", "1"])
        ])
        let target = VectorDraftInput(name: "x", entries: ["5", "-2"])
        let coordinator = MatrixMasterFeatureCoordinator(
            vectorDraft: target,
            basisDraft: basis,
            analyzeKind: .coordinates
        )

        await coordinator.runQuickComputation(for: .analyze)

        XCTAssertTrue(coordinator.lastResult?.answer.contains("[x]_beta") == true)
        XCTAssertTrue(
            coordinator.lastResult?.reusablePayloads.contains(where: {
                if case let .vector(payload) = $0 {
                    return payload.source == "Analyze coordinate vector"
                }
                return false
            }) == true
        )
    }

    func testCoordinatorAnalyzeLinearMapsBasisImagesWorkflowProducesMapDiagnostics() async {
        let domainBasis = BasisDraftInput(vectors: [
            VectorDraftInput(name: "b1", entries: ["1", "0"]),
            VectorDraftInput(name: "b2", entries: ["0", "1"])
        ])
        let codomainBasis = BasisDraftInput(name: "Gamma", vectors: [
            VectorDraftInput(name: "g1", entries: ["1", "0"]),
            VectorDraftInput(name: "g2", entries: ["0", "1"])
        ])
        var imageMatrix = MatrixDraftInput(rows: 2, columns: 2)
        imageMatrix.setValue("1", row: 0, column: 0)
        imageMatrix.setValue("0", row: 0, column: 1)
        imageMatrix.setValue("0", row: 1, column: 0)
        imageMatrix.setValue("0", row: 1, column: 1)

        let coordinator = MatrixMasterFeatureCoordinator(
            secondaryMatrixDraft: imageMatrix,
            basisDraft: domainBasis,
            secondaryBasisDraft: codomainBasis,
            analyzeKind: .linearMaps,
            linearMapDefinitionKind: .basisImages
        )

        await coordinator.runQuickComputation(for: .analyze)

        XCTAssertTrue(coordinator.lastResult?.answer.contains("rank(T) = 1") == true)
        XCTAssertTrue(
            coordinator.lastResult?.reusablePayloads.contains(where: {
                if case let .matrix(payload) = $0 {
                    return payload.source == "Linear maps [T]^beta_gamma"
                }
                return false
            }) == true
        )
    }

    func testCoordinatorSpacesDirectSumWorkflowProducesDecision() async {
        let primary = BasisDraftInput(vectors: [
            VectorDraftInput(name: "u1", entries: ["1", "0"]),
            VectorDraftInput(name: "u2", entries: ["0", "0"])
        ])
        let secondary = BasisDraftInput(vectors: [
            VectorDraftInput(name: "w1", entries: ["0", "1"]),
            VectorDraftInput(name: "w2", entries: ["0", "0"])
        ])
        let coordinator = MatrixMasterFeatureCoordinator(
            basisDraft: primary,
            secondaryBasisDraft: secondary,
            spacesKind: .directSumCheck
        )

        await coordinator.runQuickComputation(for: .spaces)

        XCTAssertTrue(coordinator.lastResult?.answer.contains("direct sum") == true)
        XCTAssertTrue(coordinator.lastResult?.diagnostics.contains(where: { $0.contains("dim(U ∩ W) = 0") }) == true)
    }

    func testCoordinatorAppliesPolynomialPresetToBothSpaceSets() {
        let coordinator = MatrixMasterFeatureCoordinator(
            spacesPresetKind: .polynomialSpace,
            spacesPolynomialDegree: 3
        )

        coordinator.applySpacesPresetToBothSets()

        XCTAssertEqual(coordinator.basisDraft.vectorCount, 4)
        XCTAssertEqual(coordinator.basisDraft.dimension, 4)
        XCTAssertEqual(coordinator.secondaryBasisDraft.vectorCount, 4)
        XCTAssertEqual(coordinator.secondaryBasisDraft.dimension, 4)
        XCTAssertEqual(coordinator.basisDraft.vectors[0].name, "1")
        XCTAssertEqual(coordinator.basisDraft.vectors[1].name, "x")
        XCTAssertEqual(coordinator.basisDraft.vectors[2].name, "x²")
    }

    func testCoordinatorAppliesMatrixSpacePresetToPrimarySet() {
        let coordinator = MatrixMasterFeatureCoordinator(
            spacesPresetKind: .matrixSpace,
            spacesMatrixRowCount: 2,
            spacesMatrixColumnCount: 3
        )

        coordinator.applySpacesPresetToPrimarySet()

        XCTAssertEqual(coordinator.basisDraft.vectorCount, 6)
        XCTAssertEqual(coordinator.basisDraft.dimension, 6)
        XCTAssertEqual(coordinator.basisDraft.vectors[0].name, "E11")
        XCTAssertEqual(coordinator.basisDraft.vectors[5].name, "E23")
        XCTAssertEqual(coordinator.secondaryBasisDraft.vectorCount, 2)
    }

    func testCoordinatorRunsOperateMatrixMultiply() async {
        var matrixA = MatrixDraftInput(rows: 2, columns: 2)
        matrixA.setValue("1", row: 0, column: 0)
        matrixA.setValue("2", row: 0, column: 1)
        matrixA.setValue("3", row: 1, column: 0)
        matrixA.setValue("4", row: 1, column: 1)

        var matrixB = MatrixDraftInput(rows: 2, columns: 2)
        matrixB.setValue("2", row: 0, column: 0)
        matrixB.setValue("0", row: 0, column: 1)
        matrixB.setValue("1", row: 1, column: 0)
        matrixB.setValue("2", row: 1, column: 1)

        let coordinator = MatrixMasterFeatureCoordinator(
            matrixDraft: matrixA,
            secondaryMatrixDraft: matrixB,
            operateKind: .matrixMultiply
        )

        await coordinator.runQuickComputation(for: .operate)

        XCTAssertTrue(coordinator.lastResult?.answer.contains("A * B") == true)
        XCTAssertTrue(coordinator.lastResult?.reusablePayloads.contains(where: {
            if case .matrix = $0 { return true }
            return false
        }) == true)
    }

    func testCoordinatorLibrarySaveLoadAndSummary() async {
        let coordinator = MatrixMasterFeatureCoordinator()
        coordinator.vectorDraft = VectorDraftInput(name: "saved-v", entries: ["5", "-1"])

        await coordinator.saveCurrentVectorDraftToLibrary()
        XCTAssertEqual(coordinator.libraryVectors.count, 1)
        XCTAssertTrue(coordinator.libraryMessage?.contains("Saved") == true)

        guard let stored = coordinator.libraryVectors.first else {
            return XCTFail("Expected stored library vector.")
        }

        coordinator.loadLibraryVectorIntoDraft(stored)
        XCTAssertEqual(coordinator.vectorDraft.name, "saved-v")
        XCTAssertEqual(coordinator.vectorDraft.entries, ["5", "-1"])

        await coordinator.runQuickComputation(for: .library)
        XCTAssertTrue(coordinator.lastResult?.answer.contains("Library vectors: 1") == true)
    }

    func testCoordinatorEnrichesSolveResultWithStructuredObjectsAndRowReductionPanels() async {
        var solveDraft = MatrixDraftInput(rows: 2, columns: 3)
        solveDraft.setValue("1", row: 0, column: 0)
        solveDraft.setValue("1", row: 0, column: 1)
        solveDraft.setValue("2", row: 0, column: 2)
        solveDraft.setValue("2", row: 1, column: 0)
        solveDraft.setValue("-1", row: 1, column: 1)
        solveDraft.setValue("0", row: 1, column: 2)

        let coordinator = MatrixMasterFeatureCoordinator(matrixDraft: solveDraft)
        await coordinator.runQuickComputation(for: .solve)

        XCTAssertNotNil(coordinator.lastResult?.rowReductionPanels)
        XCTAssertTrue((coordinator.lastResult?.structuredObjects.count ?? 0) > 0)
    }

    func testCoordinatorStoresResultsPerDestination() async {
        let coordinator = MatrixMasterFeatureCoordinator()

        await coordinator.runQuickComputation(for: .analyze)
        XCTAssertNotNil(coordinator.result(for: .analyze))
        XCTAssertNil(coordinator.result(for: .operate))

        await coordinator.runQuickComputation(for: .operate)
        XCTAssertNotNil(coordinator.result(for: .analyze))
        XCTAssertNotNil(coordinator.result(for: .operate))
    }
}
