import XCTest
@testable import MatrixDomain

final class MatrixDomainTests: XCTestCase {
    func testDestinationsExposeExpectedOrder() {
        XCTAssertEqual(MatrixMasterDestination.allCases.map(\.rawValue), ["solve", "operate", "analyze", "spaces", "library"])
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

    func testMatrixDraftInitializerFromEntriesPadsRaggedRows() {
        let draft = MatrixDraftInput(entries: [
            ["1", "2"],
            ["3"]
        ])

        XCTAssertEqual(draft.rows, 2)
        XCTAssertEqual(draft.columns, 2)
        XCTAssertEqual(draft.value(atRow: 1, column: 1), "0")
    }

    func testComputationResultCodableRoundTripWithReusePayloads() throws {
        let result = MatrixMasterComputationResult(
            answer: "Unique solution",
            diagnostics: ["Classification: unique solution."],
            steps: ["Sample step."],
            reusablePayloads: [
                .matrix(MatrixReusablePayload(entries: [["1", "0"]], source: "Solve coefficient matrix")),
                .vector(VectorReusablePayload(name: "Solve solution", entries: ["1"], source: "Solve unique solution"))
            ]
        )

        let encoded = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(MatrixMasterComputationResult.self, from: encoded)

        XCTAssertEqual(decoded, result)
    }

    func testComputationRequestCodableRoundTripWithOperateFields() throws {
        let request = MatrixMasterComputationRequest(
            destination: .operate,
            mode: .numeric,
            inputSummary: "Operate test",
            matrixEntries: [["1", "2"], ["3", "4"]],
            secondaryMatrixEntries: [["2", "0"], ["1", "2"]],
            vectorEntries: ["1", "2"],
            secondaryVectorEntries: ["3", "4"],
            scalarToken: "2",
            exponent: 3,
            operateKind: .expression,
            expression: "A*B"
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(MatrixMasterComputationRequest.self, from: encoded)

        XCTAssertEqual(decoded, request)
    }

    func testComputationRequestCodableRoundTripWithAnalyzeFields() throws {
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .exact,
            inputSummary: "Analyze span",
            vectorEntries: ["3", "4"],
            basisVectors: [
                ["1", "0"],
                ["0", "1"]
            ],
            analyzeKind: .spanMembership
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(MatrixMasterComputationRequest.self, from: encoded)

        XCTAssertEqual(decoded, request)
    }

    func testComputationRequestCodableRoundTripWithSpacesFields() throws {
        let request = MatrixMasterComputationRequest(
            destination: .spaces,
            mode: .exact,
            inputSummary: "Spaces direct sum",
            basisVectors: [
                ["1", "0", "0"],
                ["0", "1", "0"]
            ],
            secondaryBasisVectors: [
                ["0", "0", "1"]
            ],
            spacesKind: .directSumCheck
        )

        let encoded = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(MatrixMasterComputationRequest.self, from: encoded)

        XCTAssertEqual(decoded, request)
    }

    func testLibrarySnapshotCodableRoundTrip() throws {
        let snapshot = MatrixLibrarySnapshot(
            vectors: [
                MatrixLibraryVectorItem(name: "v1", entries: ["1", "2"])
            ],
            history: [
                MatrixLibraryHistoryEntry(title: "Saved vector", detail: "v1")
            ],
            updatedAt: Date(timeIntervalSince1970: 500)
        )

        let encoded = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(MatrixLibrarySnapshot.self, from: encoded)
        XCTAssertEqual(decoded, snapshot)
    }
}
