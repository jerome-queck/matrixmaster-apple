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
            title: "Solve Input"
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
}
