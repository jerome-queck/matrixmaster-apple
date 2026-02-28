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
        let view = AnalyzeConfigurationView(analyzeKind: .constant(.matrixProperties))
        XCTAssertNotNil(view)
    }

    func testSpacesConfigurationViewCanBeConstructed() {
        let view = SpacesConfigurationView(spacesKind: .constant(.basisTestExtract))
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
}
