import Foundation
import MatrixDomain

public enum MatrixExactEngineError: Error, Equatable, LocalizedError {
    case nonExactModeRequest
    case missingMatrixInput
    case missingVectorInput
    case solveRequiresAugmentedMatrix
    case analyzeRequiresNonEmptyMatrix
    case analyzeRequiresBasisVectors
    case analyzeRequiresTargetVector
    case analyzeBasisDimensionMismatch(expected: Int, actual: Int, vectorIndex: Int)
    case analyzeTargetDimensionMismatch(expected: Int, actual: Int)
    case linearMapsRequiresSecondaryBasisVectors
    case linearMapsRequiresSecondaryMatrix
    case linearMapsDomainBasisMustBeSquare(vectorCount: Int, dimension: Int)
    case linearMapsCodomainBasisMustBeSquare(vectorCount: Int, dimension: Int)
    case linearMapsDomainBasisSingular
    case linearMapsCodomainBasisSingular
    case linearMapsMapMatrixDimensionMismatch(expectedRows: Int, expectedColumns: Int, actualRows: Int, actualColumns: Int)
    case linearMapsImageMatrixDimensionMismatch(expectedRows: Int, expectedColumns: Int, actualRows: Int, actualColumns: Int)
    case spacesRequiresSecondaryBasisVectors
    case spacesBasisDimensionMismatch(expected: Int, actual: Int)
    case raggedMatrixInput
    case unsupportedToken(row: Int, column: Int, token: String)
    case operateDimensionMismatch
    case operateRequiresSquareMatrix
    case unsupportedOperateExpression(String)

    public var errorDescription: String? {
        switch self {
        case .nonExactModeRequest:
            return "Exact engine requires exact mode."
        case .missingMatrixInput:
            return "This workflow requires matrix entries."
        case .missingVectorInput:
            return "This operation requires vector entries."
        case .solveRequiresAugmentedMatrix:
            return "Solve requires an augmented matrix with at least two columns."
        case .analyzeRequiresNonEmptyMatrix:
            return "Analyze requires at least one matrix row."
        case .analyzeRequiresBasisVectors:
            return "This Analyze workflow requires basis vectors."
        case .analyzeRequiresTargetVector:
            return "This Analyze workflow requires a target vector."
        case let .analyzeBasisDimensionMismatch(expected, actual, vectorIndex):
            return "Basis vector \(vectorIndex + 1) has dimension \(actual), expected \(expected)."
        case let .analyzeTargetDimensionMismatch(expected, actual):
            return "Target vector has dimension \(actual), expected \(expected)."
        case .linearMapsRequiresSecondaryBasisVectors:
            return "Linear maps workflow requires a secondary basis."
        case .linearMapsRequiresSecondaryMatrix:
            return "Linear maps workflow requires an image matrix when defining by basis images."
        case let .linearMapsDomainBasisMustBeSquare(vectorCount, dimension):
            return "Domain basis must be square: received \(vectorCount) vectors in R^\(dimension)."
        case let .linearMapsCodomainBasisMustBeSquare(vectorCount, dimension):
            return "Codomain basis must be square: received \(vectorCount) vectors in R^\(dimension)."
        case .linearMapsDomainBasisSingular:
            return "Domain basis vectors are dependent; domain basis matrix is not invertible."
        case .linearMapsCodomainBasisSingular:
            return "Codomain basis vectors are dependent; codomain basis matrix is not invertible."
        case let .linearMapsMapMatrixDimensionMismatch(expectedRows, expectedColumns, actualRows, actualColumns):
            return "Map matrix dimensions are \(actualRows)x\(actualColumns), expected \(expectedRows)x\(expectedColumns)."
        case let .linearMapsImageMatrixDimensionMismatch(expectedRows, expectedColumns, actualRows, actualColumns):
            return "Image matrix dimensions are \(actualRows)x\(actualColumns), expected \(expectedRows)x\(expectedColumns)."
        case .spacesRequiresSecondaryBasisVectors:
            return "This Spaces workflow requires a secondary generating set."
        case let .spacesBasisDimensionMismatch(expected, actual):
            return "Secondary generating set has dimension \(actual), expected \(expected)."
        case .raggedMatrixInput:
            return "Matrix rows must all have the same length."
        case let .unsupportedToken(row, column, token):
            return "Entry (\(row), \(column)) is unsupported in exact mode: \(token)."
        case .operateDimensionMismatch:
            return "Operate input dimensions are incompatible for the selected operation."
        case .operateRequiresSquareMatrix:
            return "This operation requires a square matrix."
        case let .unsupportedOperateExpression(expression):
            return "Unsupported operate expression: \(expression)."
        }
    }
}

public protocol MatrixExactComputing: Sendable {
    func compute(_ request: MatrixMasterComputationRequest) async throws -> MatrixMasterComputationResult
}

public struct MatrixExactEngine: MatrixExactComputing {
    public init() {}

    public func compute(_ request: MatrixMasterComputationRequest) async throws -> MatrixMasterComputationResult {
        guard request.mode == .exact else {
            throw MatrixExactEngineError.nonExactModeRequest
        }

        switch request.destination {
        case .solve:
            return try solveExactSystem(request)
        case .analyze:
            return try analyzeExactMatrix(request)
        case .spaces:
            return try analyzeExactSpaces(request)
        case .operate:
            return try operateExactData(request)
        case .library:
            return MatrixMasterComputationResult(
                answer: "Library workflows are handled by the feature coordinator.",
                diagnostics: [
                    "Exact library engine path remains pass-through."
                ],
                steps: []
            )
        }
    }

