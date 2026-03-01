import SwiftUI
import XCTest
import MatrixDomain
@testable import MatrixUI

final class MatrixUITests: XCTestCase {
    func testPlaceholderCanBeConstructed() {
        let view = MatrixMasterDestinationPlaceholder(
            destination: .solve,
            mode: .exact,
            lastResult: nil
        )
        XCTAssertNotNil(view)
    }

    func testMatrixEditorCanBeConstructed() {
        let view = MatrixGridEditorView(
            matrix: .constant(MatrixDraftInput(rows: 2, columns: 2)),
            title: "Solve Input",
            showsRandomizeButton: true
        )
        XCTAssertNotNil(view)
    }

    func testAugmentedSystemEditorCanBeConstructed() {
        let view = AugmentedSystemEditorView(
            matrix: .constant(MatrixDraftInput(rows: 2, columns: 3)),
            title: "Solve System Input"
        )
        XCTAssertNotNil(view)
    }

    func testBasisEditorCanBeConstructed() {
        let basis = BasisDraftInput(vectors: [
            VectorDraftInput(name: "v1", entries: ["1", "0"]),
            VectorDraftInput(name: "v2", entries: ["0", "1"])
        ])
        let view = BasisEditorView(basis: .constant(basis))
        XCTAssertNotNil(view)
    }

    func testOperateConfigurationViewCanBeConstructed() {
        let view = OperateConfigurationView(
            operateKind: .constant(.matrixMultiply),
            scalarToken: .constant("2"),
            exponent: .constant(3),
            expression: .constant("A*B")
        )
        XCTAssertNotNil(view)
    }

    func testAnalyzeConfigurationViewCanBeConstructed() {
        let view = AnalyzeConfigurationView(
            analyzeKind: .constant(.matrixProperties),
            linearMapDefinitionKind: .constant(.matrix)
        )
        XCTAssertNotNil(view)
    }

    func testAnalyzeConfigurationLinearMapsModeCanBeConstructed() {
        let view = AnalyzeConfigurationView(
            analyzeKind: .constant(.linearMaps),
            linearMapDefinitionKind: .constant(.basisImages)
        )
        XCTAssertNotNil(view)
    }

    func testSpacesConfigurationViewCanBeConstructed() {
        let view = SpacesConfigurationView(spacesKind: .constant(.basisTestExtract))
        XCTAssertNotNil(view)
    }

    func testSpacesConfigurationViewWithPresetControlsCanBeConstructed() {
        let view = SpacesConfigurationView(
            spacesKind: .constant(.subspaceSum),
            spacesPresetKind: .constant(.matrixSpace),
            polynomialDegree: .constant(2),
            matrixSpaceRows: .constant(2),
            matrixSpaceColumns: .constant(2),
            showsSecondaryApplyActions: true,
            onApplyPrimaryPreset: {},
            onApplySecondaryPreset: {},
            onApplyBothPresets: {}
        )
        XCTAssertNotNil(view)
    }

    func testLibraryCatalogViewCanBeConstructed() {
        let vectors = [
            MatrixLibraryVectorItem(name: "v1", entries: ["1", "2"])
        ]
        let history = [
            MatrixLibraryHistoryEntry(title: "Saved vector", detail: "v1")
        ]
        let view = LibraryCatalogView(
            vectors: vectors,
            history: history,
            exportPath: "/tmp/library.json",
            onSaveDraft: {},
            onLoadVector: { _ in },
            onDeleteVector: { _ in },
            onExportCatalog: {}
        )
        XCTAssertNotNil(view)
    }

    func testResultPresentationViewWithStructuredObjectsCanBeConstructed() {
        let result = MatrixMasterComputationResult(
            answer: "A * v = [1, 2]",
            diagnostics: ["Mode: Exact."],
            steps: ["Computed row dot products."],
            reusablePayloads: [],
            structuredObjects: [
                .matrix(MatrixMathMatrixObject(label: "A", entries: [["1", "0"], ["0", "1"]])),
                .vector(MatrixMathVectorObject(label: "v", entries: ["1", "2"])),
                .polynomial(MatrixMathPolynomialObject(label: "p", coefficients: ["1", "-1", "2"]))
            ],
            rowReductionPanels: MatrixRowReductionPanels(
                sourceLabel: "A",
                refEntries: [["1", "0"], ["0", "1"]],
                rrefEntries: [["1", "0"], ["0", "1"]]
            )
        )

        let view = MatrixResultPresentationView(
            destination: .operate,
            mode: .exact,
            lastResult: result
        )
        XCTAssertNotNil(view)
    }

    func testPolynomialSpaceElementsEditorCanBeConstructed() {
        let basis = BasisDraftInput(vectors: [
            VectorDraftInput(name: "p1", entries: ["1", "0", "2"]),
            VectorDraftInput(name: "p2", entries: ["0", "1", "0"])
        ])
        let view = PolynomialSpaceElementsEditorView(
            basis: .constant(basis),
            polynomialDegree: .constant(2),
            title: "Polynomial Elements"
        )
        XCTAssertNotNil(view)
    }

    func testMatrixSpaceElementsEditorCanBeConstructed() {
        let basis = BasisDraftInput(vectors: [
            VectorDraftInput(name: "M1", entries: ["1", "0", "0", "1"]),
            VectorDraftInput(name: "M2", entries: ["0", "1", "1", "0"])
        ])
        let view = MatrixSpaceElementsEditorView(
            basis: .constant(basis),
            rowCount: .constant(2),
            columnCount: .constant(2),
            title: "Matrix Elements"
        )
        XCTAssertNotNil(view)
    }
}
