import Foundation
import MatrixDomain

public enum MatrixNumericEngineError: Error, Equatable, LocalizedError {
    case nonNumericModeRequest
    case missingMatrixInput
    case missingVectorInput
    case solveRequiresAugmentedMatrix
    case emptyMatrixInput
    case analyzeRequiresBasisVectors
    case analyzeRequiresTargetVector
    case analyzeBasisDimensionMismatch(expected: Int, actual: Int, vectorIndex: Int)
    case analyzeTargetDimensionMismatch(expected: Int, actual: Int)
    case spacesRequiresSecondaryBasisVectors
    case spacesBasisDimensionMismatch(expected: Int, actual: Int)
    case raggedMatrixInput
    case unsupportedToken(row: Int, column: Int, token: String)
    case operateDimensionMismatch
    case operateRequiresSquareMatrix
    case unsupportedOperateExpression(String)

    public var errorDescription: String? {
        switch self {
        case .nonNumericModeRequest:
            return "Numeric engine requires numeric mode."
        case .missingMatrixInput:
            return "This workflow requires matrix entries."
        case .missingVectorInput:
            return "This operation requires vector entries."
        case .solveRequiresAugmentedMatrix:
            return "Solve requires an augmented matrix with at least one variable and one right-hand-side column."
        case .emptyMatrixInput:
            return "Analyze requires at least one matrix row."
        case .analyzeRequiresBasisVectors:
            return "This Analyze workflow requires basis vectors."
        case .analyzeRequiresTargetVector:
            return "This Analyze workflow requires a target vector."
        case let .analyzeBasisDimensionMismatch(expected, actual, vectorIndex):
            return "Basis vector \(vectorIndex + 1) has dimension \(actual), expected \(expected)."
        case let .analyzeTargetDimensionMismatch(expected, actual):
            return "Target vector has dimension \(actual), expected \(expected)."
        case .spacesRequiresSecondaryBasisVectors:
            return "This Spaces workflow requires a secondary generating set."
        case let .spacesBasisDimensionMismatch(expected, actual):
            return "Secondary generating set has dimension \(actual), expected \(expected)."
        case .raggedMatrixInput:
            return "Matrix rows must all have the same length."
        case let .unsupportedToken(row, column, token):
            return "Entry (\(row), \(column)) is unsupported in numeric mode: \(token)."
        case .operateDimensionMismatch:
            return "Operate input dimensions are incompatible for the selected operation."
        case .operateRequiresSquareMatrix:
            return "This operation requires a square matrix."
        case let .unsupportedOperateExpression(expression):
            return "Unsupported operate expression: \(expression)."
        }
    }
}

public protocol MatrixNumericComputing: Sendable {
    func compute(_ request: MatrixMasterComputationRequest) async throws -> MatrixMasterComputationResult
}

public struct StubMatrixNumericEngine: MatrixNumericComputing {
    public init() {}

    public func compute(_ request: MatrixMasterComputationRequest) async throws -> MatrixMasterComputationResult {
        guard request.mode == .numeric else {
            throw MatrixNumericEngineError.nonNumericModeRequest
        }

        switch request.destination {
        case .analyze:
            return try analyzeNumericMatrix(request)
        case .spaces:
            return try analyzeNumericSpaces(request)
        case .operate:
            return try operateNumericData(request)
        case .solve:
            return try solveNumericSystem(request)
        case .library:
            return MatrixMasterComputationResult(
                answer: "Library workflows are handled by the feature coordinator.",
                diagnostics: [
                    "Numeric library engine path remains pass-through."
                ],
                steps: []
            )
        }
    }