    private func solveExactSystem(_ request: MatrixMasterComputationRequest) throws -> MatrixMasterComputationResult {
        let rawEntries = try rawMatrixEntries(from: request)

        guard let firstRow = rawEntries.first, firstRow.count >= 2 else {
            throw MatrixExactEngineError.solveRequiresAugmentedMatrix
        }

        guard rawEntries.allSatisfy({ $0.count == firstRow.count }) else {
            throw MatrixExactEngineError.raggedMatrixInput
        }

        let parsedMatrix = try parse(entries: rawEntries)
        let variableCount = firstRow.count - 1
        let coefficientEntries = parsedMatrix.map { row in
            Array(row.prefix(variableCount)).map(\.token)
        }

        var work = parsedMatrix
        var pivotColumns: [Int] = []
        var operationSteps: [String] = [
            "Interpreted input as an augmented matrix with \(work.count) equations and \(variableCount) unknowns."
        ]

        var pivotRow = 0

        for column in 0..<variableCount {
            guard pivotRow < work.count else {
                break
            }

            guard let rowWithPivot = (pivotRow..<work.count).first(where: { !work[$0][column].isZero }) else {
                continue
            }

            if rowWithPivot != pivotRow {
                work.swapAt(rowWithPivot, pivotRow)
                operationSteps.append("R\(pivotRow + 1) <-> R\(rowWithPivot + 1)")
            }

            let pivotValue = work[pivotRow][column]
            if !pivotValue.isOne {
                let reciprocal = Rational(pivotValue.denominator, pivotValue.numerator)
                scaleRow(&work[pivotRow], by: reciprocal)
                operationSteps.append("R\(pivotRow + 1) = (\(reciprocal.token)) * R\(pivotRow + 1)")
            }

            for row in 0..<work.count where row != pivotRow {
                let factor = work[row][column]
                guard !factor.isZero else {
                    continue
                }

                addScaledRow(source: work[pivotRow], scale: -factor, destination: &work[row])
                operationSteps.append("R\(row + 1) = R\(row + 1) + (\((-factor).token)) * R\(pivotRow + 1)")
            }

            pivotColumns.append(column)
            pivotRow += 1
        }

        let classification = classify(matrix: work, variableCount: variableCount, pivotColumns: pivotColumns)

        let diagnostics = buildDiagnostics(
            classification: classification,
            pivotColumns: pivotColumns,
            variableCount: variableCount
        )
        operationSteps.append(classification.summaryStep)

        let answer: String
        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: coefficientEntries,
                    source: "Solve coefficient matrix"
                )
            )
        ]

        switch classification {
        case let .unique(solution):
            answer = "Unique solution: \(formattedSolution(solution))"
            payloads.append(
                .vector(
                    VectorReusablePayload(
                        name: "Solve solution",
                        entries: solution.map(\.token),
                        source: "Solve unique solution"
                    )
                )
            )
        case let .infinite(freeVariables):
            let freeDescription = freeVariables.map { "x\($0 + 1)" }.joined(separator: ", ")
            answer = "Infinitely many solutions (free variables: \(freeDescription))."
        case .inconsistent:
            answer = "No solution (system is inconsistent)."
        }

        return MatrixMasterComputationResult(
            answer: answer,
            diagnostics: diagnostics,
            steps: operationSteps,
            reusablePayloads: payloads
        )
    }

    private func analyzeExactMatrix(_ request: MatrixMasterComputationRequest) throws -> MatrixMasterComputationResult {
        let analyzeKind = request.analyzeKind ?? .matrixProperties
        switch analyzeKind {
        case .matrixProperties:
            break
        case .spanMembership:
            return try analyzeExactSpanMembership(request)
        case .independence:
            return try analyzeExactIndependence(request)
        case .coordinates:
            return try analyzeExactCoordinates(request)
        case .linearMaps:
            return try analyzeExactLinearMaps(request)
        }

        let rawEntries = try rawMatrixEntries(from: request)
        guard !rawEntries.isEmpty else {
            throw MatrixExactEngineError.analyzeRequiresNonEmptyMatrix
        }
        let parsedMatrix = try parse(entries: rawEntries)
        let rows = parsedMatrix.count
        let columns = parsedMatrix.first?.count ?? 0

        let rankSummary = rrefSummary(for: parsedMatrix)
        let nullity = max(0, columns - rankSummary.rank)
        let columnBasisVectors = columnSpaceBasis(from: parsedMatrix, pivotColumns: rankSummary.pivotColumns)
        let rowBasisVectors = rowSpaceBasis(from: rankSummary.reduced)
        let nullBasisVectors = nullSpaceBasis(
            from: rankSummary.reduced,
            pivotColumns: rankSummary.pivotColumns,
            columnCount: columns
        )
        var diagnostics: [String] = [
            "Mode: Exact (rational arithmetic).",
            "Dimensions: \(rows)x\(columns).",
            "Rank(A): \(rankSummary.rank).",
            "Nullity(A): \(nullity).",
            "Rank-nullity check: \(rankSummary.rank) + \(nullity) = \(columns).",
            "Col(A) basis: \(inlineBasis(columnBasisVectors)).",
            "Row(A) basis: \(inlineBasis(rowBasisVectors)).",
            "Null(A) basis: \(inlineBasis(nullBasisVectors))."
        ]

        var steps: [String] = [
            "Computed rank using exact RREF with pivot columns: \(pivotDescription(rankSummary.pivotColumns)).",
            "Used pivot columns from the original matrix to witness a column-space basis.",
            "Used nonzero rows of RREF to witness a row-space basis."
        ]

        var answerSegments: [String] = [
            "rank(A) = \(rankSummary.rank)",
            "nullity(A) = \(nullity)",
            "dim Col(A) = \(columnBasisVectors.count)",
            "dim Row(A) = \(rowBasisVectors.count)",
            "dim Null(A) = \(nullBasisVectors.count)"
        ]
        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(rankSummary.reduced),
                    source: "Analyze RREF matrix"
                )
            )
        ]

        if !columnBasisVectors.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(columnBasisVectors, rowCount: rows)),
                        source: "Analyze column space basis (vectors as columns)"
                    )
                )
            )
        }

        if !rowBasisVectors.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(rowBasisVectors, rowCount: columns)),
                        source: "Analyze row space basis (vectors as columns)"
                    )
                )
            )
        }

        if !nullBasisVectors.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(nullBasisVectors, rowCount: columns)),
                        source: "Analyze null space basis (vectors as columns)"
                    )
                )
            )
            steps.append("Set each free variable to 1 (others 0) to construct null-space basis vectors.")
        } else {
            steps.append("No free variables remain, so Null(A) is the trivial subspace {0}.")
        }

        if rows == columns {
            let traceValue = trace(of: parsedMatrix)
            let determinantSummary = determinant(of: parsedMatrix)
            let inverseSummary = inverse(of: parsedMatrix)

            answerSegments.insert("det(A) = \(determinantSummary.value.token)", at: 0)
            answerSegments.append("trace(A) = \(traceValue.token)")

            diagnostics.append("Trace(A): \(traceValue.token).")
            diagnostics.append("Determinant: \(determinantSummary.value.token).")
            diagnostics.append(
                inverseSummary.inverse == nil
                ? "Inverse: matrix is singular."
                : "Inverse: matrix is invertible."
            )

            steps.append(contentsOf: determinantSummary.steps.prefix(3))
            steps.append(contentsOf: inverseSummary.steps.prefix(3))

            if let inverseMatrix = inverseSummary.inverse {
                let inverseInline = inlineMatrix(inverseMatrix)
                answerSegments.append("inverse(A): available")
                answerSegments.append("inverse(A) = \(inverseInline)")
                diagnostics.append("Inverse(A): \(inverseInline).")
                payloads.append(
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(inverseMatrix),
                            source: "Analyze inverse matrix"
                        )
                    )
                )
            } else {
                answerSegments.append("inverse(A): not available (singular)")
            }
        } else {
            diagnostics.append("Trace, determinant, and inverse require a square matrix.")
            answerSegments.append("trace(A), det(A), inverse(A): square matrices only")
        }

        return MatrixMasterComputationResult(
            answer: answerSegments.joined(separator: " | "),
            diagnostics: diagnostics,
            steps: steps,
            reusablePayloads: payloads
        )
    }

    private func analyzeExactSpanMembership(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let basisVectors = try parseBasisVectors(from: request)
        let dimension = basisVectors[0].count
        let targetVector = try parseAnalyzeTargetVector(from: request, expectedDimension: dimension)
        let coefficientMatrix = matrixFromColumnVectors(basisVectors, rowCount: dimension)
        let solveSummary = solveExactBasisSystem(
            basisVectors: basisVectors,
            targetVector: targetVector
        )

        var diagnostics: [String] = [
            "Mode: Exact (rational arithmetic).",
            "Analyze workflow: span membership.",
            "Basis vectors: \(basisVectors.count).",
            "Vector dimension: \(dimension).",
            "Pivot columns in basis matrix: \(pivotDescription(solveSummary.basisPivotColumns))."
        ]
        var steps: [String] = [
            "Built the coefficient matrix using basis vectors as columns.",
            "Solved B * c = x with exact RREF."
        ]
        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(coefficientMatrix),
                    source: "Analyze span basis matrix (vectors as columns)"
                )
            )
        ]

        let answer: String
        switch solveSummary.classification {
        case .inconsistent:
            answer = "Target vector is not in span(B)."
            diagnostics.append("Classification: inconsistent system, so x is not in span(B).")
            steps.append("A contradictory row appeared in the augmented system.")
        case let .unique(solution):
            answer = "Target vector is in span(B). Witness: \(formattedCoefficients(solution))."
            diagnostics.append("Classification: unique coefficient witness.")
            payloads.append(
                .vector(
                    VectorReusablePayload(
                        name: "Span membership coefficients",
                        entries: solution.map(\.token),
                        source: "Analyze span witness coefficients"
                    )
                )
            )
        case let .infinite(freeVariables):
            let witness = particularSolution(
                from: solveSummary.reducedAugmented,
                variableCount: basisVectors.count,
                pivotColumns: solveSummary.basisPivotColumns
            )
            let freeDescription = freeVariables.map { "c\($0 + 1)" }.joined(separator: ", ")
            answer = "Target vector is in span(B). One witness (free vars set to 0): \(formattedCoefficients(witness))."
            diagnostics.append("Classification: infinitely many coefficient witnesses.")
            diagnostics.append("Free variables: \(freeDescription).")
            payloads.append(
                .vector(
                    VectorReusablePayload(
                        name: "Span membership witness",
                        entries: witness.map(\.token),
                        source: "Analyze span witness coefficients"
                    )
                )
            )
        }

        return MatrixMasterComputationResult(
            answer: answer,
            diagnostics: diagnostics,
            steps: steps,
            reusablePayloads: payloads
        )
    }

    private func analyzeExactIndependence(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let basisVectors = try parseBasisVectors(from: request)
        let dimension = basisVectors[0].count
        let coefficientMatrix = matrixFromColumnVectors(basisVectors, rowCount: dimension)
        let rankSummary = rrefSummary(for: coefficientMatrix)
        let rank = rankSummary.rank
        let vectorCount = basisVectors.count
        let isIndependent = rank == vectorCount
        let nullBasis = nullSpaceBasis(
            from: rankSummary.reduced,
            pivotColumns: rankSummary.pivotColumns,
            columnCount: vectorCount
        )
        let extractedBasisVectors = rankSummary.pivotColumns.map { basisVectors[$0] }

        var diagnostics: [String] = [
            "Mode: Exact (rational arithmetic).",
            "Analyze workflow: independence/dependence.",
            "Vector count: \(vectorCount).",
            "Vector dimension: \(dimension).",
            "Rank(B): \(rank)."
        ]
        let steps: [String] = [
            "Built matrix B with vectors as columns.",
            "Computed exact RREF and pivot columns: \(pivotDescription(rankSummary.pivotColumns))."
        ]

        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(coefficientMatrix),
                    source: "Analyze independence matrix (vectors as columns)"
                )
            )
        ]

        if !extractedBasisVectors.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(extractedBasisVectors, rowCount: dimension)),
                        source: "Analyze extracted basis (vectors as columns)"
                    )
                )
            )
        }

        let answer: String
        if isIndependent {
            answer = "Vectors are linearly independent."
            diagnostics.append("Classification: independent (rank equals vector count).")
        } else {
            let relationCoefficients = nullBasis.first ?? Array(repeating: .zero, count: vectorCount)
            answer = "Vectors are linearly dependent. Witness: \(formattedDependenceRelation(relationCoefficients))."
            diagnostics.append("Classification: dependent (rank is less than vector count).")
            if !nullBasis.isEmpty {
                payloads.append(
                    .vector(
                        VectorReusablePayload(
                            name: "Dependence coefficients",
                            entries: relationCoefficients.map(\.token),
                            source: "Analyze dependence relation"
                        )
                    )
                )
            }
        }

        return MatrixMasterComputationResult(
            answer: answer,
            diagnostics: diagnostics,
            steps: steps,
            reusablePayloads: payloads
        )
    }

    private func analyzeExactCoordinates(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let basisVectors = try parseBasisVectors(from: request)
        let dimension = basisVectors[0].count
        let targetVector = try parseAnalyzeTargetVector(from: request, expectedDimension: dimension)
        let coefficientMatrix = matrixFromColumnVectors(basisVectors, rowCount: dimension)
        let rankSummary = rrefSummary(for: coefficientMatrix)
        let vectorCount = basisVectors.count
        let basisIsIndependent = rankSummary.rank == vectorCount
        let nullBasis = nullSpaceBasis(
            from: rankSummary.reduced,
            pivotColumns: rankSummary.pivotColumns,
            columnCount: vectorCount
        )

        var diagnostics: [String] = [
            "Mode: Exact (rational arithmetic).",
            "Analyze workflow: coordinate vector.",
            "Basis vectors: \(vectorCount).",
            "Vector dimension: \(dimension).",
            "Rank(B): \(rankSummary.rank)."
        ]
        let steps: [String] = [
            "Built basis matrix B with basis vectors as columns."
        ]
        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(coefficientMatrix),
                    source: "Analyze coordinate basis matrix (vectors as columns)"
                )
            )
        ]

        if !basisIsIndependent {
            diagnostics.append("Basis check: dependent vectors, so coordinates are not unique when they exist.")
        }

        let solveSummary = solveExactBasisSystem(
            basisVectors: basisVectors,
            targetVector: targetVector
        )

        switch solveSummary.classification {
        case .inconsistent:
            diagnostics.append("Target vector is outside span(B).")
            return MatrixMasterComputationResult(
                answer: "Coordinate vector is unavailable because x is not in span(B).",
                diagnostics: diagnostics,
                steps: steps + ["Solved B * c = x and found an inconsistent augmented system."],
                reusablePayloads: payloads
            )
        case let .unique(solution):
            diagnostics.append("Unique coordinates exist because B is independent and x is in span(B).")
            payloads.append(
                .vector(
                    VectorReusablePayload(
                        name: "Coordinate vector [x]_beta",
                        entries: solution.map(\.token),
                        source: "Analyze coordinate vector"
                    )
                )
            )

            return MatrixMasterComputationResult(
                answer: "[x]_beta = [\(solution.map(\.token).joined(separator: ", "))]",
                diagnostics: diagnostics,
                steps: steps + ["Solved B * c = x exactly to obtain coordinate coefficients."],
                reusablePayloads: payloads
            )
        case .infinite:
            let witness = particularSolution(
                from: solveSummary.reducedAugmented,
                variableCount: basisVectors.count,
                pivotColumns: solveSummary.basisPivotColumns
            )
            diagnostics.append("Multiple coordinate candidates detected.")
            if !nullBasis.isEmpty {
                diagnostics.append("Homogeneous direction basis: \(inlineBasis(nullBasis)).")
                diagnostics.append("Coordinate family: \(coordinateFamilyExpression(witness: witness, directions: nullBasis)).")
            }
            payloads.append(
                .vector(
                    VectorReusablePayload(
                        name: "Coordinate witness",
                        entries: witness.map(\.token),
                        source: "Analyze coordinate witness"
                    )
                )
            )
            for (directionIndex, relation) in nullBasis.enumerated() {
                payloads.append(
                    .vector(
                        VectorReusablePayload(
                            name: "Coordinate nullspace direction \(directionIndex + 1)",
                            entries: relation.map(\.token),
                            source: "Analyze coordinate nullspace direction \(directionIndex + 1)"
                        )
                    )
                )
            }
            return MatrixMasterComputationResult(
                answer: "Coordinate vector is not unique. One witness: \(formattedCoefficients(witness)). Family: \(coordinateFamilyExpression(witness: witness, directions: nullBasis)).",
                diagnostics: diagnostics,
                steps: steps + [
                    "Solved B * c = x and found free variables.",
                    "Built a full family parameterization from a witness plus every basis direction in Null(B)."
                ],
                reusablePayloads: payloads
            )
        }
    }

    private func analyzeExactLinearMaps(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let definitionKind = request.linearMapDefinitionKind ?? .matrix
        let domainBasis = try parseBasisVectors(from: request)
        let codomainBasis = try parseLinearMapSecondaryBasisVectors(from: request)
        let domainDimension = domainBasis[0].count
        let codomainDimension = codomainBasis[0].count

        guard domainBasis.count == domainDimension else {
            throw MatrixExactEngineError.linearMapsDomainBasisMustBeSquare(
                vectorCount: domainBasis.count,
                dimension: domainDimension
            )
        }
        guard codomainBasis.count == codomainDimension else {
            throw MatrixExactEngineError.linearMapsCodomainBasisMustBeSquare(
                vectorCount: codomainBasis.count,
                dimension: codomainDimension
            )
        }

        let domainBasisMatrix = matrixFromColumnVectors(domainBasis, rowCount: domainDimension)
        let codomainBasisMatrix = matrixFromColumnVectors(codomainBasis, rowCount: codomainDimension)

        let domainInverseSummary = inverse(of: domainBasisMatrix)
        guard let domainBasisInverse = domainInverseSummary.inverse else {
            throw MatrixExactEngineError.linearMapsDomainBasisSingular
        }

        let codomainInverseSummary = inverse(of: codomainBasisMatrix)
        guard let codomainBasisInverse = codomainInverseSummary.inverse else {
            throw MatrixExactEngineError.linearMapsCodomainBasisSingular
        }

        var steps: [String] = [
            "Interpreted domain basis β and codomain basis γ as ordered bases."
        ]
        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(domainBasisMatrix),
                    source: "Linear maps domain basis matrix B"
                )
            ),
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(codomainBasisMatrix),
                    source: "Linear maps codomain basis matrix G"
                )
            )
        ]

        let standardMatrix: [[Rational]]
        switch definitionKind {
        case .matrix:
            let parsedMatrix = try parse(entries: try rawMatrixEntries(from: request))
            let actualRows = parsedMatrix.count
            let actualColumns = parsedMatrix.first?.count ?? 0
            guard actualRows == codomainDimension && actualColumns == domainDimension else {
                throw MatrixExactEngineError.linearMapsMapMatrixDimensionMismatch(
                    expectedRows: codomainDimension,
                    expectedColumns: domainDimension,
                    actualRows: actualRows,
                    actualColumns: actualColumns
                )
            }
            standardMatrix = parsedMatrix
            steps.append("Accepted the provided matrix A as the standard-coordinate representation of T.")
        case .basisImages:
            let imageMatrix = try parse(entries: try rawSecondaryMatrixEntries(from: request))
            let actualRows = imageMatrix.count
            let actualColumns = imageMatrix.first?.count ?? 0
            guard actualRows == codomainDimension && actualColumns == domainDimension else {
                throw MatrixExactEngineError.linearMapsImageMatrixDimensionMismatch(
                    expectedRows: codomainDimension,
                    expectedColumns: domainDimension,
                    actualRows: actualRows,
                    actualColumns: actualColumns
                )
            }
            standardMatrix = multiply(imageMatrix, domainBasisInverse)
            steps.append("Interpreted columns of Y as T(b_i) in standard codomain coordinates.")
            steps.append("Computed A = Y * B^-1 to recover the standard-coordinate map matrix.")
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(imageMatrix),
                        source: "Linear maps image matrix Y"
                    )
                )
            )
        }

        let rankSummary = rrefSummary(for: standardMatrix)
        let rank = rankSummary.rank
        let nullity = max(0, domainDimension - rank)
        let kernelBasis = nullSpaceBasis(
            from: rankSummary.reduced,
            pivotColumns: rankSummary.pivotColumns,
            columnCount: domainDimension
        )
        let rangeBasis = columnSpaceBasis(from: standardMatrix, pivotColumns: rankSummary.pivotColumns)
        let injective = rank == domainDimension
        let surjective = rank == codomainDimension
        let bijective = injective && surjective && domainDimension == codomainDimension
        let mapBetaGamma = multiply(codomainBasisInverse, multiply(standardMatrix, domainBasisMatrix))

        payloads.append(
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(standardMatrix),
                    source: "Linear maps standard matrix A"
                )
            )
        )
        payloads.append(
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(mapBetaGamma),
                    source: "Linear maps [T]^beta_gamma"
                )
            )
        )
        if !kernelBasis.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(kernelBasis, rowCount: domainDimension)),
                        source: "Linear maps kernel basis (vectors as columns)"
                    )
                )
            )
        }
        if !rangeBasis.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(rangeBasis, rowCount: codomainDimension)),
                        source: "Linear maps range basis (vectors as columns)"
                    )
                )
            )
        }

        var diagnostics: [String] = [
            "Mode: Exact (rational arithmetic).",
            "Analyze workflow: linear maps.",
            "Definition: \(definitionKind.title).",
            "Domain dimension: \(domainDimension).",
            "Codomain dimension: \(codomainDimension).",
            "rank(T): \(rank).",
            "nullity(T): \(nullity).",
            "Kernel basis: \(inlineBasis(kernelBasis)).",
            "Range basis: \(inlineBasis(rangeBasis)).",
            "Injective: \(injective ? "yes" : "no").",
            "Surjective: \(surjective ? "yes" : "no").",
            "Bijective: \(bijective ? "yes" : "no").",
            "[T]^beta_gamma: \(inlineMatrix(mapBetaGamma))."
        ]

        steps.append("Computed kernel and range using exact RREF pivot analysis on A.")
        steps.append("Computed basis-relative representation [T]^beta_gamma = G^-1 * A * B.")

        var answerParts: [String] = [
            "T: R^\(domainDimension) -> R^\(codomainDimension)",
            "rank(T) = \(rank)",
            "nullity(T) = \(nullity)",
            "kernel dim = \(kernelBasis.count)",
            "range dim = \(rangeBasis.count)",
            "injective: \(injective ? "yes" : "no")",
            "surjective: \(surjective ? "yes" : "no")",
            "bijective: \(bijective ? "yes" : "no")",
            "[T]^beta_gamma = \(inlineMatrix(mapBetaGamma))"
        ]

        if domainDimension == codomainDimension {
            let betaToGamma = multiply(codomainBasisInverse, domainBasisMatrix)
            let gammaToBeta = multiply(domainBasisInverse, codomainBasisMatrix)
            let mapBeta = multiply(domainBasisInverse, multiply(standardMatrix, domainBasisMatrix))
            let mapGamma = multiply(codomainBasisInverse, multiply(standardMatrix, codomainBasisMatrix))
            let reconstructedGamma = multiply(betaToGamma, multiply(mapBeta, gammaToBeta))
            let similar = reconstructedGamma == mapGamma
            let traceBeta = trace(of: mapBeta)
            let traceGamma = trace(of: mapGamma)
            let determinantBeta = determinant(of: mapBeta).value
            let determinantGamma = determinant(of: mapGamma).value

            answerParts.append("similar via basis change: \(similar ? "yes" : "no")")
            diagnostics.append("C_(gamma<-beta): \(inlineMatrix(betaToGamma)).")
            diagnostics.append("C_(beta<-gamma): \(inlineMatrix(gammaToBeta)).")
            if !similar {
                diagnostics.append("Similarity comparison failed despite equal dimensions; verify that β and γ describe the same ambient space ordering.")
            }
            diagnostics.append("trace([T]_beta) = \(traceBeta.token), trace([T]_gamma) = \(traceGamma.token).")
            diagnostics.append("det([T]_beta) = \(determinantBeta.token), det([T]_gamma) = \(determinantGamma.token).")

            steps.append("Computed coordinate-change matrices C_(gamma<-beta) and C_(beta<-gamma).")
            steps.append("Verified [T]_gamma = C_(gamma<-beta) * [T]_beta * C_(beta<-gamma).")

            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(betaToGamma),
                        source: "Linear maps C_(gamma<-beta)"
                    )
                )
            )
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(gammaToBeta),
                        source: "Linear maps C_(beta<-gamma)"
                    )
                )
            )
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(mapBeta),
                        source: "Linear maps [T]_beta"
                    )
                )
            )
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(mapGamma),
                        source: "Linear maps [T]_gamma"
                    )
                )
            )
        } else {
            answerParts.append("similarity diagnostics: not applicable")
            diagnostics.append("Similarity skipped: T is not an endomorphism because domain and codomain dimensions differ.")
            diagnostics.append("Received T: R^\(domainDimension) -> R^\(codomainDimension). Similarity requires T: V -> V.")
            diagnostics.append("Provide two ordered bases of the same n-dimensional ambient space to enable C_(gamma<-beta) and [T]_beta/[T]_gamma comparison.")
            steps.append("Skipped similarity and basis-change comparison because this map is not an endomorphism.")
        }

        return MatrixMasterComputationResult(
            answer: answerParts.joined(separator: " | "),
            diagnostics: diagnostics,
            steps: steps,
            reusablePayloads: payloads
        )
    }

    private func analyzeExactSpaces(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let spacesKind = request.spacesKind ?? .basisTestExtract

        switch spacesKind {
        case .basisTestExtract:
            return try exactSpacesBasisTestExtract(request)
        case .basisExtendPrune:
            return try exactSpacesBasisExtendPrune(request)
        case .subspaceSum:
            return try exactSpacesSubspaceSum(request)
        case .subspaceIntersection:
            return try exactSpacesSubspaceIntersection(request)
        case .directSumCheck:
            return try exactSpacesDirectSumCheck(request)
        }
    }

    private func exactSpacesBasisTestExtract(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let generatingVectors = try parseBasisVectors(from: request)
        let dimension = generatingVectors[0].count
        let generatingMatrix = matrixFromColumnVectors(generatingVectors, rowCount: dimension)
        let rankSummary = rrefSummary(for: generatingMatrix)
        let extractedBasis = rankSummary.pivotColumns.map { generatingVectors[$0] }
        let isIndependent = rankSummary.rank == generatingVectors.count
        let spansAmbient = rankSummary.rank == dimension
        let isBasis = isIndependent && spansAmbient

        let answer: String
        if isBasis {
            answer = "U is a basis for R^\(dimension)."
        } else {
            answer = "U is not a basis for R^\(dimension). Extracted basis has \(extractedBasis.count) vectors."
        }

        var diagnostics: [String] = [
            "Mode: Exact (rational arithmetic).",
            "Spaces workflow: basis test / extract.",
            "Input vectors: \(generatingVectors.count).",
            "Ambient dimension: \(dimension).",
            "Rank(U): \(rankSummary.rank).",
            "Independent: \(isIndependent ? "yes" : "no").",
            "Spans R^\(dimension): \(spansAmbient ? "yes" : "no").",
            "Extracted basis: \(inlineBasis(extractedBasis))."
        ]
        if !isBasis {
            diagnostics.append("Basis test failed because \(isIndependent ? "span is insufficient" : "vectors are dependent").")
        }

        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(generatingMatrix),
                    source: "Spaces generating set U (vectors as columns)"
                )
            )
        ]
        if !extractedBasis.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(extractedBasis, rowCount: dimension)),
                        source: "Spaces extracted basis (vectors as columns)"
                    )
                )
            )
        }

        return MatrixMasterComputationResult(
            answer: answer,
            diagnostics: diagnostics,
            steps: [
                "Constructed U as a matrix with vectors as columns.",
                "Computed exact RREF to identify pivot columns: \(pivotDescription(rankSummary.pivotColumns)).",
                "Kept pivot columns as an extracted basis."
            ],
            reusablePayloads: payloads
        )
    }

    private func exactSpacesBasisExtendPrune(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let generatingVectors = try parseBasisVectors(from: request)
        let dimension = generatingVectors[0].count
        let generatingMatrix = matrixFromColumnVectors(generatingVectors, rowCount: dimension)
        let rankSummary = rrefSummary(for: generatingMatrix)

        var extractedBasis = rankSummary.pivotColumns.map { generatingVectors[$0] }
        let prunedCount = max(0, generatingVectors.count - extractedBasis.count)
        var addedVectors: [[Rational]] = []
        var steps: [String] = [
            "Built U with vectors as columns and reduced to RREF.",
            "Pruned dependent vectors by retaining pivot columns: \(pivotDescription(rankSummary.pivotColumns))."
        ]

        if extractedBasis.count < dimension {
            for basisIndex in 0..<dimension where extractedBasis.count < dimension {
                let candidate = standardBasisVector(index: basisIndex, dimension: dimension)
                let trialVectors = extractedBasis + [candidate]
                let trialMatrix = matrixFromColumnVectors(trialVectors, rowCount: dimension)
                let trialRank = rrefSummary(for: trialMatrix).rank
                if trialRank > extractedBasis.count {
                    extractedBasis.append(candidate)
                    addedVectors.append(candidate)
                    steps.append("Added e\(basisIndex + 1) to increase rank to \(trialRank).")
                }
            }
        }

        let answer = "Pruned set to \(extractedBasis.count - addedVectors.count) independent vectors and extended to a basis of R^\(dimension) with \(addedVectors.count) added vectors."
        let diagnostics: [String] = [
            "Mode: Exact (rational arithmetic).",
            "Spaces workflow: basis extend / prune.",
            "Input vectors: \(generatingVectors.count).",
            "Ambient dimension: \(dimension).",
            "Rank(U): \(rankSummary.rank).",
            "Pruned vectors: \(prunedCount).",
            "Added extension vectors: \(addedVectors.count).",
            "Extended basis: \(inlineBasis(extractedBasis))."
        ]

        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(generatingMatrix),
                    source: "Spaces generating set U (vectors as columns)"
                )
            )
        ]
        if !extractedBasis.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(extractedBasis, rowCount: dimension)),
                        source: "Spaces extended basis (vectors as columns)"
                    )
                )
            )
        }

        return MatrixMasterComputationResult(
            answer: answer,
            diagnostics: diagnostics,
            steps: steps,
            reusablePayloads: payloads
        )
    }

    private func exactSpacesSubspaceSum(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let primaryVectors = try parseBasisVectors(from: request)
        let dimension = primaryVectors[0].count
        let secondaryVectors = try parseSecondaryBasisVectors(from: request, expectedDimension: dimension)
        let relation = exactSubspaceRelationSummary(primary: primaryVectors, secondary: secondaryVectors)

        var payloads: [MatrixMasterReusablePayload] = []
        if !relation.sumBasis.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(relation.sumBasis, rowCount: dimension)),
                        source: "Spaces U + W basis (vectors as columns)"
                    )
                )
            )
        }

        return MatrixMasterComputationResult(
            answer: "dim(U + W) = \(relation.dimSum), basis(U + W) = \(inlineBasis(relation.sumBasis)).",
            diagnostics: [
                "Mode: Exact (rational arithmetic).",
                "Spaces workflow: subspace sum.",
                "dim(U) = \(relation.dimU), dim(W) = \(relation.dimW), dim(U + W) = \(relation.dimSum).",
                "dim(U ∩ W) by rank formula = \(relation.dimIntersection)."
            ],
            steps: [
                "Formed [U W] by concatenating generating vectors.",
                "Reduced [U W] to obtain pivot columns for a basis of U + W.",
                "Applied dim(U + W) = dim(U) + dim(W) - dim(U ∩ W)."
            ],
            reusablePayloads: payloads
        )
    }

    private func exactSpacesSubspaceIntersection(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let primaryVectors = try parseBasisVectors(from: request)
        let dimension = primaryVectors[0].count
        let secondaryVectors = try parseSecondaryBasisVectors(from: request, expectedDimension: dimension)
        let relation = exactSubspaceRelationSummary(primary: primaryVectors, secondary: secondaryVectors)

        var payloads: [MatrixMasterReusablePayload] = []
        if !relation.intersectionBasis.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(relation.intersectionBasis, rowCount: dimension)),
                        source: "Spaces U intersection W basis (vectors as columns)"
                    )
                )
            )
        }

        let answer: String
        if relation.intersectionBasis.isEmpty {
            answer = "U ∩ W = {0}."
        } else {
            answer = "Basis(U ∩ W) = \(inlineBasis(relation.intersectionBasis))."
        }

        return MatrixMasterComputationResult(
            answer: answer,
            diagnostics: [
                "Mode: Exact (rational arithmetic).",
                "Spaces workflow: subspace intersection.",
                "dim(U ∩ W) = \(relation.dimIntersection).",
                "dim(U) + dim(W) - dim(U + W) = \(relation.dimIntersection)."
            ],
            steps: [
                "Solved U*a = W*b by reducing [U | -W].",
                "Converted null-space coefficient relations into intersection vectors.",
                "Extracted an independent basis for U ∩ W."
            ],
            reusablePayloads: payloads
        )
    }

    private func exactSpacesDirectSumCheck(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let primaryVectors = try parseBasisVectors(from: request)
        let dimension = primaryVectors[0].count
        let secondaryVectors = try parseSecondaryBasisVectors(from: request, expectedDimension: dimension)
        let relation = exactSubspaceRelationSummary(primary: primaryVectors, secondary: secondaryVectors)
        let isDirect = relation.dimIntersection == 0

        var payloads: [MatrixMasterReusablePayload] = []
        if !relation.intersectionBasis.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(relation.intersectionBasis, rowCount: dimension)),
                        source: "Spaces direct-sum obstruction basis (vectors as columns)"
                    )
                )
            )
        }

        let answer: String
        if isDirect {
            answer = "U and W form a direct sum: U ⊕ W."
        } else {
            answer = "U and W do not form a direct sum (nontrivial intersection)."
        }

        return MatrixMasterComputationResult(
            answer: answer,
            diagnostics: [
                "Mode: Exact (rational arithmetic).",
                "Spaces workflow: direct sum check.",
                "dim(U) = \(relation.dimU), dim(W) = \(relation.dimW), dim(U + W) = \(relation.dimSum).",
                "dim(U ∩ W) = \(relation.dimIntersection).",
                "Intersection basis: \(inlineBasis(relation.intersectionBasis))."
            ],
            steps: [
                "Computed U ∩ W via [U | -W] null-space relations.",
                "Applied criterion U ⊕ W iff U ∩ W = {0}.",
                "Used rank-nullity dimension identity as a consistency check."
            ],
            reusablePayloads: payloads
        )
    }

    private func operateExactData(_ request: MatrixMasterComputationRequest) throws -> MatrixMasterComputationResult {
        let rawPrimaryEntries = try rawMatrixEntries(from: request)
        guard !rawPrimaryEntries.isEmpty else {
            throw MatrixExactEngineError.missingMatrixInput
        }

        let matrixA = try parse(entries: rawPrimaryEntries)
        let operation = try resolveOperateKind(for: request)

        switch operation {
        case .matrixAdd:
            let matrixB = try parse(entries: request.secondaryMatrixEntries ?? rawPrimaryEntries)
            guard sameShape(matrixA, matrixB) else {
                throw MatrixExactEngineError.operateDimensionMismatch
            }
            let result = zip(matrixA, matrixB).map { rowA, rowB in
                zip(rowA, rowB).map(+)
            }
            let inline = inlineMatrix(result)
            return MatrixMasterComputationResult(
                answer: "A + B = \(inline)",
                diagnostics: [
                    "Mode: Exact.",
                    "Operation: A + B.",
                    "Result dimensions: \(result.count)x\(result.first?.count ?? 0)."
                ],
                steps: ["Added entries of A and B elementwise."],
                reusablePayloads: [
                    .matrix(MatrixReusablePayload(entries: stringify(result), source: "Operate A + B"))
                ]
            )
        case .matrixSubtract:
            let matrixB = try parse(entries: request.secondaryMatrixEntries ?? rawPrimaryEntries)
            guard sameShape(matrixA, matrixB) else {
                throw MatrixExactEngineError.operateDimensionMismatch
            }
            let result = zip(matrixA, matrixB).map { rowA, rowB in
                zip(rowA, rowB).map(-)
            }
            let inline = inlineMatrix(result)
            return MatrixMasterComputationResult(
                answer: "A - B = \(inline)",
                diagnostics: [
                    "Mode: Exact.",
                    "Operation: A - B.",
                    "Result dimensions: \(result.count)x\(result.first?.count ?? 0)."
                ],
                steps: ["Subtracted B from A entry-by-entry."],
                reusablePayloads: [
                    .matrix(MatrixReusablePayload(entries: stringify(result), source: "Operate A - B"))
                ]
            )
        case .matrixMultiply:
            let matrixB = try parse(entries: request.secondaryMatrixEntries ?? rawPrimaryEntries)
            guard (matrixA.first?.count ?? 0) == matrixB.count else {
                throw MatrixExactEngineError.operateDimensionMismatch
            }
            let result = multiply(matrixA, matrixB)
            let inline = inlineMatrix(result)
            return MatrixMasterComputationResult(
                answer: "A * B = \(inline)",
                diagnostics: [
                    "Mode: Exact.",
                    "Operation: A * B.",
                    "Result dimensions: \(result.count)x\(result.first?.count ?? 0)."
                ],
                steps: ["Computed row-column dot products for A * B."],
                reusablePayloads: [
                    .matrix(MatrixReusablePayload(entries: stringify(result), source: "Operate A * B"))
                ]
            )
        case .transpose:
            let result = transpose(matrixA)
            return MatrixMasterComputationResult(
                answer: "transpose(A) = \(inlineMatrix(result))",
                diagnostics: [
                    "Mode: Exact.",
                    "Operation: transpose(A).",
                    "Result dimensions: \(result.count)x\(result.first?.count ?? 0)."
                ],
                steps: ["Swapped rows and columns of A."],
                reusablePayloads: [
                    .matrix(MatrixReusablePayload(entries: stringify(result), source: "Operate transpose(A)"))
                ]
            )
        case .trace:
            guard matrixA.count == (matrixA.first?.count ?? 0) else {
                throw MatrixExactEngineError.operateRequiresSquareMatrix
            }
            let traceValue = trace(of: matrixA)
            return MatrixMasterComputationResult(
                answer: "trace(A) = \(traceValue.token)",
                diagnostics: ["Mode: Exact.", "Operation: trace(A)."],
                steps: ["Summed diagonal entries of A."]
            )
        case let .power(exponent):
            guard matrixA.count == (matrixA.first?.count ?? 0) else {
                throw MatrixExactEngineError.operateRequiresSquareMatrix
            }
            let result = power(matrixA, exponent: exponent)
            return MatrixMasterComputationResult(
                answer: "A^\(exponent) = \(inlineMatrix(result))",
                diagnostics: [
                    "Mode: Exact.",
                    "Operation: A^\(exponent)."
                ],
                steps: ["Applied repeated matrix multiplication \(exponent - 1) time(s)."],
                reusablePayloads: [
                    .matrix(MatrixReusablePayload(entries: stringify(result), source: "Operate A^\(exponent)"))
                ]
            )
        case .matrixVectorProduct:
            let vectorV = try parseVector(entries: request.vectorEntries)
            guard let vectorV else {
                throw MatrixExactEngineError.missingVectorInput
            }
            guard (matrixA.first?.count ?? 0) == vectorV.count else {
                throw MatrixExactEngineError.operateDimensionMismatch
            }
            let result = matrixVectorMultiply(matrixA, vectorV)
            return MatrixMasterComputationResult(
                answer: "A * v = \(inlineVector(result))",
                diagnostics: [
                    "Mode: Exact.",
                    "Operation: A * v."
                ],
                steps: ["Computed row dot products between A and v."],
                reusablePayloads: [
                    .vector(
                        VectorReusablePayload(
                            name: "Operate A*v",
                            entries: result.map(\.token),
                            source: "Operate A * v"
                        )
                    )
                ]
            )
        case .vectorAdd:
            let vectorV = try parseVector(entries: request.vectorEntries)
            let vectorU = try parseVector(entries: request.secondaryVectorEntries)
            guard let vectorU, let vectorV else {
                throw MatrixExactEngineError.missingVectorInput
            }
            guard vectorU.count == vectorV.count else {
                throw MatrixExactEngineError.operateDimensionMismatch
            }
            let result = zip(vectorU, vectorV).map(+)
            return MatrixMasterComputationResult(
                answer: "u + v = \(inlineVector(result))",
                diagnostics: ["Mode: Exact.", "Operation: u + v."],
                steps: ["Added vectors component-wise."],
                reusablePayloads: [
                    .vector(
                        VectorReusablePayload(
                            name: "Operate u+v",
                            entries: result.map(\.token),
                            source: "Operate u + v"
                        )
                    )
                ]
            )
        case let .scalarVectorMultiply(scalar):
            let vectorV = try parseVector(entries: request.vectorEntries)
            guard let vectorV else {
                throw MatrixExactEngineError.missingVectorInput
            }
            let result = vectorV.map { scalar * $0 }
            return MatrixMasterComputationResult(
                answer: "\(scalar.token) * v = \(inlineVector(result))",
                diagnostics: [
                    "Mode: Exact.",
                    "Operation: scalar-vector product."
                ],
                steps: ["Scaled each vector component by \(scalar.token)."],
                reusablePayloads: [
                    .vector(
                        VectorReusablePayload(
                            name: "Operate s*v",
                            entries: result.map(\.token),
                            source: "Operate scalar * v"
                        )
                    )
                ]
            )
        }
    }

    private func rawMatrixEntries(from request: MatrixMasterComputationRequest) throws -> [[String]] {
        guard let rawEntries = request.matrixEntries else {
            throw MatrixExactEngineError.missingMatrixInput
        }

        guard let firstRow = rawEntries.first else {
            return rawEntries
        }

        guard rawEntries.allSatisfy({ $0.count == firstRow.count }) else {
            throw MatrixExactEngineError.raggedMatrixInput
        }

        return rawEntries
    }

    private func rawSecondaryMatrixEntries(from request: MatrixMasterComputationRequest) throws -> [[String]] {
        guard let rawEntries = request.secondaryMatrixEntries else {
            throw MatrixExactEngineError.linearMapsRequiresSecondaryMatrix
        }

        guard let firstRow = rawEntries.first else {
            return rawEntries
        }

        guard rawEntries.allSatisfy({ $0.count == firstRow.count }) else {
            throw MatrixExactEngineError.raggedMatrixInput
        }

        return rawEntries
    }

    private func parseVector(entries: [String]?) throws -> [Rational]? {
        guard let entries else {
            return nil
        }

        var parsed: [Rational] = []
        for (index, token) in entries.enumerated() {
            guard let value = Rational(token: token) else {
                throw MatrixExactEngineError.unsupportedToken(
                    row: 1,
                    column: index + 1,
                    token: token
                )
            }
            parsed.append(value)
        }

        return parsed
    }

    private func parseBasisVectors(from request: MatrixMasterComputationRequest) throws -> [[Rational]] {
        guard let rawBasisVectors = request.basisVectors, !rawBasisVectors.isEmpty else {
            throw MatrixExactEngineError.analyzeRequiresBasisVectors
        }

        let expectedDimension = rawBasisVectors[0].count
        guard expectedDimension > 0 else {
            throw MatrixExactEngineError.analyzeRequiresBasisVectors
        }

        var parsedVectors: [[Rational]] = []
        for (vectorIndex, vectorTokens) in rawBasisVectors.enumerated() {
            guard vectorTokens.count == expectedDimension else {
                throw MatrixExactEngineError.analyzeBasisDimensionMismatch(
                    expected: expectedDimension,
                    actual: vectorTokens.count,
                    vectorIndex: vectorIndex
                )
            }

            var parsedVector: [Rational] = []
            for (entryIndex, token) in vectorTokens.enumerated() {
                guard let value = Rational(token: token) else {
                    throw MatrixExactEngineError.unsupportedToken(
                        row: vectorIndex + 1,
                        column: entryIndex + 1,
                        token: token
                    )
                }
                parsedVector.append(value)
            }
            parsedVectors.append(parsedVector)
        }

        return parsedVectors
    }

    private func parseSecondaryBasisVectors(
        from request: MatrixMasterComputationRequest,
        expectedDimension: Int
    ) throws -> [[Rational]] {
        guard let rawBasisVectors = request.secondaryBasisVectors, !rawBasisVectors.isEmpty else {
            throw MatrixExactEngineError.spacesRequiresSecondaryBasisVectors
        }

        guard let first = rawBasisVectors.first else {
            throw MatrixExactEngineError.spacesRequiresSecondaryBasisVectors
        }

        guard first.count == expectedDimension else {
            throw MatrixExactEngineError.spacesBasisDimensionMismatch(
                expected: expectedDimension,
                actual: first.count
            )
        }

        var parsedVectors: [[Rational]] = []
        for (vectorIndex, vectorTokens) in rawBasisVectors.enumerated() {
            guard vectorTokens.count == expectedDimension else {
                throw MatrixExactEngineError.analyzeBasisDimensionMismatch(
                    expected: expectedDimension,
                    actual: vectorTokens.count,
                    vectorIndex: vectorIndex
                )
            }

            var parsedVector: [Rational] = []
            for (entryIndex, token) in vectorTokens.enumerated() {
                guard let value = Rational(token: token) else {
                    throw MatrixExactEngineError.unsupportedToken(
                        row: vectorIndex + 1,
                        column: entryIndex + 1,
                        token: token
                    )
                }
                parsedVector.append(value)
            }
            parsedVectors.append(parsedVector)
        }

        return parsedVectors
    }

    private func parseLinearMapSecondaryBasisVectors(
        from request: MatrixMasterComputationRequest
    ) throws -> [[Rational]] {
        guard let rawBasisVectors = request.secondaryBasisVectors, !rawBasisVectors.isEmpty else {
            throw MatrixExactEngineError.linearMapsRequiresSecondaryBasisVectors
        }

        let expectedDimension = rawBasisVectors[0].count
        guard expectedDimension > 0 else {
            throw MatrixExactEngineError.linearMapsRequiresSecondaryBasisVectors
        }

        var parsedVectors: [[Rational]] = []
        for (vectorIndex, vectorTokens) in rawBasisVectors.enumerated() {
            guard vectorTokens.count == expectedDimension else {
                throw MatrixExactEngineError.analyzeBasisDimensionMismatch(
                    expected: expectedDimension,
                    actual: vectorTokens.count,
                    vectorIndex: vectorIndex
                )
            }

            var parsedVector: [Rational] = []
            for (entryIndex, token) in vectorTokens.enumerated() {
                guard let value = Rational(token: token) else {
                    throw MatrixExactEngineError.unsupportedToken(
                        row: vectorIndex + 1,
                        column: entryIndex + 1,
                        token: token
                    )
                }
                parsedVector.append(value)
            }
            parsedVectors.append(parsedVector)
        }

        return parsedVectors
    }

    private func parseAnalyzeTargetVector(
        from request: MatrixMasterComputationRequest,
        expectedDimension: Int
    ) throws -> [Rational] {
        guard let vector = try parseVector(entries: request.vectorEntries) else {
            throw MatrixExactEngineError.analyzeRequiresTargetVector
        }

        guard vector.count == expectedDimension else {
            throw MatrixExactEngineError.analyzeTargetDimensionMismatch(
                expected: expectedDimension,
                actual: vector.count
            )
        }

        return vector
    }

    private func solveExactBasisSystem(
        basisVectors: [[Rational]],
        targetVector: [Rational]
    ) -> ExactBasisSolveSummary {
        let variableCount = basisVectors.count
        let rowCount = targetVector.count
        var augmented = matrixFromColumnVectors(basisVectors, rowCount: rowCount)
        for row in 0..<rowCount {
            augmented[row].append(targetVector[row])
        }

        let reduced = rrefSummary(for: augmented)
        let basisPivotColumns = reduced.pivotColumns.filter { $0 < variableCount }
        let classification = classify(
            matrix: reduced.reduced,
            variableCount: variableCount,
            pivotColumns: basisPivotColumns
        )

        return ExactBasisSolveSummary(
            reducedAugmented: reduced.reduced,
            basisPivotColumns: basisPivotColumns,
            classification: classification
        )
    }

    private func particularSolution(
        from reducedAugmented: [[Rational]],
        variableCount: Int,
        pivotColumns: [Int]
    ) -> [Rational] {
        var solution = Array(repeating: Rational.zero, count: variableCount)

        for (pivotRow, pivotColumn) in pivotColumns.enumerated()
        where pivotRow < reducedAugmented.count {
            solution[pivotColumn] = reducedAugmented[pivotRow][variableCount]
        }

        return solution
    }

    private func sameShape(_ lhs: [[Rational]], _ rhs: [[Rational]]) -> Bool {
        lhs.count == rhs.count && (lhs.first?.count ?? 0) == (rhs.first?.count ?? 0)
    }

    private func multiply(_ lhs: [[Rational]], _ rhs: [[Rational]]) -> [[Rational]] {
        let rowCount = lhs.count
        let innerCount = lhs.first?.count ?? 0
        let columnCount = rhs.first?.count ?? 0
        var result = Array(
            repeating: Array(repeating: Rational.zero, count: columnCount),
            count: rowCount
        )

        for row in 0..<rowCount {
            for column in 0..<columnCount {
                var total = Rational.zero
                for inner in 0..<innerCount {
                    total += lhs[row][inner] * rhs[inner][column]
                }
                result[row][column] = total
            }
        }

        return result
    }

    private func transpose(_ matrix: [[Rational]]) -> [[Rational]] {
        let rowCount = matrix.count
        let columnCount = matrix.first?.count ?? 0
        var result = Array(
            repeating: Array(repeating: Rational.zero, count: rowCount),
            count: columnCount
        )

        for row in 0..<rowCount {
            for column in 0..<columnCount {
                result[column][row] = matrix[row][column]
            }
        }

        return result
    }

    private func power(_ matrix: [[Rational]], exponent: Int) -> [[Rational]] {
        guard exponent > 1 else {
            return matrix
        }

        var result = matrix
        for _ in 2...exponent {
            result = multiply(result, matrix)
        }
        return result
    }

    private func matrixVectorMultiply(_ matrix: [[Rational]], _ vector: [Rational]) -> [Rational] {
        matrix.map { row in
            zip(row, vector).reduce(Rational.zero) { partial, pair in
                partial + pair.0 * pair.1
            }
        }
    }

    private func inlineVector(_ vector: [Rational]) -> String {
        "[\(vector.map(\.token).joined(separator: ", "))]"
    }

    private func resolveOperateKind(for request: MatrixMasterComputationRequest) throws -> ExactResolvedOperateKind {
        let baseKind = request.operateKind ?? .matrixAdd

        switch baseKind {
        case .matrixAdd:
            return .matrixAdd
        case .matrixSubtract:
            return .matrixSubtract
        case .matrixMultiply:
            return .matrixMultiply
        case .transpose:
            return .transpose
        case .trace:
            return .trace
        case .power:
            return .power(max(1, request.exponent ?? 2))
        case .matrixVectorProduct:
            return .matrixVectorProduct
        case .vectorAdd:
            return .vectorAdd
        case .scalarVectorMultiply:
            let scalar = request.scalarToken.flatMap(Rational.init(token:)) ?? Rational(2, 1)
            return .scalarVectorMultiply(scalar)
        case .expression:
            return try resolveOperateExpression(request.expression)
        }
    }

    private func resolveOperateExpression(_ expression: String?) throws -> ExactResolvedOperateKind {
        let rawExpression = (expression ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = rawExpression
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        switch normalized {
        case "a+b":
            return .matrixAdd
        case "a-b":
            return .matrixSubtract
        case "a*b":
            return .matrixMultiply
        case "a*v":
            return .matrixVectorProduct
        case "u+v":
            return .vectorAdd
        case "transpose(a)":
            return .transpose
        case "trace(a)":
            return .trace
        default:
            break
        }

        if normalized.hasPrefix("a^"),
           let exponent = Int(normalized.dropFirst(2)),
           exponent >= 1 {
            return .power(exponent)
        }

        if normalized.hasSuffix("*v") {
            let scalarToken = String(normalized.dropLast(2))
            if let scalar = Rational(token: scalarToken) {
                return .scalarVectorMultiply(scalar)
            }
        }

        throw MatrixExactEngineError.unsupportedOperateExpression(rawExpression)
    }

    private func rrefSummary(for matrix: [[Rational]]) -> RREFSummary {
        guard let firstRow = matrix.first else {
            return RREFSummary(reduced: matrix, pivotColumns: [])
        }

        var work = matrix
        var pivotColumns: [Int] = []
        var pivotRow = 0
        let columnCount = firstRow.count

        for column in 0..<columnCount {
            guard pivotRow < work.count else {
                break
            }

            guard let rowWithPivot = (pivotRow..<work.count).first(where: { !work[$0][column].isZero }) else {
                continue
            }

            if rowWithPivot != pivotRow {
                work.swapAt(rowWithPivot, pivotRow)
            }

            let pivotValue = work[pivotRow][column]
            if !pivotValue.isOne {
                let reciprocal = Rational(pivotValue.denominator, pivotValue.numerator)
                scaleRow(&work[pivotRow], by: reciprocal)
            }

            for row in 0..<work.count where row != pivotRow {
                let factor = work[row][column]
                guard !factor.isZero else {
                    continue
                }

                addScaledRow(source: work[pivotRow], scale: -factor, destination: &work[row])
            }

            pivotColumns.append(column)
            pivotRow += 1
        }

        return RREFSummary(reduced: work, pivotColumns: pivotColumns)
    }

    private func trace(of matrix: [[Rational]]) -> Rational {
        var total = Rational.zero
        for index in matrix.indices {
            total += matrix[index][index]
        }
        return total
    }

    private func determinant(of matrix: [[Rational]]) -> DeterminantSummary {
        let size = matrix.count
        guard size > 0 else {
            return DeterminantSummary(value: Rational.one, steps: ["Computed determinant on empty matrix as 1."])
        }

        var work = matrix
        var sign = 1
        var steps: [String] = []

        for column in 0..<size {
            guard let pivotRow = (column..<size).first(where: { !work[$0][column].isZero }) else {
                steps.append("Column \(column + 1) has no pivot; determinant is 0.")
                return DeterminantSummary(value: .zero, steps: steps)
            }

            if pivotRow != column {
                work.swapAt(pivotRow, column)
                sign *= -1
                steps.append("Swapped rows \(column + 1) and \(pivotRow + 1) (determinant sign flip).")
            }

            let pivot = work[column][column]
            for row in (column + 1)..<size {
                let factor = work[row][column] / pivot
                guard !factor.isZero else {
                    continue
                }

                for innerColumn in column..<size {
                    work[row][innerColumn] -= factor * work[column][innerColumn]
                }
            }
        }

        var determinant = Rational.one
        for index in 0..<size {
            determinant *= work[index][index]
        }

        if sign < 0 {
            determinant = -determinant
        }

        steps.append("Multiplied upper-triangular pivots to obtain determinant \(determinant.token).")
        return DeterminantSummary(value: determinant, steps: steps)
    }

    private func inverse(of matrix: [[Rational]]) -> InverseSummary {
        let size = matrix.count
        var work: [[Rational]] = []
        var steps: [String] = []

        for row in 0..<size {
            var augmentedRow = matrix[row]
            for column in 0..<size {
                augmentedRow.append(row == column ? .one : .zero)
            }
            work.append(augmentedRow)
        }

        for column in 0..<size {
            guard let pivotRow = (column..<size).first(where: { !work[$0][column].isZero }) else {
                steps.append("Column \(column + 1) has no pivot; matrix is singular.")
                return InverseSummary(inverse: nil, steps: steps)
            }

            if pivotRow != column {
                work.swapAt(pivotRow, column)
                steps.append("R\(column + 1) <-> R\(pivotRow + 1)")
            }

            let pivotValue = work[column][column]
            if !pivotValue.isOne {
                let reciprocal = Rational(pivotValue.denominator, pivotValue.numerator)
                scaleRow(&work[column], by: reciprocal)
                steps.append("R\(column + 1) = (\(reciprocal.token)) * R\(column + 1)")
            }

            for row in 0..<size where row != column {
                let factor = work[row][column]
                guard !factor.isZero else {
                    continue
                }

                addScaledRow(source: work[column], scale: -factor, destination: &work[row])
                steps.append("R\(row + 1) = R\(row + 1) + (\((-factor).token)) * R\(column + 1)")
            }
        }

        let inverseMatrix = work.map { row in
            Array(row.suffix(size))
        }

        return InverseSummary(inverse: inverseMatrix, steps: steps)
    }

    private func pivotDescription(_ pivotColumns: [Int]) -> String {
        if pivotColumns.isEmpty {
            return "none"
        }

        return pivotColumns.map { "c\($0 + 1)" }.joined(separator: ", ")
    }

    private func columnSpaceBasis(from matrix: [[Rational]], pivotColumns: [Int]) -> [[Rational]] {
        pivotColumns.map { pivotColumn in
            matrix.map { row in
                row[pivotColumn]
            }
        }
    }

    private func rowSpaceBasis(from reducedMatrix: [[Rational]]) -> [[Rational]] {
        reducedMatrix.filter { row in
            row.contains { !$0.isZero }
        }
    }

    private func nullSpaceBasis(
        from reducedMatrix: [[Rational]],
        pivotColumns: [Int],
        columnCount: Int
    ) -> [[Rational]] {
        let pivotSet = Set(pivotColumns)
        let freeColumns = (0..<columnCount).filter { !pivotSet.contains($0) }

        guard !freeColumns.isEmpty else {
            return []
        }

        var basis: [[Rational]] = []

        for freeColumn in freeColumns {
            var vector = Array(repeating: Rational.zero, count: columnCount)
            vector[freeColumn] = .one

            for (pivotRow, pivotColumn) in pivotColumns.enumerated() where pivotRow < reducedMatrix.count {
                vector[pivotColumn] = -reducedMatrix[pivotRow][freeColumn]
            }

            basis.append(vector)
        }

        return basis
    }

    private func matrixFromColumnVectors(_ vectors: [[Rational]], rowCount: Int) -> [[Rational]] {
        guard !vectors.isEmpty else {
            return []
        }

        var matrix = Array(
            repeating: Array(repeating: Rational.zero, count: vectors.count),
            count: rowCount
        )

        for column in vectors.indices {
            for row in 0..<rowCount {
                matrix[row][column] = vectors[column][row]
            }
        }

        return matrix
    }

    private func standardBasisVector(index: Int, dimension: Int) -> [Rational] {
        var vector = Array(repeating: Rational.zero, count: dimension)
        if index >= 0 && index < dimension {
            vector[index] = .one
        }
        return vector
    }

    private func linearCombination(
        of vectors: [[Rational]],
        coefficients: [Rational],
        dimension: Int
    ) -> [Rational] {
        var result = Array(repeating: Rational.zero, count: dimension)
        for (columnIndex, coefficient) in coefficients.enumerated() where columnIndex < vectors.count {
            guard !coefficient.isZero else {
                continue
            }
            for row in 0..<dimension {
                result[row] += coefficient * vectors[columnIndex][row]
            }
        }
        return result
    }

    private func isZeroVector(_ vector: [Rational]) -> Bool {
        vector.allSatisfy(\.isZero)
    }

    private func exactSubspaceRelationSummary(
        primary primaryVectors: [[Rational]],
        secondary secondaryVectors: [[Rational]]
    ) -> ExactSubspaceRelationSummary {
        let dimension = primaryVectors[0].count
        let primaryMatrix = matrixFromColumnVectors(primaryVectors, rowCount: dimension)
        let secondaryMatrix = matrixFromColumnVectors(secondaryVectors, rowCount: dimension)

        let primaryRank = rrefSummary(for: primaryMatrix).rank
        let secondaryRank = rrefSummary(for: secondaryMatrix).rank

        let combinedVectors = primaryVectors + secondaryVectors
        let combinedMatrix = matrixFromColumnVectors(combinedVectors, rowCount: dimension)
        let sumRankSummary = rrefSummary(for: combinedMatrix)
        let sumBasis = sumRankSummary.pivotColumns.map { combinedVectors[$0] }

        var matchingMatrix = primaryMatrix
        for row in 0..<dimension {
            matchingMatrix[row].append(contentsOf: secondaryMatrix[row].map(-))
        }
        let matchingSummary = rrefSummary(for: matchingMatrix)
        let nullCoefficients = nullSpaceBasis(
            from: matchingSummary.reduced,
            pivotColumns: matchingSummary.pivotColumns,
            columnCount: combinedVectors.count
        )

        var intersectionCandidates: [[Rational]] = []
        for coefficientVector in nullCoefficients {
            let primaryCoefficients = Array(coefficientVector.prefix(primaryVectors.count))
            let candidate = linearCombination(
                of: primaryVectors,
                coefficients: primaryCoefficients,
                dimension: dimension
            )
            if !isZeroVector(candidate) {
                intersectionCandidates.append(candidate)
            }
        }

        let intersectionBasis: [[Rational]]
        if intersectionCandidates.isEmpty {
            intersectionBasis = []
        } else {
            let candidateMatrix = matrixFromColumnVectors(intersectionCandidates, rowCount: dimension)
            let candidateSummary = rrefSummary(for: candidateMatrix)
            intersectionBasis = candidateSummary.pivotColumns.map { intersectionCandidates[$0] }
        }

        return ExactSubspaceRelationSummary(
            dimU: primaryRank,
            dimW: secondaryRank,
            dimSum: sumRankSummary.rank,
            dimIntersection: intersectionBasis.count,
            sumBasis: sumBasis,
            intersectionBasis: intersectionBasis
        )
    }

    private func inlineBasis(_ vectors: [[Rational]]) -> String {
        guard !vectors.isEmpty else {
            return "{0}"
        }

        let vectorDescriptions = vectors.map { vector in
            "[\(vector.map(\.token).joined(separator: ", "))]"
        }
        return "{\(vectorDescriptions.joined(separator: ", "))}"
    }

    private func stringify(_ matrix: [[Rational]]) -> [[String]] {
        matrix.map { row in
            row.map(\.token)
        }
    }

    private func inlineMatrix(_ matrix: [[Rational]]) -> String {
        let rowDescriptions = matrix.map { row in
            "[\(row.map(\.token).joined(separator: ", "))]"
        }

        return "[\(rowDescriptions.joined(separator: ", "))]"
    }

    private func parse(entries: [[String]]) throws -> [[Rational]] {
        var parsedRows: [[Rational]] = []

        for (rowIndex, row) in entries.enumerated() {
            var parsedRow: [Rational] = []
            for (columnIndex, token) in row.enumerated() {
                guard let value = Rational(token: token) else {
                    throw MatrixExactEngineError.unsupportedToken(
                        row: rowIndex + 1,
                        column: columnIndex + 1,
                        token: token
                    )
                }
                parsedRow.append(value)
            }
            parsedRows.append(parsedRow)
        }

        return parsedRows
    }

    private func scaleRow(_ row: inout [Rational], by factor: Rational) {
        for index in row.indices {
            row[index] *= factor
        }
    }

    private func addScaledRow(source: [Rational], scale: Rational, destination: inout [Rational]) {
        for index in destination.indices {
            destination[index] += scale * source[index]
        }
    }

    private func classify(
        matrix: [[Rational]],
        variableCount: Int,
        pivotColumns: [Int]
    ) -> SolveClassification {
        for row in matrix {
            let coefficientSlice = row.prefix(variableCount)
            let allZeroCoefficients = coefficientSlice.allSatisfy(\.isZero)
            if allZeroCoefficients && !row[variableCount].isZero {
                return .inconsistent
            }
        }

        if pivotColumns.count == variableCount {
            let solution = extractUniqueSolution(from: matrix, variableCount: variableCount, pivotColumns: pivotColumns)
            return .unique(solution: solution)
        }

        let pivotColumnSet = Set(pivotColumns)
        let freeVariables = (0..<variableCount).filter { !pivotColumnSet.contains($0) }
        return .infinite(freeVariables: freeVariables)
    }

    private func extractUniqueSolution(
        from matrix: [[Rational]],
        variableCount: Int,
        pivotColumns: [Int]
    ) -> [Rational] {
        var solution = Array(repeating: Rational.zero, count: variableCount)

        for (rowIndex, pivotColumn) in pivotColumns.enumerated() where rowIndex < matrix.count && pivotColumn < variableCount {
            solution[pivotColumn] = matrix[rowIndex][variableCount]
        }

        return solution
    }

    private func formattedSolution(_ solution: [Rational]) -> String {
        solution
            .enumerated()
            .map { "x\($0.offset + 1) = \($0.element.token)" }
            .joined(separator: ", ")
    }

    private func formattedCoefficients(_ coefficients: [Rational]) -> String {
        coefficients
            .enumerated()
            .map { "c\($0.offset + 1) = \($0.element.token)" }
            .joined(separator: ", ")
    }

    private func coordinateFamilyExpression(
        witness: [Rational],
        directions: [[Rational]]
    ) -> String {
        var segments = ["c = \(inlineVector(witness))"]
        for (index, direction) in directions.enumerated() {
            segments.append("+ t\(index + 1) * \(inlineVector(direction))")
        }
        return segments.joined(separator: " ")
    }

    private func formattedDependenceRelation(_ coefficients: [Rational]) -> String {
        let terms = coefficients.enumerated().map { index, coefficient in
            "(\(coefficient.token)) * v\(index + 1)"
        }
        return "\(terms.joined(separator: " + ")) = 0"
    }

    private func buildDiagnostics(
        classification: SolveClassification,
        pivotColumns: [Int],
        variableCount: Int
    ) -> [String] {
        let pivotDescription: String
        if pivotColumns.isEmpty {
            pivotDescription = "none"
        } else {
            pivotDescription = pivotColumns.map { "c\($0 + 1)" }.joined(separator: ", ")
        }

        let classificationDescription: String
        switch classification {
        case .inconsistent:
            classificationDescription = "inconsistent"
        case .infinite:
            classificationDescription = "infinitely many solutions"
        case .unique:
            classificationDescription = "unique solution"
        }

        var diagnostics: [String] = [
            "Mode: Exact (rational row-reduction).",
            "Unknowns: \(variableCount).",
            "Pivot columns: \(pivotDescription).",
            "Classification: \(classificationDescription)."
        ]

        if case let .infinite(freeVariables) = classification {
            let freeDescription = freeVariables.map { "x\($0 + 1)" }.joined(separator: ", ")
            diagnostics.append("Free variables: \(freeDescription).")
        }

        return diagnostics
    }
}

