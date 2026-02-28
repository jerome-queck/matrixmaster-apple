import XCTest
import MatrixDomain
@testable import MatrixExact

final class MatrixExactTests: XCTestCase {
    func testExactSolveReturnsUniqueSolutionAndReusePayloads() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .solve,
            mode: .exact,
            inputSummary: "Solve unique",
            matrixEntries: [
                ["1", "1", "2"],
                ["2", "-1", "0"]
            ]
        )

        let result = try await engine.compute(request)
        XCTAssertTrue(result.answer.contains("Unique solution"))
        XCTAssertTrue(result.answer.contains("x1 = 2/3"))
        XCTAssertTrue(result.answer.contains("x2 = 4/3"))
        XCTAssertEqual(result.reusablePayloads.count, 2)
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Classification: unique solution") }))
        XCTAssertTrue(result.steps.contains(where: { $0.contains("Every variable has a pivot column") }))
    }

    func testExactSolveDetectsInfiniteSolutions() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .solve,
            mode: .exact,
            inputSummary: "Solve infinite",
            matrixEntries: [
                ["1", "1", "2"],
                ["2", "2", "4"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("Infinitely many solutions"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Free variables: x2") }))
        XCTAssertEqual(result.reusablePayloads.count, 1)
    }

    func testExactSolveDetectsInconsistentSystem() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .solve,
            mode: .exact,
            inputSummary: "Solve inconsistent",
            matrixEntries: [
                ["1", "1", "1"],
                ["1", "1", "2"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("No solution"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Classification: inconsistent") }))
    }

    func testExactSolveSupportsScientificNotationTokens() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .solve,
            mode: .exact,
            inputSummary: "Solve scientific notation",
            matrixEntries: [
                ["1e0", "1", "2"],
                ["2E0", "-1e0", "0e0"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("Unique solution"))
        XCTAssertTrue(result.answer.contains("x1 = 2/3"))
        XCTAssertTrue(result.answer.contains("x2 = 4/3"))
    }

    func testExactAnalyzeComputesDeterminantRankTraceAndInverse() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .exact,
            inputSummary: "Analyze square",
            matrixEntries: [
                ["1", "2"],
                ["3", "4"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("det(A) = -2"))
        XCTAssertTrue(result.answer.contains("rank(A) = 2"))
        XCTAssertTrue(result.answer.contains("nullity(A) = 0"))
        XCTAssertTrue(result.answer.contains("dim Col(A) = 2"))
        XCTAssertTrue(result.answer.contains("dim Row(A) = 2"))
        XCTAssertTrue(result.answer.contains("dim Null(A) = 0"))
        XCTAssertTrue(result.answer.contains("trace(A) = 5"))
        XCTAssertTrue(result.answer.contains("inverse(A): available"))
        XCTAssertTrue(result.answer.contains("inverse(A) = [[-2, 1], [3/2, -1/2]]"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Rank-nullity check: 2 + 0 = 2") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Col(A) basis:") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Row(A) basis:") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Null(A) basis: {0}") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Inverse(A): [[-2, 1], [3/2, -1/2]]") }))
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze inverse matrix"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze column space basis (vectors as columns)"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze row space basis (vectors as columns)"
                }
                return false
            }
        )
        XCTAssertFalse(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze null space basis (vectors as columns)"
                }
                return false
            }
        )
        XCTAssertTrue(result.steps.contains(where: { $0.contains("column-space basis") }))
        XCTAssertTrue(result.steps.contains(where: { $0.contains("Null(A) is the trivial subspace") }))
        XCTAssertGreaterThanOrEqual(result.reusablePayloads.count, 4)
    }

    func testExactAnalyzeHandlesNonSquareMatrix() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .exact,
            inputSummary: "Analyze rectangular",
            matrixEntries: [
                ["1", "2", "3"],
                ["2", "4", "6"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("rank(A) = 1"))
        XCTAssertTrue(result.answer.contains("dim Col(A) = 1"))
        XCTAssertTrue(result.answer.contains("dim Row(A) = 1"))
        XCTAssertTrue(result.answer.contains("dim Null(A) = 2"))
        XCTAssertTrue(result.answer.contains("square matrices only"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Rank-nullity check: 1 + 2 = 3") }))
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze null space basis (vectors as columns)"
                }
                return false
            }
        )
        if let rowBasisPayload = result.reusablePayloads.first(where: {
            if case let .matrix(payload) = $0 {
                return payload.source == "Analyze row space basis (vectors as columns)"
            }
            return false
        }) {
            guard case let .matrix(payload) = rowBasisPayload else {
                return XCTFail("Expected matrix row-basis payload.")
            }
            XCTAssertEqual(payload.entries.count, 3)
            XCTAssertEqual(payload.entries.first?.count, 1)
        } else {
            XCTFail("Expected row-space basis payload.")
        }
        XCTAssertGreaterThanOrEqual(result.reusablePayloads.count, 4)
    }

    func testExactAnalyzeSpanMembershipProducesWitnessCoefficients() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .exact,
            inputSummary: "Span membership",
            vectorEntries: ["3", "4"],
            basisVectors: [
                ["1", "0"],
                ["0", "1"]
            ],
            analyzeKind: .spanMembership
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("in span(B)"))
        XCTAssertTrue(result.answer.contains("c1 = 3"))
        XCTAssertTrue(result.answer.contains("c2 = 4"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .vector(payload) = $0 {
                return payload.source == "Analyze span witness coefficients"
            }
            return false
        }))
    }

    func testExactAnalyzeIndependenceDetectsDependenceRelation() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .exact,
            inputSummary: "Independence",
            basisVectors: [
                ["1", "2"],
                ["2", "4"]
            ],
            analyzeKind: .independence
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("linearly dependent"))
        XCTAssertTrue(result.answer.contains("v1"))
        XCTAssertTrue(result.answer.contains("v2"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .vector(payload) = $0 {
                return payload.source == "Analyze dependence relation"
            }
            return false
        }))
    }

    func testExactAnalyzeCoordinatesComputesUniqueCoordinateVector() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .exact,
            inputSummary: "Coordinates",
            vectorEntries: ["5", "-2"],
            basisVectors: [
                ["1", "0"],
                ["0", "1"]
            ],
            analyzeKind: .coordinates
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("[x]_beta"))
        XCTAssertTrue(result.answer.contains("5"))
        XCTAssertTrue(result.answer.contains("-2"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .vector(payload) = $0 {
                return payload.source == "Analyze coordinate vector"
            }
            return false
        }))
    }

    func testExactAnalyzeCoordinatesReportsNonUniqueCoordinateFamily() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .exact,
            inputSummary: "Coordinates non-unique",
            vectorEntries: ["3", "0"],
            basisVectors: [
                ["1", "0"],
                ["2", "0"]
            ],
            analyzeKind: .coordinates
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("not unique"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Homogeneous direction basis") }))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .vector(payload) = $0 {
                return payload.source == "Analyze coordinate nullspace direction"
            }
            return false
        }))
    }

    func testExactSpacesBasisExtendPruneBuildsExtendedBasis() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .spaces,
            mode: .exact,
            inputSummary: "Spaces extend",
            basisVectors: [
                ["1", "0"],
                ["2", "0"]
            ],
            spacesKind: .basisExtendPrune
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("extended to a basis of R^2"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .matrix(payload) = $0 {
                return payload.source == "Spaces extended basis (vectors as columns)"
            }
            return false
        }))
    }

    func testExactSpacesIntersectionComputesWitnessBasis() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .spaces,
            mode: .exact,
            inputSummary: "Spaces intersection",
            basisVectors: [
                ["1", "0", "0"],
                ["0", "1", "0"]
            ],
            secondaryBasisVectors: [
                ["0", "1", "0"],
                ["0", "0", "1"]
            ],
            spacesKind: .subspaceIntersection
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("Basis(U ∩ W)"))
        XCTAssertTrue(result.answer.contains("[0, 1, 0]"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .matrix(payload) = $0 {
                return payload.source == "Spaces U intersection W basis (vectors as columns)"
            }
            return false
        }))
    }

    func testExactSpacesDirectSumCheckDetectsDirectSum() async throws {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .spaces,
            mode: .exact,
            inputSummary: "Spaces direct sum",
            basisVectors: [
                ["1", "0"],
                ["0", "0"]
            ],
            secondaryBasisVectors: [
                ["0", "1"],
                ["0", "0"]
            ],
            spacesKind: .directSumCheck
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("direct sum"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("dim(U ∩ W) = 0") }))
    }

    func testExactOperateSupportsMatrixAndVectorOperations() async throws {
        let engine = MatrixExactEngine()
        let multiplyRequest = MatrixMasterComputationRequest(
            destination: .operate,
            mode: .exact,
            inputSummary: "Operate multiply",
            matrixEntries: [
                ["1", "2"],
                ["3", "4"]
            ],
            secondaryMatrixEntries: [
                ["2", "0"],
                ["1", "2"]
            ],
            operateKind: .matrixMultiply
        )

        let multiplyResult = try await engine.compute(multiplyRequest)
        XCTAssertTrue(multiplyResult.answer.contains("A * B"))
        XCTAssertTrue(
            multiplyResult.reusablePayloads.contains { payload in
                if case .matrix = payload { return true }
                return false
            }
        )

        let expressionRequest = MatrixMasterComputationRequest(
            destination: .operate,
            mode: .exact,
            inputSummary: "Operate expression",
            matrixEntries: [
                ["1", "0"],
                ["0", "1"]
            ],
            vectorEntries: ["1", "2"],
            operateKind: .expression,
            expression: "2*v"
        )

        let expressionResult = try await engine.compute(expressionRequest)
        XCTAssertTrue(expressionResult.answer.contains("* v"))
        XCTAssertTrue(
            expressionResult.reusablePayloads.contains { payload in
                if case .vector = payload { return true }
                return false
            }
        )
    }

    func testExactEngineRejectsNumericMode() async {
        let engine = MatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .solve,
            mode: .numeric,
            inputSummary: "Sample"
        )

        do {
            _ = try await engine.compute(request)
            XCTFail("Expected nonExactModeRequest error")
        } catch {
            XCTAssertEqual(error as? MatrixExactEngineError, .nonExactModeRequest)
        }
    }
}
