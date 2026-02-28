import XCTest
@testable import MatrixDomain

final class MatrixDomainTests: XCTestCase {
    func testDestinationsExposeExpectedOrder() {
        XCTAssertEqual(MatrixMasterDestination.allCases.map(\.rawValue), ["solve", "operate", "analyze", "library"])
    }

    func testShellSnapshotRoundTrip() throws {
        let snapshot = MatrixMasterShellSnapshot(
            selectedDestination: .analyze,
            selectedMode: .numeric,
            updatedAt: Date(timeIntervalSince1970: 42)
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(MatrixMasterShellSnapshot.self, from: data)
        XCTAssertEqual(decoded, snapshot)
    }

    func testMatrixDraftValidationAcceptsIntegerFractionAndDecimal() throws {
        var draft = MatrixDraftInput(rows: 2, columns: 2)
        draft.setValue("1", row: 0, column: 0)
        draft.setValue("-2/3", row: 0, column: 1)
        draft.setValue("4.5", row: 1, column: 0)
        draft.setValue("0", row: 1, column: 1)

        let validated = try draft.validatedEntries()

        XCTAssertEqual(validated[0][1], "-2/3")
        XCTAssertEqual(validated[1][0], "4.5")
    }

    func testMatrixDraftValidationRejectsZeroDenominator() {
        var draft = MatrixDraftInput(rows: 1, columns: 1)
        draft.setValue("3/0", row: 0, column: 0)

        XCTAssertThrowsError(try draft.validatedEntries()) { error in
            XCTAssertEqual(
                error as? MatrixInputValidationError,
                .zeroDenominatorMatrixEntry(row: 1, column: 1, value: "3/0")
            )
        }
    }

    func testBasisValidationRejectsDimensionMismatch() {
        let basis = BasisDraftInput(vectors: [
            VectorDraftInput(name: "v1", entries: ["1", "0", "0"]),
            VectorDraftInput(name: "v2", entries: ["1", "0"])
        ])

        XCTAssertThrowsError(try basis.validatedVectors()) { error in
            XCTAssertEqual(
                error as? MatrixInputValidationError,
                .inconsistentVectorLength(expected: 3, actual: 2, vectorIndex: 1)
            )
        }
    }

    func testBasisAlignVectorsResizesAllVectors() {
        var basis = BasisDraftInput(vectors: [
            VectorDraftInput(name: "v1", entries: ["1"]),
            VectorDraftInput(name: "v2", entries: ["2"])
        ])

        basis.alignVectors(to: 4)

        XCTAssertEqual(basis.vectors[0].entries.count, 4)
        XCTAssertEqual(basis.vectors[1].entries.count, 4)
    }
}