public typealias StubMatrixExactEngine = MatrixExactEngine

private enum ExactResolvedOperateKind {
    case matrixAdd
    case matrixSubtract
    case matrixMultiply
    case transpose
    case trace
    case power(Int)
    case matrixVectorProduct
    case vectorAdd
    case scalarVectorMultiply(Rational)
}

private struct RREFSummary {
    let reduced: [[Rational]]
    let pivotColumns: [Int]

    var rank: Int {
        pivotColumns.count
    }
}

private struct DeterminantSummary {
    let value: Rational
    let steps: [String]
}

private struct InverseSummary {
    let inverse: [[Rational]]?
    let steps: [String]
}

private struct ExactBasisSolveSummary {
    let reducedAugmented: [[Rational]]
    let basisPivotColumns: [Int]
    let classification: SolveClassification
}

private struct ExactSubspaceRelationSummary {
    let dimU: Int
    let dimW: Int
    let dimSum: Int
    let dimIntersection: Int
    let sumBasis: [[Rational]]
    let intersectionBasis: [[Rational]]
}

private enum SolveClassification: Equatable {
    case unique(solution: [Rational])
    case infinite(freeVariables: [Int])
    case inconsistent

    var summaryStep: String {
        switch self {
        case .inconsistent:
            return "Detected a contradictory row, so the system is inconsistent."
        case let .infinite(freeVariables):
            let freeDescription = freeVariables.map { "x\($0 + 1)" }.joined(separator: ", ")
            return "At least one free variable remains (\(freeDescription)); solutions are parameterized."
        case .unique:
            return "Every variable has a pivot column; the system has a unique solution."
        }
    }
}