    private func solveNumericSystem(_ request: MatrixMasterComputationRequest) throws -> MatrixMasterComputationResult {
        let parsedMatrix = try parseMatrixEntries(request.matrixEntries)
        guard let firstRow = parsedMatrix.first, firstRow.count >= 2 else {
            throw MatrixNumericEngineError.solveRequiresAugmentedMatrix
        }

        let tolerance = 1.0e-9
        let variableCount = firstRow.count - 1
        let columnCount = firstRow.count
        let coefficientEntries = parsedMatrix.map { row in
            Array(row.prefix(variableCount)).map(formatted)
        }

        var work = parsedMatrix
        var pivotColumns: [Int] = []
        var steps: [String] = [
            "Interpreted input as an augmented matrix with \(work.count) equations and \(variableCount) unknowns."
        ]
        var pivotRow = 0

        for column in 0..<variableCount where pivotRow < work.count {
            guard let rowWithPivot = bestPivotRow(in: work, column: column, fromRow: pivotRow),
                  abs(work[rowWithPivot][column]) > tolerance else {
                continue
            }

            if rowWithPivot != pivotRow {
                work.swapAt(rowWithPivot, pivotRow)
                steps.append("R\(pivotRow + 1) <-> R\(rowWithPivot + 1)")
            }

            let pivot = work[pivotRow][column]
            for innerColumn in column..<columnCount {
                work[pivotRow][innerColumn] /= pivot
                if abs(work[pivotRow][innerColumn]) < tolerance {
                    work[pivotRow][innerColumn] = 0
                }
            }
            steps.append("R\(pivotRow + 1) = (1/\(formatted(pivot))) * R\(pivotRow + 1)")

            for row in 0..<work.count where row != pivotRow {
                let factor = work[row][column]
                guard abs(factor) > tolerance else {
                    continue
                }

                for innerColumn in column..<columnCount {
                    work[row][innerColumn] -= factor * work[pivotRow][innerColumn]
                    if abs(work[row][innerColumn]) < tolerance {
                        work[row][innerColumn] = 0
                    }
                }

                steps.append("R\(row + 1) = R\(row + 1) + (\(formatted(-factor))) * R\(pivotRow + 1)")
            }

            pivotColumns.append(column)
            pivotRow += 1
        }

        let classification = classifySolve(
            matrix: work,
            variableCount: variableCount,
            pivotColumns: pivotColumns,
            tolerance: tolerance
        )
        steps.append(classification.summaryStep)

        var diagnostics = buildSolveDiagnostics(
            classification: classification,
            pivotColumns: pivotColumns,
            variableCount: variableCount,
            tolerance: tolerance
        )
        diagnostics.append("RREF snapshot ready for reuse.")

        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: coefficientEntries,
                    source: "Solve coefficient matrix"
                )
            ),
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(work),
                    source: "Solve numeric RREF matrix"
                )
            )
        ]

        let answer: String
        switch classification {
        case let .unique(solution):
            answer = "Unique solution: \(formattedSolution(solution))"
            payloads.append(
                .vector(
                    VectorReusablePayload(
                        name: "Solve solution",
                        entries: solution.map(formatted),
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
            steps: steps,
            reusablePayloads: payloads
        )
    }

    private func analyzeNumericMatrix(_ request: MatrixMasterComputationRequest) throws -> MatrixMasterComputationResult {
        let analyzeKind = request.analyzeKind ?? .matrixProperties
        switch analyzeKind {
        case .matrixProperties:
            break
        case .spanMembership:
            return try analyzeNumericSpanMembership(request)
        case .independence:
            return try analyzeNumericIndependence(request)
        case .coordinates:
            return try analyzeNumericCoordinates(request)
        }

        let matrix = try parseMatrixEntries(request.matrixEntries)
        let rowCount = matrix.count
        let columnCount = matrix[0].count
        let tolerance = 1.0e-9

        let rankSummary = rank(of: matrix, tolerance: tolerance)
        let nullity = max(0, columnCount - rankSummary.rank)
        let columnBasisVectors = columnSpaceBasis(from: matrix, pivotColumns: rankSummary.pivotColumns)
        let rowBasisVectors = rowSpaceBasis(from: rankSummary.reduced, tolerance: tolerance)
        let nullBasisVectors = nullSpaceBasis(
            from: rankSummary.reduced,
            pivotColumns: rankSummary.pivotColumns,
            columnCount: columnCount,
            tolerance: tolerance
        )
        let qrSummary = qrDecomposition(of: matrix, tolerance: tolerance)
        let sigmaSummary = singularValueSummary(of: matrix, tolerance: tolerance)

        var answerParts = [
            "Numeric rank(A) = \(rankSummary.rank)",
            "nullity(A) = \(nullity)",
            "dim Col(A) = \(columnBasisVectors.count)",
            "dim Row(A) = \(rowBasisVectors.count)",
            "dim Null(A) = \(nullBasisVectors.count)"
        ]
        var diagnostics = [
            "Mode: Numeric (Double).",
            "Dimensions: \(rowCount)x\(columnCount).",
            "Tolerance: \(formattedScientific(tolerance)).",
            "Pivot columns: \(pivotDescription(rankSummary.pivotColumns)).",
            "Nullity(A): \(nullity).",
            "Rank-nullity check: \(rankSummary.rank) + \(nullity) = \(columnCount).",
            "Col(A) basis: \(inlineBasis(columnBasisVectors)).",
            "Row(A) basis: \(inlineBasis(rowBasisVectors)).",
            "Null(A) basis: \(inlineBasis(nullBasisVectors))."
        ]
        var steps = [
            "Computed rank with Gaussian elimination at tolerance \(formattedScientific(tolerance)).",
            "Used pivot columns from the original matrix to witness a column-space basis.",
            "Used nonzero rows of RREF to witness a row-space basis."
        ]
        var payloads: [MatrixMasterReusablePayload] = [
            .matrix(
                MatrixReusablePayload(
                    entries: stringify(rankSummary.reduced),
                    source: "Analyze numeric RREF matrix"
                )
            )
        ]

        if !columnBasisVectors.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(columnBasisVectors, rowCount: rowCount)),
                        source: "Analyze numeric column space basis (vectors as columns)"
                    )
                )
            )
        }

        if !rowBasisVectors.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(rowBasisVectors, rowCount: columnCount)),
                        source: "Analyze numeric row space basis (vectors as columns)"
                    )
                )
            )
        }

        if !nullBasisVectors.isEmpty {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(matrixFromColumnVectors(nullBasisVectors, rowCount: columnCount)),
                        source: "Analyze numeric null space basis (vectors as columns)"
                    )
                )
            )
            steps.append("Set each free variable to 1 (others 0) to construct a numeric null-space basis.")
        } else {
            steps.append("No free variables remain at tolerance, so Null(A) is treated as the trivial subspace {0}.")
        }

        answerParts.append(qrSummary.success ? "QR: available" : "QR: unstable at tolerance")
        diagnostics.append(
            qrSummary.success
            ? "QR decomposition succeeded via modified Gram-Schmidt."
            : "QR decomposition failed due to near-dependent columns."
        )
        steps.append(
            qrSummary.success
            ? "Computed QR factors using modified Gram-Schmidt."
            : "QR decomposition encountered a near-zero column norm."
        )

        if qrSummary.success {
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(qrSummary.q),
                        source: "Analyze numeric Q factor"
                    )
                )
            )
            payloads.append(
                .matrix(
                    MatrixReusablePayload(
                        entries: stringify(qrSummary.r),
                        source: "Analyze numeric R factor"
                    )
                )
            )
        }

        if let sigmaMax = sigmaSummary.sigmaMax {
            answerParts.append("sigma_max(A) ~= \(formatted(sigmaMax))")
            diagnostics.append("Largest singular value estimate: \(formatted(sigmaMax)).")
            if !sigmaSummary.singularValues.isEmpty {
                answerParts.append(
                    "SVD singular values ~= [\(sigmaSummary.singularValues.map(formatted).joined(separator: ", "))]"
                )
                diagnostics.append("SVD baseline singular values computed from AᵀA eigenvalue deflation.")
                payloads.append(
                    .vector(
                        VectorReusablePayload(
                            name: "Analyze singular values",
                            entries: sigmaSummary.singularValues.map(formatted),
                            source: "Analyze SVD singular values"
                        )
                    )
                )
            }
            steps.append("Estimated singular spectrum from repeated dominant-eigen extraction on AᵀA.")
        } else {
            answerParts.append("sigma_max(A): unavailable")
            diagnostics.append("Largest singular value and SVD baseline could not converge.")
        }

        if rowCount == columnCount {
            let traceValue = trace(of: matrix)
            let determinantValue = determinant(of: matrix, tolerance: tolerance)
            let luSummary = luDecomposition(of: matrix, tolerance: tolerance)
            let inverseSummary = inverse(of: matrix, tolerance: tolerance)
            let eigenSummary = dominantEigenpair(of: matrix, tolerance: tolerance)

            answerParts.insert("det(A) ~= \(formatted(determinantValue))", at: 0)
            answerParts.append("trace(A) ~= \(formatted(traceValue))")
            answerParts.append(
                luSummary.success
                ? "LU: available"
                : "LU: singular/unstable at tolerance"
            )
            if let eigenvalue = eigenSummary.eigenvalue {
                answerParts.append("lambda_max(A) ~= \(formatted(eigenvalue))")
            } else {
                answerParts.append("lambda_max(A): unavailable")
            }
            answerParts.append(
                inverseSummary.inverse == nil
                ? "inverse(A): not available (singular/unstable)"
                : "inverse(A): available"
            )
            if let inverse = inverseSummary.inverse {
                answerParts.append("inverse(A) ~= \(inlineMatrix(inverse))")
            }

            diagnostics.append("Trace(A): \(formatted(traceValue)).")
            diagnostics.append("Determinant: \(formatted(determinantValue)).")
            diagnostics.append(
                luSummary.success
                ? "LU decomposition succeeded with partial pivoting."
                : "LU decomposition hit a near-zero pivot at tolerance."
            )
            diagnostics.append(
                eigenSummary.eigenvalue == nil
                ? "Dominant eigen estimate did not converge."
                : "Dominant eigen estimate computed by power iteration."
            )
            diagnostics.append(
                inverseSummary.inverse == nil
                ? "Inverse(A): near-zero pivot encountered at tolerance."
                : "Inverse(A): computed via Gauss-Jordan elimination."
            )

            steps.append("Computed determinant from elimination pivots.")
            steps.append(contentsOf: inverseSummary.steps.prefix(3))
            steps.append(contentsOf: eigenSummary.steps.prefix(2))

            if luSummary.success {
                steps.append("Computed LU factors with partial pivoting.")
                payloads.append(
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(luSummary.lower),
                            source: "Analyze numeric L factor"
                        )
                    )
                )
                payloads.append(
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(luSummary.upper),
                            source: "Analyze numeric U factor"
                        )
                    )
                )
            }

            if let eigenvector = eigenSummary.eigenvector {
                payloads.append(
                    .vector(
                        VectorReusablePayload(
                            name: "Analyze dominant eigenvector",
                            entries: eigenvector.map(formatted),
                            source: "Analyze dominant eigenvector"
                        )
                    )
                )
            }

            if let inverse = inverseSummary.inverse {
                payloads.append(
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(inverse),
                            source: "Analyze numeric inverse matrix"
                        )
                    )
                )
            }
        } else {
            diagnostics.append("Trace, determinant, LU decomposition, and eigen analysis require a square matrix.")
            answerParts.append("trace(A), det(A), LU, lambda_max(A): square matrices only")
        }

        return MatrixMasterComputationResult(
            answer: answerParts.joined(separator: " | "),
            diagnostics: diagnostics,
            steps: steps,
            reusablePayloads: payloads
        )
    }

    private func analyzeNumericSpanMembership(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let basisVectors = try parseBasisVectors(from: request)
        let tolerance = 1.0e-9
        let dimension = basisVectors[0].count
        let targetVector = try parseAnalyzeTargetVector(
            from: request,
            expectedDimension: dimension
        )
        let coefficientMatrix = matrixFromColumnVectors(basisVectors, rowCount: dimension)
        let solveSummary = solveNumericBasisSystem(
            basisVectors: basisVectors,
            targetVector: targetVector,
            tolerance: tolerance
        )

        var diagnostics: [String] = [
            "Mode: Numeric (Double).",
            "Analyze workflow: span membership.",
            "Tolerance: \(formattedScientific(tolerance)).",
            "Basis vectors: \(basisVectors.count).",
            "Vector dimension: \(dimension).",
            "Pivot columns in basis matrix: \(pivotDescription(solveSummary.basisPivotColumns))."
        ]
        var steps: [String] = [
            "Built the coefficient matrix using basis vectors as columns.",
            "Solved B * c = x with tolerance-aware RREF."
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
            diagnostics.append("Classification: inconsistent system at tolerance, so x is not in span(B).")
            steps.append("A contradictory row appeared in the augmented system.")
        case let .unique(solution):
            answer = "Target vector is in span(B). Witness: \(formattedCoefficients(solution))."
            diagnostics.append("Classification: unique coefficient witness.")
            payloads.append(
                .vector(
                    VectorReusablePayload(
                        name: "Span membership coefficients",
                        entries: solution.map(formatted),
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
                        entries: witness.map(formatted),
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

    private func analyzeNumericIndependence(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let basisVectors = try parseBasisVectors(from: request)
        let tolerance = 1.0e-9
        let dimension = basisVectors[0].count
        let coefficientMatrix = matrixFromColumnVectors(basisVectors, rowCount: dimension)
        let rankSummary = rank(of: coefficientMatrix, tolerance: tolerance)
        let rank = rankSummary.rank
        let vectorCount = basisVectors.count
        let isIndependent = rank == vectorCount
        let nullBasis = nullSpaceBasis(
            from: rankSummary.reduced,
            pivotColumns: rankSummary.pivotColumns,
            columnCount: vectorCount,
            tolerance: tolerance
        )
        let extractedBasisVectors = rankSummary.pivotColumns.map { basisVectors[$0] }

        var diagnostics: [String] = [
            "Mode: Numeric (Double).",
            "Analyze workflow: independence/dependence.",
            "Tolerance: \(formattedScientific(tolerance)).",
            "Vector count: \(vectorCount).",
            "Vector dimension: \(dimension).",
            "Rank(B): \(rank)."
        ]
        let steps: [String] = [
            "Built matrix B with vectors as columns.",
            "Computed RREF/pivot columns with tolerance-aware elimination: \(pivotDescription(rankSummary.pivotColumns))."
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
            let relationCoefficients = nullBasis.first ?? Array(repeating: 0.0, count: vectorCount)
            answer = "Vectors are linearly dependent. Witness: \(formattedDependenceRelation(relationCoefficients))."
            diagnostics.append("Classification: dependent (rank is less than vector count).")
            if !nullBasis.isEmpty {
                payloads.append(
                    .vector(
                        VectorReusablePayload(
                            name: "Dependence coefficients",
                            entries: relationCoefficients.map(formatted),
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

    private func analyzeNumericCoordinates(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let basisVectors = try parseBasisVectors(from: request)
        let tolerance = 1.0e-9
        let dimension = basisVectors[0].count
        let targetVector = try parseAnalyzeTargetVector(
            from: request,
            expectedDimension: dimension
        )
        let coefficientMatrix = matrixFromColumnVectors(basisVectors, rowCount: dimension)
        let rankSummary = rank(of: coefficientMatrix, tolerance: tolerance)
        let vectorCount = basisVectors.count
        let basisIsIndependent = rankSummary.rank == vectorCount
        let nullBasis = nullSpaceBasis(
            from: rankSummary.reduced,
            pivotColumns: rankSummary.pivotColumns,
            columnCount: vectorCount,
            tolerance: tolerance
        )

        var diagnostics: [String] = [
            "Mode: Numeric (Double).",
            "Analyze workflow: coordinate vector.",
            "Tolerance: \(formattedScientific(tolerance)).",
            "Basis vectors: \(vectorCount).",
            "Vector dimension: \(dimension).",
            "Rank(B): \(rankSummary.rank)."
        ]
        let steps = [
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

        let solveSummary = solveNumericBasisSystem(
            basisVectors: basisVectors,
            targetVector: targetVector,
            tolerance: tolerance
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
                        entries: solution.map(formatted),
                        source: "Analyze coordinate vector"
                    )
                )
            )
            return MatrixMasterComputationResult(
                answer: "[x]_beta ~= [\(solution.map(formatted).joined(separator: ", "))]",
                diagnostics: diagnostics,
                steps: steps + ["Solved B * c = x using tolerance-aware elimination."],
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
            }
            payloads.append(
                .vector(
                    VectorReusablePayload(
                        name: "Coordinate witness",
                        entries: witness.map(formatted),
                        source: "Analyze coordinate witness"
                    )
                )
            )
            if let relation = nullBasis.first {
                payloads.append(
                    .vector(
                        VectorReusablePayload(
                            name: "Coordinate nullspace direction",
                            entries: relation.map(formatted),
                            source: "Analyze coordinate nullspace direction"
                        )
                    )
                )
            }
            return MatrixMasterComputationResult(
                answer: "Coordinate vector is not unique. One witness: \(formattedCoefficients(witness)). General form uses nullspace directions of B.",
                diagnostics: diagnostics,
                steps: steps + [
                    "Solved B * c = x and found free variables.",
                    "General coordinate family: c = c0 + c_h where c_h is in Null(B)."
                ],
                reusablePayloads: payloads
            )
        }
    }

    private func analyzeNumericSpaces(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let spacesKind = request.spacesKind ?? .basisTestExtract

        switch spacesKind {
        case .basisTestExtract:
            return try numericSpacesBasisTestExtract(request)
        case .basisExtendPrune:
            return try numericSpacesBasisExtendPrune(request)
        case .subspaceSum:
            return try numericSpacesSubspaceSum(request)
        case .subspaceIntersection:
            return try numericSpacesSubspaceIntersection(request)
        case .directSumCheck:
            return try numericSpacesDirectSumCheck(request)
        }
    }

    private func numericSpacesBasisTestExtract(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let tolerance = 1.0e-9
        let generatingVectors = try parseBasisVectors(from: request)
        let dimension = generatingVectors[0].count
        let generatingMatrix = matrixFromColumnVectors(generatingVectors, rowCount: dimension)
        let rankSummary = rank(of: generatingMatrix, tolerance: tolerance)
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
            "Mode: Numeric (Double).",
            "Spaces workflow: basis test / extract.",
            "Tolerance: \(formattedScientific(tolerance)).",
            "Input vectors: \(generatingVectors.count).",
            "Ambient dimension: \(dimension).",
            "Rank(U): \(rankSummary.rank).",
            "Independent: \(isIndependent ? "yes" : "no").",
            "Spans R^\(dimension): \(spansAmbient ? "yes" : "no").",
            "Extracted basis: \(inlineBasis(extractedBasis))."
        ]
        if !isBasis {
            diagnostics.append("Basis test failed because \(isIndependent ? "span is insufficient" : "vectors are dependent at tolerance").")
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
                "Computed tolerance-aware RREF pivots: \(pivotDescription(rankSummary.pivotColumns)).",
                "Kept pivot columns as an extracted basis."
            ],
            reusablePayloads: payloads
        )
    }

    private func numericSpacesBasisExtendPrune(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let tolerance = 1.0e-9
        let generatingVectors = try parseBasisVectors(from: request)
        let dimension = generatingVectors[0].count
        let generatingMatrix = matrixFromColumnVectors(generatingVectors, rowCount: dimension)
        let rankSummary = rank(of: generatingMatrix, tolerance: tolerance)

        var extractedBasis = rankSummary.pivotColumns.map { generatingVectors[$0] }
        let prunedCount = max(0, generatingVectors.count - extractedBasis.count)
        var addedVectors: [[Double]] = []
        var steps: [String] = [
            "Built U with vectors as columns and reduced using tolerance-aware elimination.",
            "Pruned dependent vectors by retaining pivot columns: \(pivotDescription(rankSummary.pivotColumns))."
        ]

        if extractedBasis.count < dimension {
            for basisIndex in 0..<dimension where extractedBasis.count < dimension {
                let candidate = standardBasisVector(index: basisIndex, dimension: dimension)
                let trialVectors = extractedBasis + [candidate]
                let trialMatrix = matrixFromColumnVectors(trialVectors, rowCount: dimension)
                let trialRank = rank(of: trialMatrix, tolerance: tolerance).rank
                if trialRank > extractedBasis.count {
                    extractedBasis.append(candidate)
                    addedVectors.append(candidate)
                    steps.append("Added e\(basisIndex + 1) to increase rank to \(trialRank).")
                }
            }
        }

        let answer = "Pruned set to \(extractedBasis.count - addedVectors.count) independent vectors and extended to a basis of R^\(dimension) with \(addedVectors.count) added vectors."
        let diagnostics: [String] = [
            "Mode: Numeric (Double).",
            "Spaces workflow: basis extend / prune.",
            "Tolerance: \(formattedScientific(tolerance)).",
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

    private func numericSpacesSubspaceSum(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let tolerance = 1.0e-9
        let primaryVectors = try parseBasisVectors(from: request)
        let dimension = primaryVectors[0].count
        let secondaryVectors = try parseSecondaryBasisVectors(
            from: request,
            expectedDimension: dimension
        )
        let relation = numericSubspaceRelationSummary(
            primary: primaryVectors,
            secondary: secondaryVectors,
            tolerance: tolerance
        )

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
                "Mode: Numeric (Double).",
                "Spaces workflow: subspace sum.",
                "Tolerance: \(formattedScientific(tolerance)).",
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

    private func numericSpacesSubspaceIntersection(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let tolerance = 1.0e-9
        let primaryVectors = try parseBasisVectors(from: request)
        let dimension = primaryVectors[0].count
        let secondaryVectors = try parseSecondaryBasisVectors(
            from: request,
            expectedDimension: dimension
        )
        let relation = numericSubspaceRelationSummary(
            primary: primaryVectors,
            secondary: secondaryVectors,
            tolerance: tolerance
        )

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
                "Mode: Numeric (Double).",
                "Spaces workflow: subspace intersection.",
                "Tolerance: \(formattedScientific(tolerance)).",
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

    private func numericSpacesDirectSumCheck(
        _ request: MatrixMasterComputationRequest
    ) throws -> MatrixMasterComputationResult {
        let tolerance = 1.0e-9
        let primaryVectors = try parseBasisVectors(from: request)
        let dimension = primaryVectors[0].count
        let secondaryVectors = try parseSecondaryBasisVectors(
            from: request,
            expectedDimension: dimension
        )
        let relation = numericSubspaceRelationSummary(
            primary: primaryVectors,
            secondary: secondaryVectors,
            tolerance: tolerance
        )
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
                "Mode: Numeric (Double).",
                "Spaces workflow: direct sum check.",
                "Tolerance: \(formattedScientific(tolerance)).",
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

    private func operateNumericData(_ request: MatrixMasterComputationRequest) throws -> MatrixMasterComputationResult {
        let matrixA = try parseMatrixEntries(request.matrixEntries)
        let operation = try resolveOperateKind(for: request)

        switch operation {
        case .matrixAdd:
            let matrixB = try parseMatrixEntries(request.secondaryMatrixEntries)
            guard sameShape(matrixA, matrixB) else {
                throw MatrixNumericEngineError.operateDimensionMismatch
            }
            let result = zip(matrixA, matrixB).map { rowA, rowB in
                zip(rowA, rowB).map(+)
            }
            return MatrixMasterComputationResult(
                answer: "A + B = \(inlineMatrix(result))",
                diagnostics: ["Mode: Numeric.", "Operation: A + B."],
                steps: ["Added entries of A and B elementwise."],
                reusablePayloads: [
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(result),
                            source: "Operate A + B"
                        )
                    )
                ]
            )
        case .matrixSubtract:
            let matrixB = try parseMatrixEntries(request.secondaryMatrixEntries)
            guard sameShape(matrixA, matrixB) else {
                throw MatrixNumericEngineError.operateDimensionMismatch
            }
            let result = zip(matrixA, matrixB).map { rowA, rowB in
                zip(rowA, rowB).map(-)
            }
            return MatrixMasterComputationResult(
                answer: "A - B = \(inlineMatrix(result))",
                diagnostics: ["Mode: Numeric.", "Operation: A - B."],
                steps: ["Subtracted B from A elementwise."],
                reusablePayloads: [
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(result),
                            source: "Operate A - B"
                        )
                    )
                ]
            )
        case .matrixMultiply:
            let matrixB = try parseMatrixEntries(request.secondaryMatrixEntries)
            guard (matrixA.first?.count ?? 0) == matrixB.count else {
                throw MatrixNumericEngineError.operateDimensionMismatch
            }
            let result = multiply(matrixA, matrixB)
            return MatrixMasterComputationResult(
                answer: "A * B = \(inlineMatrix(result))",
                diagnostics: ["Mode: Numeric.", "Operation: A * B."],
                steps: ["Computed row-column dot products for A * B."],
                reusablePayloads: [
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(result),
                            source: "Operate A * B"
                        )
                    )
                ]
            )
        case .transpose:
            let result = transpose(matrixA)
            return MatrixMasterComputationResult(
                answer: "transpose(A) = \(inlineMatrix(result))",
                diagnostics: ["Mode: Numeric.", "Operation: transpose(A)."],
                steps: ["Swapped rows and columns of A."],
                reusablePayloads: [
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(result),
                            source: "Operate transpose(A)"
                        )
                    )
                ]
            )
        case .trace:
            guard matrixA.count == (matrixA.first?.count ?? 0) else {
                throw MatrixNumericEngineError.operateRequiresSquareMatrix
            }
            return MatrixMasterComputationResult(
                answer: "trace(A) ~= \(formatted(trace(of: matrixA)))",
                diagnostics: ["Mode: Numeric.", "Operation: trace(A)."],
                steps: ["Summed diagonal entries of A."]
            )
        case let .power(exponent):
            guard matrixA.count == (matrixA.first?.count ?? 0) else {
                throw MatrixNumericEngineError.operateRequiresSquareMatrix
            }
            let result = power(matrixA, exponent: exponent)
            return MatrixMasterComputationResult(
                answer: "A^\(exponent) = \(inlineMatrix(result))",
                diagnostics: ["Mode: Numeric.", "Operation: A^\(exponent)."],
                steps: ["Applied repeated multiplication to compute A^\(exponent)."],
                reusablePayloads: [
                    .matrix(
                        MatrixReusablePayload(
                            entries: stringify(result),
                            source: "Operate A^\(exponent)"
                        )
                    )
                ]
            )
        case .matrixVectorProduct:
            guard let vector = try parseVectorEntries(request.vectorEntries) else {
                throw MatrixNumericEngineError.missingVectorInput
            }
            guard (matrixA.first?.count ?? 0) == vector.count else {
                throw MatrixNumericEngineError.operateDimensionMismatch
            }
            let result = matrixVectorMultiply(matrixA, vector)
            return MatrixMasterComputationResult(
                answer: "A * v = [\(result.map(formatted).joined(separator: ", "))]",
                diagnostics: ["Mode: Numeric.", "Operation: A * v."],
                steps: ["Computed row dot products between A and v."],
                reusablePayloads: [
                    .vector(
                        VectorReusablePayload(
                            name: "Operate A*v",
                            entries: result.map(formatted),
                            source: "Operate A * v"
                        )
                    )
                ]
            )
        case .vectorAdd:
            guard let vectorU = try parseVectorEntries(request.secondaryVectorEntries),
                  let vectorV = try parseVectorEntries(request.vectorEntries) else {
                throw MatrixNumericEngineError.missingVectorInput
            }
            guard vectorU.count == vectorV.count else {
                throw MatrixNumericEngineError.operateDimensionMismatch
            }
            let result = zip(vectorU, vectorV).map(+)
            return MatrixMasterComputationResult(
                answer: "u + v = [\(result.map(formatted).joined(separator: ", "))]",
                diagnostics: ["Mode: Numeric.", "Operation: u + v."],
                steps: ["Added vectors component-wise."],
                reusablePayloads: [
                    .vector(
                        VectorReusablePayload(
                            name: "Operate u+v",
                            entries: result.map(formatted),
                            source: "Operate u + v"
                        )
                    )
                ]
            )
        case let .scalarVectorMultiply(scalar):
            guard let vectorV = try parseVectorEntries(request.vectorEntries) else {
                throw MatrixNumericEngineError.missingVectorInput
            }
            let result = vectorV.map { scalar * $0 }
            return MatrixMasterComputationResult(
                answer: "\(formatted(scalar)) * v = [\(result.map(formatted).joined(separator: ", "))]",
                diagnostics: ["Mode: Numeric.", "Operation: scalar-vector product."],
                steps: ["Scaled each vector component by \(formatted(scalar))."],
                reusablePayloads: [
                    .vector(
                        VectorReusablePayload(
                            name: "Operate s*v",
                            entries: result.map(formatted),
                            source: "Operate scalar * v"
                        )
                    )
                ]
            )
        }
    }

    private func parseMatrixEntries(_ rawEntries: [[String]]?) throws -> [[Double]] {
        guard let rawEntries else {
            throw MatrixNumericEngineError.missingMatrixInput
        }

        guard !rawEntries.isEmpty else {
            throw MatrixNumericEngineError.emptyMatrixInput
        }

        guard let firstRow = rawEntries.first else {
            throw MatrixNumericEngineError.emptyMatrixInput
        }

        guard !firstRow.isEmpty else {
            throw MatrixNumericEngineError.raggedMatrixInput
        }

        guard rawEntries.allSatisfy({ $0.count == firstRow.count }) else {
            throw MatrixNumericEngineError.raggedMatrixInput
        }

        var parsedMatrix: [[Double]] = []
        for (rowIndex, row) in rawEntries.enumerated() {
            var parsedRow: [Double] = []
            for (columnIndex, token) in row.enumerated() {
                guard let value = parseToken(token) else {
                    throw MatrixNumericEngineError.unsupportedToken(
                        row: rowIndex + 1,
                        column: columnIndex + 1,
                        token: token
                    )
                }
                parsedRow.append(value)
            }
            parsedMatrix.append(parsedRow)
        }

        return parsedMatrix
    }

    private func parseVectorEntries(_ entries: [String]?) throws -> [Double]? {
        guard let entries else {
            return nil
        }

        var parsed: [Double] = []
        for (index, token) in entries.enumerated() {
            guard let value = parseToken(token) else {
                throw MatrixNumericEngineError.unsupportedToken(
                    row: 1,
                    column: index + 1,
                    token: token
                )
            }
            parsed.append(value)
        }

        return parsed
    }

    private func parseBasisVectors(from request: MatrixMasterComputationRequest) throws -> [[Double]] {
        guard let rawBasisVectors = request.basisVectors, !rawBasisVectors.isEmpty else {
            throw MatrixNumericEngineError.analyzeRequiresBasisVectors
        }

        let expectedDimension = rawBasisVectors[0].count
        guard expectedDimension > 0 else {
            throw MatrixNumericEngineError.analyzeRequiresBasisVectors
        }

        var parsedVectors: [[Double]] = []
        for (vectorIndex, vectorTokens) in rawBasisVectors.enumerated() {
            guard vectorTokens.count == expectedDimension else {
                throw MatrixNumericEngineError.analyzeBasisDimensionMismatch(
                    expected: expectedDimension,
                    actual: vectorTokens.count,
                    vectorIndex: vectorIndex
                )
            }

            var parsedVector: [Double] = []
            for (entryIndex, token) in vectorTokens.enumerated() {
                guard let value = parseToken(token) else {
                    throw MatrixNumericEngineError.unsupportedToken(
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
    ) throws -> [[Double]] {
        guard let rawBasisVectors = request.secondaryBasisVectors, !rawBasisVectors.isEmpty else {
            throw MatrixNumericEngineError.spacesRequiresSecondaryBasisVectors
        }

        guard let first = rawBasisVectors.first else {
            throw MatrixNumericEngineError.spacesRequiresSecondaryBasisVectors
        }

        guard first.count == expectedDimension else {
            throw MatrixNumericEngineError.spacesBasisDimensionMismatch(
                expected: expectedDimension,
                actual: first.count
            )
        }

        var parsedVectors: [[Double]] = []
        for (vectorIndex, vectorTokens) in rawBasisVectors.enumerated() {
            guard vectorTokens.count == expectedDimension else {
                throw MatrixNumericEngineError.analyzeBasisDimensionMismatch(
                    expected: expectedDimension,
                    actual: vectorTokens.count,
                    vectorIndex: vectorIndex
                )
            }

            var parsedVector: [Double] = []
            for (entryIndex, token) in vectorTokens.enumerated() {
                guard let value = parseToken(token) else {
                    throw MatrixNumericEngineError.unsupportedToken(
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
    ) throws -> [Double] {
        guard let vector = try parseVectorEntries(request.vectorEntries) else {
            throw MatrixNumericEngineError.analyzeRequiresTargetVector
        }

        guard vector.count == expectedDimension else {
            throw MatrixNumericEngineError.analyzeTargetDimensionMismatch(
                expected: expectedDimension,
                actual: vector.count
            )
        }

        return vector
    }

    private func parseToken(_ token: String) -> Double? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if trimmed.contains("/") {
            let parts = trimmed.split(separator: "/", omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let numerator = Double(parts[0]),
                  let denominator = Double(parts[1]),
                  denominator != 0 else {
                return nil
            }

            return numerator / denominator
        }

        return Double(trimmed)
    }

    private func rank(of matrix: [[Double]], tolerance: Double) -> NumericRankSummary {
        var work = matrix
        let rowCount = matrix.count
        let columnCount = matrix[0].count
        var pivotRow = 0
        var pivotColumns: [Int] = []

        for column in 0..<columnCount where pivotRow < rowCount {
            let pivotCandidate = bestPivotRow(in: work, column: column, fromRow: pivotRow)
            guard let pivotRowIndex = pivotCandidate,
                  abs(work[pivotRowIndex][column]) > tolerance else {
                continue
            }

            if pivotRowIndex != pivotRow {
                work.swapAt(pivotRowIndex, pivotRow)
            }

            let pivotValue = work[pivotRow][column]
            for innerColumn in column..<columnCount {
                work[pivotRow][innerColumn] /= pivotValue
            }

            for row in 0..<rowCount where row != pivotRow {
                let factor = work[row][column]
                guard abs(factor) > tolerance else {
                    continue
                }

                for innerColumn in column..<columnCount {
                    work[row][innerColumn] -= factor * work[pivotRow][innerColumn]
                    if abs(work[row][innerColumn]) < tolerance {
                        work[row][innerColumn] = 0
                    }
                }
            }

            pivotColumns.append(column)
            pivotRow += 1
        }

        return NumericRankSummary(reduced: work, pivotColumns: pivotColumns)
    }

    private func determinant(of matrix: [[Double]], tolerance: Double) -> Double {
        let size = matrix.count
        guard size > 0 else {
            return 1
        }

        var work = matrix
        var swapCount = 0

        for column in 0..<size {
            let pivotCandidate = bestPivotRow(in: work, column: column, fromRow: column)
            guard let pivotRow = pivotCandidate,
                  abs(work[pivotRow][column]) > tolerance else {
                return 0
            }

            if pivotRow != column {
                work.swapAt(pivotRow, column)
                swapCount += 1
            }

            let pivot = work[column][column]
            for row in (column + 1)..<size {
                let factor = work[row][column] / pivot
                guard abs(factor) > tolerance else {
                    continue
                }

                for innerColumn in column..<size {
                    work[row][innerColumn] -= factor * work[column][innerColumn]
                }
            }
        }

        var determinant = 1.0
        for index in 0..<size {
            determinant *= work[index][index]
        }

        return swapCount.isMultiple(of: 2) ? determinant : -determinant
    }

    private func trace(of matrix: [[Double]]) -> Double {
        var total = 0.0
        for index in matrix.indices {
            total += matrix[index][index]
        }
        return total
    }

    private func luDecomposition(of matrix: [[Double]], tolerance: Double) -> NumericLUSummary {
        let size = matrix.count
        var lower = identityMatrix(size: size)
        var upper = matrix
        var permutation = Array(0..<size)
        var swapCount = 0

        for column in 0..<size {
            let pivotCandidate = bestPivotRow(in: upper, column: column, fromRow: column)
            guard let pivotRow = pivotCandidate,
                  abs(upper[pivotRow][column]) > tolerance else {
                return NumericLUSummary(
                    success: false,
                    lower: lower,
                    upper: upper,
                    permutation: permutation,
                    swapCount: swapCount
                )
            }

            if pivotRow != column {
                upper.swapAt(pivotRow, column)
                permutation.swapAt(pivotRow, column)

                for previousColumn in 0..<column {
                    let temporary = lower[column][previousColumn]
                    lower[column][previousColumn] = lower[pivotRow][previousColumn]
                    lower[pivotRow][previousColumn] = temporary
                }

                swapCount += 1
            }

            let pivot = upper[column][column]
            for row in (column + 1)..<size {
                let factor = upper[row][column] / pivot
                lower[row][column] = factor

                for innerColumn in column..<size {
                    upper[row][innerColumn] -= factor * upper[column][innerColumn]
                    if abs(upper[row][innerColumn]) < tolerance {
                        upper[row][innerColumn] = 0
                    }
                }
            }
        }

        return NumericLUSummary(
            success: true,
            lower: lower,
            upper: upper,
            permutation: permutation,
            swapCount: swapCount
        )
    }

    private func inverse(of matrix: [[Double]], tolerance: Double) -> NumericInverseSummary {
        let size = matrix.count
        var work = matrix
        var inverse = identityMatrix(size: size)
        var steps: [String] = []

        for column in 0..<size {
            guard let pivotRow = bestPivotRow(in: work, column: column, fromRow: column),
                  abs(work[pivotRow][column]) > tolerance else {
                steps.append("Column \(column + 1) has no stable pivot; inverse unavailable.")
                return NumericInverseSummary(inverse: nil, steps: steps)
            }

            if pivotRow != column {
                work.swapAt(pivotRow, column)
                inverse.swapAt(pivotRow, column)
                steps.append("R\(column + 1) <-> R\(pivotRow + 1)")
            }

            let pivot = work[column][column]
            for innerColumn in 0..<size {
                work[column][innerColumn] /= pivot
                inverse[column][innerColumn] /= pivot

                if abs(work[column][innerColumn]) < tolerance {
                    work[column][innerColumn] = 0
                }
                if abs(inverse[column][innerColumn]) < tolerance {
                    inverse[column][innerColumn] = 0
                }
            }
            steps.append("R\(column + 1) = (1/\(formatted(pivot))) * R\(column + 1)")

            for row in 0..<size where row != column {
                let factor = work[row][column]
                guard abs(factor) > tolerance else {
                    continue
                }

                for innerColumn in 0..<size {
                    work[row][innerColumn] -= factor * work[column][innerColumn]
                    inverse[row][innerColumn] -= factor * inverse[column][innerColumn]

                    if abs(work[row][innerColumn]) < tolerance {
                        work[row][innerColumn] = 0
                    }
                    if abs(inverse[row][innerColumn]) < tolerance {
                        inverse[row][innerColumn] = 0
                    }
                }

                steps.append("R\(row + 1) = R\(row + 1) + (\(formatted(-factor))) * R\(column + 1)")
            }
        }

        return NumericInverseSummary(inverse: inverse, steps: steps)
    }

    private func qrDecomposition(of matrix: [[Double]], tolerance: Double) -> NumericQRSummary {
        let rowCount = matrix.count
        let columnCount = matrix.first?.count ?? 0

        var q = Array(repeating: Array(repeating: 0.0, count: columnCount), count: rowCount)
        var r = Array(repeating: Array(repeating: 0.0, count: columnCount), count: columnCount)
        var orthonormalColumns: [[Double]] = []

        for column in 0..<columnCount {
            var work = matrix.map { $0[column] }

            for previousColumn in 0..<orthonormalColumns.count {
                let projection = dot(work, orthonormalColumns[previousColumn])
                r[previousColumn][column] = projection

                for row in 0..<rowCount {
                    work[row] -= projection * orthonormalColumns[previousColumn][row]
                }
            }

            let norm = sqrt(dot(work, work))
            if norm <= tolerance {
                return NumericQRSummary(success: false, q: q, r: r)
            }

            r[column][column] = norm
            let normalized = work.map { $0 / norm }
            orthonormalColumns.append(normalized)

            for row in 0..<rowCount {
                q[row][column] = normalized[row]
            }
        }

        return NumericQRSummary(success: true, q: q, r: r)
    }

    private func dominantEigenpair(of matrix: [[Double]], tolerance: Double) -> NumericEigenSummary {
        let size = matrix.count
        guard size > 0, size == (matrix.first?.count ?? 0) else {
            return NumericEigenSummary(eigenvalue: nil, eigenvector: nil, steps: [])
        }

        var vector = Array(repeating: 1.0 / sqrt(Double(size)), count: size)
        var previousEigenvalue = 0.0
        var steps: [String] = []

        for iteration in 1...120 {
            let next = matrixVectorMultiply(matrix, vector)
            let norm = sqrt(dot(next, next))
            guard norm > tolerance else {
                steps.append("Power iteration hit near-zero norm at step \(iteration).")
                return NumericEigenSummary(eigenvalue: nil, eigenvector: nil, steps: steps)
            }

            vector = next.map { $0 / norm }
            let transformed = matrixVectorMultiply(matrix, vector)
            let eigenvalue = dot(vector, transformed)

            if abs(eigenvalue - previousEigenvalue) < tolerance {
                steps.append("Power iteration converged after \(iteration) step(s).")
                return NumericEigenSummary(eigenvalue: eigenvalue, eigenvector: vector, steps: steps)
            }

            previousEigenvalue = eigenvalue
        }

        steps.append("Power iteration did not converge within 120 steps.")
        return NumericEigenSummary(eigenvalue: nil, eigenvector: nil, steps: steps)
    }

    private func singularValueSummary(of matrix: [[Double]], tolerance: Double) -> NumericSingularSummary {
        let transposeMatrix = transpose(matrix)
        let gram = multiply(transposeMatrix, matrix)
        guard !gram.isEmpty else {
            return NumericSingularSummary(sigmaMax: nil, singularValues: [])
        }

        var work = gram
        var singularValues: [Double] = []

        for _ in 0..<work.count {
            let eigen = dominantEigenpair(of: work, tolerance: tolerance)
            guard let eigenvalue = eigen.eigenvalue,
                  let eigenvector = eigen.eigenvector else {
                break
            }

            if eigenvalue <= tolerance {
                break
            }

            singularValues.append(sqrt(eigenvalue))

            for row in 0..<work.count {
                for column in 0..<work.count {
                    work[row][column] -= eigenvalue * eigenvector[row] * eigenvector[column]
                    if abs(work[row][column]) < tolerance {
                        work[row][column] = 0
                    }
                }
            }
        }

        singularValues.sort(by: >)
        return NumericSingularSummary(
            sigmaMax: singularValues.first,
            singularValues: singularValues
        )
    }

    private func resolveOperateKind(for request: MatrixMasterComputationRequest) throws -> NumericResolvedOperateKind {
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
            let scalar = request.scalarToken.flatMap(parseToken) ?? 2
            return .scalarVectorMultiply(scalar)
        case .expression:
            return try resolveOperateExpression(request.expression)
        }
    }

    private func resolveOperateExpression(_ expression: String?) throws -> NumericResolvedOperateKind {
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
            if let scalar = parseToken(scalarToken) {
                return .scalarVectorMultiply(scalar)
            }
        }

        throw MatrixNumericEngineError.unsupportedOperateExpression(rawExpression)
    }

    private func sameShape(_ lhs: [[Double]], _ rhs: [[Double]]) -> Bool {
        lhs.count == rhs.count && (lhs.first?.count ?? 0) == (rhs.first?.count ?? 0)
    }

    private func multiply(_ lhs: [[Double]], _ rhs: [[Double]]) -> [[Double]] {
        let rowCount = lhs.count
        let innerCount = lhs.first?.count ?? 0
        let columnCount = rhs.first?.count ?? 0
        var result = Array(repeating: Array(repeating: 0.0, count: columnCount), count: rowCount)

        for row in 0..<rowCount {
            for column in 0..<columnCount {
                var total = 0.0
                for inner in 0..<innerCount {
                    total += lhs[row][inner] * rhs[inner][column]
                }
                result[row][column] = total
            }
        }

        return result
    }

    private func transpose(_ matrix: [[Double]]) -> [[Double]] {
        let rowCount = matrix.count
        let columnCount = matrix.first?.count ?? 0
        var result = Array(repeating: Array(repeating: 0.0, count: rowCount), count: columnCount)

        for row in 0..<rowCount {
            for column in 0..<columnCount {
                result[column][row] = matrix[row][column]
            }
        }

        return result
    }

    private func power(_ matrix: [[Double]], exponent: Int) -> [[Double]] {
        guard exponent > 1 else {
            return matrix
        }

        var result = matrix
        for _ in 2...exponent {
            result = multiply(result, matrix)
        }
        return result
    }

    private func matrixVectorMultiply(_ matrix: [[Double]], _ vector: [Double]) -> [Double] {
        matrix.map { row in
            zip(row, vector).reduce(0.0) { partial, pair in
                partial + pair.0 * pair.1
            }
        }
    }

    private func dot(_ lhs: [Double], _ rhs: [Double]) -> Double {
        zip(lhs, rhs).reduce(0.0) { partial, pair in
            partial + pair.0 * pair.1
        }
    }

    private func bestPivotRow(in matrix: [[Double]], column: Int, fromRow: Int) -> Int? {
        guard fromRow < matrix.count else {
            return nil
        }

        var bestRow = fromRow
        var bestMagnitude = abs(matrix[fromRow][column])

        for row in (fromRow + 1)..<matrix.count {
            let candidateMagnitude = abs(matrix[row][column])
            if candidateMagnitude > bestMagnitude {
                bestMagnitude = candidateMagnitude
                bestRow = row
            }
        }

        return bestRow
    }

    private func identityMatrix(size: Int) -> [[Double]] {
        var matrix = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        for index in 0..<size {
            matrix[index][index] = 1
        }
        return matrix
    }

    private func classifySolve(
        matrix: [[Double]],
        variableCount: Int,
        pivotColumns: [Int],
        tolerance: Double
    ) -> NumericSolveClassification {
        for row in matrix {
            let allZeroCoefficients = row.prefix(variableCount).allSatisfy { abs($0) <= tolerance }
            if allZeroCoefficients && abs(row[variableCount]) > tolerance {
                return .inconsistent
            }
        }

        if pivotColumns.count == variableCount {
            let solution = extractUniqueSolution(
                from: matrix,
                variableCount: variableCount,
                pivotColumns: pivotColumns
            )
            return .unique(solution: solution)
        }

        let pivotColumnSet = Set(pivotColumns)
        let freeVariables = (0..<variableCount).filter { !pivotColumnSet.contains($0) }
        return .infinite(freeVariables: freeVariables)
    }

    private func extractUniqueSolution(
        from matrix: [[Double]],
        variableCount: Int,
        pivotColumns: [Int]
    ) -> [Double] {
        var solution = Array(repeating: 0.0, count: variableCount)

        for (rowIndex, pivotColumn) in pivotColumns.enumerated()
        where rowIndex < matrix.count && pivotColumn < variableCount {
            solution[pivotColumn] = matrix[rowIndex][variableCount]
        }

        return solution
    }

    private func solveNumericBasisSystem(
        basisVectors: [[Double]],
        targetVector: [Double],
        tolerance: Double
    ) -> NumericBasisSolveSummary {
        let variableCount = basisVectors.count
        let rowCount = targetVector.count
        var augmented = matrixFromColumnVectors(basisVectors, rowCount: rowCount)
        let augmentedColumnCount = variableCount + 1

        for row in 0..<rowCount {
            augmented[row].append(targetVector[row])
        }

        var work = augmented
        var pivotColumns: [Int] = []
        var pivotRow = 0

        for column in 0..<variableCount where pivotRow < rowCount {
            guard let rowWithPivot = bestPivotRow(in: work, column: column, fromRow: pivotRow),
                  abs(work[rowWithPivot][column]) > tolerance else {
                continue
            }

            if rowWithPivot != pivotRow {
                work.swapAt(rowWithPivot, pivotRow)
            }

            let pivot = work[pivotRow][column]
            for innerColumn in column..<augmentedColumnCount {
                work[pivotRow][innerColumn] /= pivot
                if abs(work[pivotRow][innerColumn]) < tolerance {
                    work[pivotRow][innerColumn] = 0
                }
            }

            for row in 0..<rowCount where row != pivotRow {
                let factor = work[row][column]
                guard abs(factor) > tolerance else {
                    continue
                }

                for innerColumn in column..<augmentedColumnCount {
                    work[row][innerColumn] -= factor * work[pivotRow][innerColumn]
                    if abs(work[row][innerColumn]) < tolerance {
                        work[row][innerColumn] = 0
                    }
                }
            }

            pivotColumns.append(column)
            pivotRow += 1
        }

        let classification = classifySolve(
            matrix: work,
            variableCount: variableCount,
            pivotColumns: pivotColumns,
            tolerance: tolerance
        )

        return NumericBasisSolveSummary(
            reducedAugmented: work,
            basisPivotColumns: pivotColumns,
            classification: classification
        )
    }

    private func particularSolution(
        from reducedAugmented: [[Double]],
        variableCount: Int,
        pivotColumns: [Int]
    ) -> [Double] {
        var solution = Array(repeating: 0.0, count: variableCount)

        for (pivotRow, pivotColumn) in pivotColumns.enumerated()
        where pivotRow < reducedAugmented.count {
            solution[pivotColumn] = reducedAugmented[pivotRow][variableCount]
        }

        return solution
    }

    private func formattedSolution(_ solution: [Double]) -> String {
        solution
            .enumerated()
            .map { "x\($0.offset + 1) ~= \(formatted($0.element))" }
            .joined(separator: ", ")
    }

    private func formattedCoefficients(_ coefficients: [Double]) -> String {
        coefficients
            .enumerated()
            .map { "c\($0.offset + 1) ~= \(formatted($0.element))" }
            .joined(separator: ", ")
    }

    private func formattedDependenceRelation(_ coefficients: [Double]) -> String {
        let terms = coefficients.enumerated().map { index, coefficient in
            "(\(formatted(coefficient))) * v\(index + 1)"
        }
        return "\(terms.joined(separator: " + ")) = 0"
    }

    private func buildSolveDiagnostics(
        classification: NumericSolveClassification,
        pivotColumns: [Int],
        variableCount: Int,
        tolerance: Double
    ) -> [String] {
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
            "Mode: Numeric (floating-point row-reduction).",
            "Unknowns: \(variableCount).",
            "Tolerance: \(formattedScientific(tolerance)).",
            "Pivot columns: \(pivotDescription(pivotColumns)).",
            "Classification: \(classificationDescription)."
        ]

        if case let .infinite(freeVariables) = classification {
            let freeDescription = freeVariables.map { "x\($0 + 1)" }.joined(separator: ", ")
            diagnostics.append("Free variables: \(freeDescription).")
        }

        return diagnostics
    }

    private func pivotDescription(_ pivotColumns: [Int]) -> String {
        if pivotColumns.isEmpty {
            return "none"
        }

        return pivotColumns.map { "c\($0 + 1)" }.joined(separator: ", ")
    }

    private func columnSpaceBasis(from matrix: [[Double]], pivotColumns: [Int]) -> [[Double]] {
        pivotColumns.map { pivotColumn in
            matrix.map { row in
                row[pivotColumn]
            }
        }
    }

    private func rowSpaceBasis(from reducedMatrix: [[Double]], tolerance: Double) -> [[Double]] {
        reducedMatrix.filter { row in
            row.contains { abs($0) > tolerance }
        }
    }

    private func nullSpaceBasis(
        from reducedMatrix: [[Double]],
        pivotColumns: [Int],
        columnCount: Int,
        tolerance: Double
    ) -> [[Double]] {
        let pivotSet = Set(pivotColumns)
        let freeColumns = (0..<columnCount).filter { !pivotSet.contains($0) }

        guard !freeColumns.isEmpty else {
            return []
        }

        var basis: [[Double]] = []

        for freeColumn in freeColumns {
            var vector = Array(repeating: 0.0, count: columnCount)
            vector[freeColumn] = 1.0

            for (pivotRow, pivotColumn) in pivotColumns.enumerated() where pivotRow < reducedMatrix.count {
                let coefficient = -reducedMatrix[pivotRow][freeColumn]
                vector[pivotColumn] = abs(coefficient) <= tolerance ? 0 : coefficient
            }

            basis.append(vector)
        }

        return basis
    }

    private func matrixFromColumnVectors(_ vectors: [[Double]], rowCount: Int) -> [[Double]] {
        guard !vectors.isEmpty else {
            return []
        }

        var matrix = Array(
            repeating: Array(repeating: 0.0, count: vectors.count),
            count: rowCount
        )

        for column in vectors.indices {
            for row in 0..<rowCount {
                matrix[row][column] = vectors[column][row]
            }
        }

        return matrix
    }

    private func standardBasisVector(index: Int, dimension: Int) -> [Double] {
        var vector = Array(repeating: 0.0, count: dimension)
        if index >= 0 && index < dimension {
            vector[index] = 1.0
        }
        return vector
    }

    private func linearCombination(
        of vectors: [[Double]],
        coefficients: [Double],
        dimension: Int,
        tolerance: Double
    ) -> [Double] {
        var result = Array(repeating: 0.0, count: dimension)
        for (columnIndex, coefficient) in coefficients.enumerated() where columnIndex < vectors.count {
            guard abs(coefficient) > tolerance else {
                continue
            }
            for row in 0..<dimension {
                result[row] += coefficient * vectors[columnIndex][row]
            }
        }
        for row in 0..<dimension where abs(result[row]) <= tolerance {
            result[row] = 0
        }
        return result
    }

    private func isZeroVector(_ vector: [Double], tolerance: Double) -> Bool {
        vector.allSatisfy { abs($0) <= tolerance }
    }

    private func numericSubspaceRelationSummary(
        primary primaryVectors: [[Double]],
        secondary secondaryVectors: [[Double]],
        tolerance: Double
    ) -> NumericSubspaceRelationSummary {
        let dimension = primaryVectors[0].count
        let primaryMatrix = matrixFromColumnVectors(primaryVectors, rowCount: dimension)
        let secondaryMatrix = matrixFromColumnVectors(secondaryVectors, rowCount: dimension)

        let primaryRank = rank(of: primaryMatrix, tolerance: tolerance).rank
        let secondaryRank = rank(of: secondaryMatrix, tolerance: tolerance).rank

        let combinedVectors = primaryVectors + secondaryVectors
        let combinedMatrix = matrixFromColumnVectors(combinedVectors, rowCount: dimension)
        let sumRankSummary = rank(of: combinedMatrix, tolerance: tolerance)
        let sumBasis = sumRankSummary.pivotColumns.map { combinedVectors[$0] }

        var matchingMatrix = primaryMatrix
        for row in 0..<dimension {
            matchingMatrix[row].append(contentsOf: secondaryMatrix[row].map(-))
        }
        let matchingSummary = rank(of: matchingMatrix, tolerance: tolerance)
        let nullCoefficients = nullSpaceBasis(
            from: matchingSummary.reduced,
            pivotColumns: matchingSummary.pivotColumns,
            columnCount: combinedVectors.count,
            tolerance: tolerance
        )

        var intersectionCandidates: [[Double]] = []
        for coefficientVector in nullCoefficients {
            let primaryCoefficients = Array(coefficientVector.prefix(primaryVectors.count))
            let candidate = linearCombination(
                of: primaryVectors,
                coefficients: primaryCoefficients,
                dimension: dimension,
                tolerance: tolerance
            )
            if !isZeroVector(candidate, tolerance: tolerance) {
                intersectionCandidates.append(candidate)
            }
        }

        let intersectionBasis: [[Double]]
        if intersectionCandidates.isEmpty {
            intersectionBasis = []
        } else {
            let candidateMatrix = matrixFromColumnVectors(intersectionCandidates, rowCount: dimension)
            let candidateSummary = rank(of: candidateMatrix, tolerance: tolerance)
            intersectionBasis = candidateSummary.pivotColumns.map { intersectionCandidates[$0] }
        }

        return NumericSubspaceRelationSummary(
            dimU: primaryRank,
            dimW: secondaryRank,
            dimSum: sumRankSummary.rank,
            dimIntersection: intersectionBasis.count,
            sumBasis: sumBasis,
            intersectionBasis: intersectionBasis
        )
    }

    private func inlineBasis(_ vectors: [[Double]]) -> String {
        guard !vectors.isEmpty else {
            return "{0}"
        }

        let vectorDescriptions = vectors.map { vector in
            "[\(vector.map(formatted).joined(separator: ", "))]"
        }
        return "{\(vectorDescriptions.joined(separator: ", "))}"
    }

    private func stringify(_ matrix: [[Double]]) -> [[String]] {
        matrix.map { row in
            row.map(formatted)
        }
    }

    private func inlineMatrix(_ matrix: [[Double]]) -> String {
        let rowDescriptions = matrix.map { row in
            "[\(row.map(formatted).joined(separator: ", "))]"
        }

        return "[\(rowDescriptions.joined(separator: ", "))]"
    }

    private func formatted(_ value: Double) -> String {
        if abs(value) < 1.0e-12 {
            return "0"
        }

        return String(format: "%.8g", value)
    }

    private func formattedScientific(_ value: Double) -> String {
        String(format: "%.1e", value)
    }
}

private struct NumericRankSummary {
    let reduced: [[Double]]
    let pivotColumns: [Int]

    var rank: Int {
        pivotColumns.count
    }
}

private struct NumericBasisSolveSummary {
    let reducedAugmented: [[Double]]
    let basisPivotColumns: [Int]
    let classification: NumericSolveClassification
}

private struct NumericSubspaceRelationSummary {
    let dimU: Int
    let dimW: Int
    let dimSum: Int
    let dimIntersection: Int
    let sumBasis: [[Double]]
    let intersectionBasis: [[Double]]
}

private struct NumericLUSummary {
    let success: Bool
    let lower: [[Double]]
    let upper: [[Double]]
    let permutation: [Int]
    let swapCount: Int
}

private struct NumericInverseSummary {
    let inverse: [[Double]]?
    let steps: [String]
}

private struct NumericQRSummary {
    let success: Bool
    let q: [[Double]]
    let r: [[Double]]
}

private struct NumericEigenSummary {
    let eigenvalue: Double?
    let eigenvector: [Double]?
    let steps: [String]
}

private struct NumericSingularSummary {
    let sigmaMax: Double?
    let singularValues: [Double]
}

private enum NumericResolvedOperateKind {
    case matrixAdd
    case matrixSubtract
    case matrixMultiply
    case transpose
    case trace
    case power(Int)
    case matrixVectorProduct
    case vectorAdd
    case scalarVectorMultiply(Double)
}

private enum NumericSolveClassification {
    case unique(solution: [Double])
    case infinite(freeVariables: [Int])
    case inconsistent

    var summaryStep: String {
        switch self {
        case .inconsistent:
            return "Detected a contradictory row at numeric tolerance, so the system is inconsistent."
        case let .infinite(freeVariables):
            let freeDescription = freeVariables.map { "x\($0 + 1)" }.joined(separator: ", ")
            return "At least one free variable remains (\(freeDescription)); solutions are parameterized."
        case .unique:
            return "Every variable has a pivot column at tolerance; the system has a unique solution."
        }
    }
}
