import XCTest
import MatrixDomain
@testable import MatrixNumeric

final class MatrixNumericTests: XCTestCase {
    func testNumericEngineAcceptsNumericMode() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
            inputSummary: "Sample",
            matrixEntries: [
                ["1", "2"],
                ["3", "4"]
            ]
        )

        let result = try await engine.compute(request)
        XCTAssertTrue(result.answer.contains("Numeric"))
        XCTAssertTrue(result.answer.contains("det(A)"))
        XCTAssertTrue(result.answer.contains("trace(A)"))
        XCTAssertTrue(result.answer.contains("nullity(A) = 0"))
        XCTAssertTrue(result.answer.contains("dim Col(A) = 2"))
        XCTAssertTrue(result.answer.contains("dim Row(A) = 2"))
        XCTAssertTrue(result.answer.contains("dim Null(A) = 0"))
        XCTAssertTrue(result.answer.contains("QR: available"))
        XCTAssertTrue(result.answer.contains("sigma_max(A)"))
        XCTAssertTrue(result.answer.contains("SVD singular values"))
        XCTAssertTrue(result.answer.contains("lambda_max(A)"))
        XCTAssertTrue(result.answer.contains("inverse(A): available"))
        XCTAssertTrue(result.answer.contains("inverse(A) ~="))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Rank-nullity check: 2 + 0 = 2") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Col(A) basis:") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Row(A) basis:") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Null(A) basis: {0}") }))
        XCTAssertTrue(result.steps.contains(where: { $0.contains("column-space basis") }))
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze numeric inverse matrix"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze numeric Q factor"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze numeric R factor"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .vector(vectorPayload) = payload {
                    return vectorPayload.source == "Analyze dominant eigenvector"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .vector(vectorPayload) = payload {
                    return vectorPayload.source == "Analyze SVD singular values"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze numeric column space basis (vectors as columns)"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze numeric row space basis (vectors as columns)"
                }
                return false
            }
        )
        XCTAssertFalse(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze numeric null space basis (vectors as columns)"
                }
                return false
            }
        )
        XCTAssertGreaterThanOrEqual(result.reusablePayloads.count, 5)
    }

    func testNumericAnalyzeParsesFractionAndScientificNotation() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
            inputSummary: "Sample",
            matrixEntries: [
                ["1/2", "1e0"],
                ["2.5", "-3E0"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("Numeric rank(A) = 2"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Tolerance") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Rank-nullity check: 2 + 0 = 2") }))
    }

    func testNumericAnalyzeProducesNullSpaceBasisForDependentRectangularMatrix() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
            inputSummary: "Dependent rectangular",
            matrixEntries: [
                ["1", "2", "3"],
                ["2", "4", "6"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("Numeric rank(A) = 1"))
        XCTAssertTrue(result.answer.contains("nullity(A) = 2"))
        XCTAssertTrue(result.answer.contains("dim Null(A) = 2"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Rank-nullity check: 1 + 2 = 3") }))
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Analyze numeric null space basis (vectors as columns)"
                }
                return false
            }
        )
        if let rowBasisPayload = result.reusablePayloads.first(where: {
            if case let .matrix(payload) = $0 {
                return payload.source == "Analyze numeric row space basis (vectors as columns)"
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
    }

    func testNumericAnalyzeSpanMembershipProducesWitnessCoefficients() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
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
        XCTAssertTrue(result.answer.contains("c1 ~= 3"))
        XCTAssertTrue(result.answer.contains("c2 ~= 4"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .vector(payload) = $0 {
                return payload.source == "Analyze span witness coefficients"
            }
            return false
        }))
    }

    func testNumericAnalyzeIndependenceDetectsDependenceRelation() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
            inputSummary: "Independence",
            basisVectors: [
                ["1", "2"],
                ["2", "4"]
            ],
            analyzeKind: .independence
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("linearly dependent"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .vector(payload) = $0 {
                return payload.source == "Analyze dependence relation"
            }
            return false
        }))
    }

    func testNumericAnalyzeCoordinatesComputesUniqueCoordinateVector() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
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

    func testNumericAnalyzeCoordinatesReportsNonUniqueCoordinateFamily() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
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
        XCTAssertTrue(result.answer.contains("Family: c ~="))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Homogeneous direction basis") }))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Coordinate family:") }))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .vector(payload) = $0 {
                return payload.source.contains("Analyze coordinate nullspace direction")
            }
            return false
        }))
    }

    func testNumericAnalyzeLinearMapsFromMatrixSupportsBasisRepresentationAndSimilarity() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
            inputSummary: "Linear maps matrix definition",
            matrixEntries: [
                ["1", "0"],
                ["0", "2"]
            ],
            basisVectors: [
                ["1", "0"],
                ["0", "1"]
            ],
            secondaryBasisVectors: [
                ["1", "1"],
                ["1", "-1"]
            ],
            analyzeKind: .linearMaps,
            linearMapDefinitionKind: .matrix
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("rank(T) = 2"))
        XCTAssertTrue(result.answer.contains("injective: yes"))
        XCTAssertTrue(result.answer.contains("surjective: yes"))
        XCTAssertTrue(result.answer.contains("similar via basis change: yes"))
        XCTAssertTrue(result.answer.contains("[T]^beta_gamma"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("C_(gamma<-beta)") }))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .matrix(payload) = $0 {
                return payload.source == "Linear maps [T]^beta_gamma"
            }
            return false
        }))
    }

    func testNumericAnalyzeLinearMapsFromBasisImagesComputesKernelAndRange() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
            inputSummary: "Linear maps basis images",
            secondaryMatrixEntries: [
                ["1", "0"],
                ["0", "0"]
            ],
            basisVectors: [
                ["1", "0"],
                ["0", "1"]
            ],
            secondaryBasisVectors: [
                ["1", "0"],
                ["0", "1"]
            ],
            analyzeKind: .linearMaps,
            linearMapDefinitionKind: .basisImages
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("rank(T) = 1"))
        XCTAssertTrue(result.answer.contains("nullity(T) = 1"))
        XCTAssertTrue(result.answer.contains("injective: no"))
        XCTAssertTrue(result.answer.contains("surjective: no"))
        XCTAssertTrue(result.reusablePayloads.contains(where: {
            if case let .matrix(payload) = $0 {
                return payload.source == "Linear maps image matrix Y"
            }
            return false
        }))
    }

    func testNumericAnalyzeLinearMapsReportsSimilarityNotApplicableForNonEndomorphism() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
            inputSummary: "Linear maps non-endomorphism",
            matrixEntries: [
                ["1", "0"],
                ["0", "1"],
                ["1", "1"]
            ],
            basisVectors: [
                ["1", "0"],
                ["0", "1"]
            ],
            secondaryBasisVectors: [
                ["1", "0", "0"],
                ["0", "1", "0"],
                ["0", "0", "1"]
            ],
            analyzeKind: .linearMaps,
            linearMapDefinitionKind: .matrix
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("similarity diagnostics: not applicable"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("not an endomorphism") }))
        XCTAssertTrue(result.steps.contains(where: { $0.contains("Skipped similarity") }))
    }

    func testNumericSpacesBasisExtendPruneBuildsExtendedBasis() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .spaces,
            mode: .numeric,
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

    func testNumericSpacesIntersectionComputesWitnessBasis() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .spaces,
            mode: .numeric,
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

    func testNumericSpacesDirectSumCheckDetectsDirectSum() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .spaces,
            mode: .numeric,
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

    func testNumericOperateSupportsMatrixAndVectorOperations() async throws {
        let engine = StubMatrixNumericEngine()

        let matrixRequest = MatrixMasterComputationRequest(
            destination: .operate,
            mode: .numeric,
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

        let matrixResult = try await engine.compute(matrixRequest)
        XCTAssertTrue(matrixResult.answer.contains("A * B"))

        let vectorRequest = MatrixMasterComputationRequest(
            destination: .operate,
            mode: .numeric,
            inputSummary: "Operate vector add",
            matrixEntries: [
                ["1", "0"],
                ["0", "1"]
            ],
            vectorEntries: ["1", "2"],
            secondaryVectorEntries: ["3", "4"],
            operateKind: .vectorAdd
        )

        let vectorResult = try await engine.compute(vectorRequest)
        XCTAssertTrue(vectorResult.answer.contains("u + v"))
        XCTAssertTrue(
            vectorResult.reusablePayloads.contains { payload in
                if case .vector = payload { return true }
                return false
            }
        )
    }

    func testNumericSolveReturnsUniqueSolutionAndReusePayloads() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .solve,
            mode: .numeric,
            inputSummary: "Numeric solve unique",
            matrixEntries: [
                ["1", "1", "2"],
                ["2", "-1", "0"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("Unique solution"))
        XCTAssertTrue(result.answer.contains("x1 ~= 0.66666667"))
        XCTAssertTrue(result.answer.contains("x2 ~= 1.3333333"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Classification: unique solution") }))
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .matrix(matrixPayload) = payload {
                    return matrixPayload.source == "Solve coefficient matrix"
                }
                return false
            }
        )
        XCTAssertTrue(
            result.reusablePayloads.contains { payload in
                if case let .vector(vectorPayload) = payload {
                    return vectorPayload.source == "Solve unique solution"
                }
                return false
            }
        )
    }

    func testNumericSolveDetectsInconsistentSystem() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .solve,
            mode: .numeric,
            inputSummary: "Numeric solve inconsistent",
            matrixEntries: [
                ["1", "1", "1"],
                ["1", "1", "2"]
            ]
        )

        let result = try await engine.compute(request)

        XCTAssertTrue(result.answer.contains("No solution"))
        XCTAssertTrue(result.diagnostics.contains(where: { $0.contains("Classification: inconsistent") }))
    }

    func testNumericEngineRejectsExactMode() async {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .exact,
            inputSummary: "Sample"
        )

        do {
            _ = try await engine.compute(request)
            XCTFail("Expected nonNumericModeRequest error")
        } catch {
            XCTAssertEqual(error as? MatrixNumericEngineError, .nonNumericModeRequest)
        }
    }
}