private struct Rational: Equatable {
    let numerator: Int
    let denominator: Int

    static let zero = Rational(0, 1)
    static let one = Rational(1, 1)
    private static let maxPowerOfTenExponent = String(Int.max).count - 1

    var isZero: Bool { numerator == 0 }
    var isOne: Bool { numerator == denominator }

    var token: String {
        denominator == 1 ? "\(numerator)" : "\(numerator)/\(denominator)"
    }

    init(_ numerator: Int, _ denominator: Int) {
        precondition(denominator != 0, "Denominator must not be zero.")

        if numerator == 0 {
            self.numerator = 0
            self.denominator = 1
            return
        }

        let sign = denominator < 0 ? -1 : 1
        let adjustedNumerator = numerator * sign
        let adjustedDenominator = abs(denominator)
        let divisor = Self.gcd(abs(adjustedNumerator), adjustedDenominator)

        self.numerator = adjustedNumerator / divisor
        self.denominator = adjustedDenominator / divisor
    }

    init?(token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if trimmed.contains("/") {
            let components = trimmed.split(separator: "/", omittingEmptySubsequences: false)
            guard components.count == 2,
                  let numerator = Int(components[0]),
                  let denominator = Int(components[1]),
                  denominator != 0 else {
                return nil
            }
            self.init(numerator, denominator)
            return
        }

        if let integer = Int(trimmed) {
            self.init(integer, 1)
            return
        }

        guard let decimal = Self.parseDecimalOrScientificNotation(trimmed) else {
            return nil
        }

        self = decimal
    }

    private static func parseDecimalOrScientificNotation(_ token: String) -> Rational? {
        var significandToken = token
        var exponent = 0

        if let exponentMarkerIndex = token.firstIndex(where: { $0 == "e" || $0 == "E" }) {
            let exponentStart = token.index(after: exponentMarkerIndex)
            let exponentToken = String(token[exponentStart...])
            guard !exponentToken.isEmpty,
                  let parsedExponent = Int(exponentToken) else {
                return nil
            }

            significandToken = String(token[..<exponentMarkerIndex])
            guard !significandToken.isEmpty,
                  !significandToken.contains("e"),
                  !significandToken.contains("E") else {
                return nil
            }

            exponent = parsedExponent
        }

        guard let significand = parseSignedDecimal(significandToken) else {
            return nil
        }

        return applyPowerOfTen(exponent: exponent, to: significand)
    }

    private static func parseSignedDecimal(_ token: String) -> Rational? {
        var body = token
        var sign = 1

        if body.hasPrefix("-") {
            sign = -1
            body.removeFirst()
        } else if body.hasPrefix("+") {
            body.removeFirst()
        }

        guard !body.isEmpty else {
            return nil
        }

        let parts = body.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else {
            return nil
        }

        if parts.count == 1 {
            guard let integer = Int(String(parts[0])) else {
                return nil
            }

            let signedInteger = sign == -1 ? -integer : integer
            return Rational(signedInteger, 1)
        }

        let wholePart = String(parts[0])
        let fractionalPart = String(parts[1])

        guard !wholePart.isEmpty || !fractionalPart.isEmpty else {
            return nil
        }

        guard (wholePart.isEmpty || Int(wholePart) != nil),
              (fractionalPart.isEmpty || Int(fractionalPart) != nil) else {
            return nil
        }

        let wholeValue = Int(wholePart) ?? 0
        if fractionalPart.isEmpty {
            return Rational(sign * wholeValue, 1)
        }

        var scale = 1
        for _ in fractionalPart {
            let (nextScale, overflowed) = scale.multipliedReportingOverflow(by: 10)
            guard !overflowed else {
                return nil
            }
            scale = nextScale
        }

        guard let fractionalValue = Int(fractionalPart) else {
            return nil
        }

        let (scaledWhole, scaledOverflowed) = wholeValue.multipliedReportingOverflow(by: scale)
        guard !scaledOverflowed else {
            return nil
        }

        let (combined, addOverflowed) = scaledWhole.addingReportingOverflow(fractionalValue)
        guard !addOverflowed else {
            return nil
        }

        let signedNumerator = sign == -1 ? -combined : combined
        return Rational(signedNumerator, scale)
    }

    private static func applyPowerOfTen(exponent: Int, to value: Rational) -> Rational? {
        guard exponent != 0 else {
            return value
        }

        let magnitude: Int
        if exponent < 0 {
            guard exponent != Int.min else {
                return nil
            }
            magnitude = -exponent
        } else {
            magnitude = exponent
        }

        guard magnitude <= maxPowerOfTenExponent,
              let power = powerOfTen(exponent: magnitude) else {
            return nil
        }

        if exponent > 0 {
            let (scaledNumerator, overflowed) = value.numerator.multipliedReportingOverflow(by: power)
            guard !overflowed else {
                return nil
            }

            return Rational(scaledNumerator, value.denominator)
        } else {
            let (scaledDenominator, overflowed) = value.denominator.multipliedReportingOverflow(by: power)
            guard !overflowed else {
                return nil
            }

            return Rational(value.numerator, scaledDenominator)
        }
    }

    private static func powerOfTen(exponent: Int) -> Int? {
        guard exponent >= 0 else {
            return nil
        }

        var power = 1
        for _ in 0..<exponent {
            let (next, overflowed) = power.multipliedReportingOverflow(by: 10)
            guard !overflowed else {
                return nil
            }
            power = next
        }

        return power
    }

    private static func gcd(_ lhs: Int, _ rhs: Int) -> Int {
        var a = lhs
        var b = rhs

        while b != 0 {
            let remainder = a % b
            a = b
            b = remainder
        }

        return max(1, a)
    }
}

private prefix func - (value: Rational) -> Rational {
    Rational(-value.numerator, value.denominator)
}

private func + (lhs: Rational, rhs: Rational) -> Rational {
    Rational(
        lhs.numerator * rhs.denominator + rhs.numerator * lhs.denominator,
        lhs.denominator * rhs.denominator
    )
}

private func - (lhs: Rational, rhs: Rational) -> Rational {
    lhs + (-rhs)
}

private func * (lhs: Rational, rhs: Rational) -> Rational {
    Rational(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator)
}

private func / (lhs: Rational, rhs: Rational) -> Rational {
    Rational(lhs.numerator * rhs.denominator, lhs.denominator * rhs.numerator)
}

private func += (lhs: inout Rational, rhs: Rational) {
    lhs = lhs + rhs
}

private func -= (lhs: inout Rational, rhs: Rational) {
    lhs = lhs - rhs
}

private func *= (lhs: inout Rational, rhs: Rational) {
    lhs = lhs * rhs
}
