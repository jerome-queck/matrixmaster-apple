import Foundation

public enum MatrixMasterDestination: String, CaseIterable, Codable, Identifiable, Sendable {
    case solve
    case operate
    case analyze
    case spaces
    case library

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .solve:
            return "Solve"
        case .operate:
            return "Operate"
        case .analyze:
            return "Analyze"
        case .spaces:
            return "Spaces"
        case .library:
            return "Library"
        }
    }

    public var systemImageName: String {
        switch self {
        case .solve:
            return "function"
        case .operate:
            return "plus.forwardslash.minus"
        case .analyze:
            return "chart.bar.doc.horizontal"
        case .spaces:
            return "square.stack.3d.up"
        case .library:
            return "books.vertical"
        }
    }
}

public enum MatrixMasterMathMode: String, CaseIterable, Codable, Sendable {
    case exact
    case numeric

    public var title: String {
        switch self {
        case .exact:
            return "Exact"
        case .numeric:
            return "Numeric"
        }
    }
}

public enum MatrixMasterSyncState: String, CaseIterable, Codable, Sendable {
    case localOnly
    case syncing
    case synced
    case needsAttention

    public var title: String {
        switch self {
        case .localOnly:
            return "Local Only"
        case .syncing:
            return "Syncing"
        case .synced:
            return "Synced"
        case .needsAttention:
            return "Needs Attention"
        }
    }
}

public struct MatrixReusablePayload: Equatable, Codable, Sendable {
    public var entries: [[String]]
    public var source: String

    public init(entries: [[String]], source: String) {
        self.entries = entries
        self.source = source
    }
}

public struct VectorReusablePayload: Equatable, Codable, Sendable {
    public var name: String
    public var entries: [String]
    public var source: String

    public init(name: String, entries: [String], source: String) {
        self.name = name
        self.entries = entries
        self.source = source
    }
}

public enum MatrixMasterReusablePayload: Equatable, Codable, Sendable {
    case matrix(MatrixReusablePayload)
    case vector(VectorReusablePayload)
}

public enum MatrixOperateKind: String, CaseIterable, Codable, Sendable {
    case matrixAdd
    case matrixSubtract
    case matrixMultiply
    case transpose
    case trace
    case power
    case matrixVectorProduct
    case vectorAdd
    case scalarVectorMultiply
    case expression

    public var title: String {
        switch self {
        case .matrixAdd:
            return "A + B"
        case .matrixSubtract:
            return "A - B"
        case .matrixMultiply:
            return "A * B"
        case .transpose:
            return "transpose(A)"
        case .trace:
            return "trace(A)"
        case .power:
            return "Aᵏ"
        case .matrixVectorProduct:
            return "A * v"
        case .vectorAdd:
            return "u + v"
        case .scalarVectorMultiply:
            return "s * v"
        case .expression:
            return "Expression"
        }
    }
}

public enum MatrixAnalyzeKind: String, CaseIterable, Codable, Sendable {
    case matrixProperties
    case spanMembership
    case independence
    case coordinates
    case linearMaps

    public var title: String {
        switch self {
        case .matrixProperties:
            return "Matrix Properties"
        case .spanMembership:
            return "Span Membership"
        case .independence:
            return "Independence"
        case .coordinates:
            return "Coordinate Vector"
        case .linearMaps:
            return "Linear Maps"
        }
    }
}

public struct MatrixAnalyzeMatrixPropertiesSelection: Equatable, Codable, Sendable {
    public var includeRankNullity: Bool
    public var includeColumnSpaceBasis: Bool
    public var includeRowSpaceBasis: Bool
    public var includeNullSpaceBasis: Bool
    public var includeDeterminant: Bool
    public var includeTrace: Bool
    public var includeInverse: Bool
    public var includeRowReductionPanels: Bool

    public init(
        includeRankNullity: Bool = true,
        includeColumnSpaceBasis: Bool = true,
        includeRowSpaceBasis: Bool = true,
        includeNullSpaceBasis: Bool = true,
        includeDeterminant: Bool = true,
        includeTrace: Bool = true,
        includeInverse: Bool = true,
        includeRowReductionPanels: Bool = true
    ) {
        self.includeRankNullity = includeRankNullity
        self.includeColumnSpaceBasis = includeColumnSpaceBasis
        self.includeRowSpaceBasis = includeRowSpaceBasis
        self.includeNullSpaceBasis = includeNullSpaceBasis
        self.includeDeterminant = includeDeterminant
        self.includeTrace = includeTrace
        self.includeInverse = includeInverse
        self.includeRowReductionPanels = includeRowReductionPanels
    }

    public static let all = MatrixAnalyzeMatrixPropertiesSelection()

    public var hasAnySelection: Bool {
        includeRankNullity
            || includeColumnSpaceBasis
            || includeRowSpaceBasis
            || includeNullSpaceBasis
            || includeDeterminant
            || includeTrace
            || includeInverse
            || includeRowReductionPanels
    }

    public var needsRREFComputation: Bool {
        includeRankNullity
            || includeColumnSpaceBasis
            || includeRowSpaceBasis
            || includeNullSpaceBasis
            || includeRowReductionPanels
    }

    public var needsSquareMetrics: Bool {
        includeDeterminant || includeTrace || includeInverse
    }
}

public struct MatrixSpacesOutputSelection: Equatable, Codable, Sendable {
    public var includeConclusion: Bool
    public var includeMathObjects: Bool
    public var includeDiagnostics: Bool
    public var includeSteps: Bool

    public init(
        includeConclusion: Bool = true,
        includeMathObjects: Bool = true,
        includeDiagnostics: Bool = true,
        includeSteps: Bool = true
    ) {
        self.includeConclusion = includeConclusion
        self.includeMathObjects = includeMathObjects
        self.includeDiagnostics = includeDiagnostics
        self.includeSteps = includeSteps
    }

    public static let all = MatrixSpacesOutputSelection()

    public var hasAnySelection: Bool {
        includeConclusion || includeMathObjects || includeDiagnostics || includeSteps
    }
}

public enum MatrixLinearMapDefinitionKind: String, CaseIterable, Codable, Sendable {
    case matrix
    case basisImages

    public var title: String {
        switch self {
        case .matrix:
            return "Define by Matrix"
        case .basisImages:
            return "Define by Basis Images"
        }
    }
}

public enum MatrixSpacesKind: String, CaseIterable, Codable, Sendable {
    case basisTestExtract
    case basisExtendPrune
    case subspaceSum
    case subspaceIntersection
    case directSumCheck

    public var title: String {
        switch self {
        case .basisTestExtract:
            return "Basis Test / Extract"
        case .basisExtendPrune:
            return "Basis Extend / Prune"
        case .subspaceSum:
            return "Subspace Sum (U + W)"
        case .subspaceIntersection:
            return "Subspace Intersection (U ∩ W)"
        case .directSumCheck:
            return "Direct Sum Check"
        }
    }
}

public enum MatrixSpacesPresetKind: String, CaseIterable, Codable, Sendable {
    case none
    case polynomialSpace
    case matrixSpace

    public var title: String {
        switch self {
        case .none:
            return "None"
        case .polynomialSpace:
            return "Polynomial Space Pₙ(F)"
        case .matrixSpace:
            return "Matrix Space Mₘ×ₙ(F)"
        }
    }
}

public struct MatrixMasterComputationRequest: Equatable, Codable, Sendable {
    public var destination: MatrixMasterDestination
    public var mode: MatrixMasterMathMode
    public var inputSummary: String
    public var matrixEntries: [[String]]?
    public var secondaryMatrixEntries: [[String]]?
    public var vectorEntries: [String]?
    public var secondaryVectorEntries: [String]?
    public var scalarToken: String?
    public var exponent: Int?
    public var operateKind: MatrixOperateKind?
    public var expression: String?
    public var basisVectors: [[String]]?
    public var secondaryBasisVectors: [[String]]?
    public var analyzeKind: MatrixAnalyzeKind?
    public var analyzeMatrixPropertiesSelection: MatrixAnalyzeMatrixPropertiesSelection?
    public var spacesKind: MatrixSpacesKind?
    public var spacesPresetKind: MatrixSpacesPresetKind?
    public var spacesOutputSelection: MatrixSpacesOutputSelection?
    public var spacesPolynomialDegree: Int?
    public var spacesMatrixRowCount: Int?
    public var spacesMatrixColumnCount: Int?
    public var linearMapDefinitionKind: MatrixLinearMapDefinitionKind?

    public init(
        destination: MatrixMasterDestination,
        mode: MatrixMasterMathMode,
        inputSummary: String,
        matrixEntries: [[String]]? = nil,
        secondaryMatrixEntries: [[String]]? = nil,
        vectorEntries: [String]? = nil,
        secondaryVectorEntries: [String]? = nil,
        scalarToken: String? = nil,
        exponent: Int? = nil,
        operateKind: MatrixOperateKind? = nil,
        expression: String? = nil,
        basisVectors: [[String]]? = nil,
        secondaryBasisVectors: [[String]]? = nil,
        analyzeKind: MatrixAnalyzeKind? = nil,
        analyzeMatrixPropertiesSelection: MatrixAnalyzeMatrixPropertiesSelection? = nil,
        spacesKind: MatrixSpacesKind? = nil,
        spacesPresetKind: MatrixSpacesPresetKind? = nil,
        spacesOutputSelection: MatrixSpacesOutputSelection? = nil,
        spacesPolynomialDegree: Int? = nil,
        spacesMatrixRowCount: Int? = nil,
        spacesMatrixColumnCount: Int? = nil,
        linearMapDefinitionKind: MatrixLinearMapDefinitionKind? = nil
    ) {
        self.destination = destination
        self.mode = mode
        self.inputSummary = inputSummary
        self.matrixEntries = matrixEntries
        self.secondaryMatrixEntries = secondaryMatrixEntries
        self.vectorEntries = vectorEntries
        self.secondaryVectorEntries = secondaryVectorEntries
        self.scalarToken = scalarToken
        self.exponent = exponent
        self.operateKind = operateKind
        self.expression = expression
        self.basisVectors = basisVectors
        self.secondaryBasisVectors = secondaryBasisVectors
        self.analyzeKind = analyzeKind
        self.analyzeMatrixPropertiesSelection = analyzeMatrixPropertiesSelection
        self.spacesKind = spacesKind
        self.spacesPresetKind = spacesPresetKind
        self.spacesOutputSelection = spacesOutputSelection
        self.spacesPolynomialDegree = spacesPolynomialDegree
        self.spacesMatrixRowCount = spacesMatrixRowCount
        self.spacesMatrixColumnCount = spacesMatrixColumnCount
        self.linearMapDefinitionKind = linearMapDefinitionKind
    }
}

public struct MatrixMathMatrixObject: Equatable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var label: String
    public var entries: [[String]]

    public init(
        id: UUID = UUID(),
        label: String,
        entries: [[String]]
    ) {
        self.id = id
        self.label = label
        self.entries = entries
    }
}

public struct MatrixMathVectorObject: Equatable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var label: String
    public var entries: [String]

    public init(
        id: UUID = UUID(),
        label: String,
        entries: [String]
    ) {
        self.id = id
        self.label = label
        self.entries = entries
    }
}

public struct MatrixMathPolynomialObject: Equatable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var label: String
    public var coefficients: [String]
    public var variableSymbol: String

    public init(
        id: UUID = UUID(),
        label: String,
        coefficients: [String],
        variableSymbol: String = "x"
    ) {
        self.id = id
        self.label = label
        self.coefficients = coefficients
        self.variableSymbol = variableSymbol
    }
}

public enum MatrixMathObject: Equatable, Codable, Sendable, Identifiable {
    case matrix(MatrixMathMatrixObject)
    case vector(MatrixMathVectorObject)
    case polynomial(MatrixMathPolynomialObject)

    public var id: UUID {
        switch self {
        case let .matrix(object):
            return object.id
        case let .vector(object):
            return object.id
        case let .polynomial(object):
            return object.id
        }
    }

    public var label: String {
        switch self {
        case let .matrix(object):
            return object.label
        case let .vector(object):
            return object.label
        case let .polynomial(object):
            return object.label
        }
    }
}

public enum MatrixMathExportFormat: String, CaseIterable, Codable, Sendable {
    case plain
    case markdown
    case latex
}

public enum MatrixMathExportFormatter {
    public static func format(_ object: MatrixMathObject, as format: MatrixMathExportFormat) -> String {
        switch format {
        case .plain:
            return plainText(for: object)
        case .markdown:
            return markdown(for: object)
        case .latex:
            return latex(for: object)
        }
    }

    public static func plainText(for object: MatrixMathObject) -> String {
        switch object {
        case let .matrix(matrix):
            return "\(matrix.label): \(inlineMatrix(matrix.entries))"
        case let .vector(vector):
            return "\(vector.label): [\(vector.entries.joined(separator: ", "))]"
        case let .polynomial(polynomial):
            return "\(polynomial.label): \(inlinePolynomial(coefficients: polynomial.coefficients, variable: polynomial.variableSymbol))"
        }
    }

    public static func markdown(for object: MatrixMathObject) -> String {
        switch object {
        case let .matrix(matrix):
            return "**\(matrix.label)**\n\n`\(inlineMatrix(matrix.entries))`"
        case let .vector(vector):
            return "**\(vector.label)**\n\n`[\(vector.entries.joined(separator: ", "))]`"
        case let .polynomial(polynomial):
            return "**\(polynomial.label)**\n\n`\(inlinePolynomial(coefficients: polynomial.coefficients, variable: polynomial.variableSymbol))`"
        }
    }

    public static func latex(for object: MatrixMathObject) -> String {
        switch object {
        case let .matrix(matrix):
            return "\(sanitizeLabelForLatex(matrix.label)) = \(latexMatrix(matrix.entries))"
        case let .vector(vector):
            return "\(sanitizeLabelForLatex(vector.label)) = \(latexColumnVector(vector.entries))"
        case let .polynomial(polynomial):
            return "\(sanitizeLabelForLatex(polynomial.label)) = \(latexPolynomial(coefficients: polynomial.coefficients, variable: polynomial.variableSymbol))"
        }
    }

    private static func inlineMatrix(_ entries: [[String]]) -> String {
        let rows = entries.map { row in
            "[\(row.joined(separator: ", "))]"
        }
        return "[\(rows.joined(separator: ", "))]"
    }

    private static func inlinePolynomial(coefficients: [String], variable: String) -> String {
        let trimmed = coefficients.map(cleanToken)
        guard !trimmed.isEmpty else {
            return "0"
        }

        var terms: [String] = []
        for power in trimmed.indices.reversed() {
            let coefficient = trimmed[power]
            guard coefficient != "0" else {
                continue
            }

            switch power {
            case 0:
                terms.append(coefficient)
            case 1:
                if coefficient == "1" {
                    terms.append(variable)
                } else if coefficient == "-1" {
                    terms.append("-\(variable)")
                } else {
                    terms.append("\(coefficient)\(variable)")
                }
            default:
                if coefficient == "1" {
                    terms.append("\(variable)^\(power)")
                } else if coefficient == "-1" {
                    terms.append("-\(variable)^\(power)")
                } else {
                    terms.append("\(coefficient)\(variable)^\(power)")
                }
            }
        }

        if terms.isEmpty {
            return "0"
        }

        return terms.enumerated().map { index, term in
            if index == 0 {
                return term
            }

            if term.hasPrefix("-") {
                return "- \(term.dropFirst())"
            }
            return "+ \(term)"
        }.joined(separator: " ")
    }

    private static func latexMatrix(_ entries: [[String]]) -> String {
        let rows = entries.map { row in
            row.map(latexToken).joined(separator: " & ")
        }.joined(separator: #" \\ "#)
        return #"\begin{bmatrix} "# + rows + #" \end{bmatrix}"#
    }

    private static func latexColumnVector(_ entries: [String]) -> String {
        let rows = entries.map(latexToken).joined(separator: #" \\ "#)
        return #"\begin{bmatrix} "# + rows + #" \end{bmatrix}"#
    }

    private static func latexPolynomial(coefficients: [String], variable: String) -> String {
        let cleanedVariable = sanitizeVariable(variable)
        guard !coefficients.isEmpty else {
            return "0"
        }

        var terms: [String] = []
        for power in coefficients.indices.reversed() {
            let rawCoefficient = cleanToken(coefficients[power])
            guard rawCoefficient != "0" else {
                continue
            }

            let coefficient = latexToken(rawCoefficient)
            switch power {
            case 0:
                terms.append(coefficient)
            case 1:
                if rawCoefficient == "1" {
                    terms.append(cleanedVariable)
                } else if rawCoefficient == "-1" {
                    terms.append("-\(cleanedVariable)")
                } else {
                    terms.append("\(coefficient)\(cleanedVariable)")
                }
            default:
                if rawCoefficient == "1" {
                    terms.append("\(cleanedVariable)^{\(power)}")
                } else if rawCoefficient == "-1" {
                    terms.append("-\(cleanedVariable)^{\(power)}")
                } else {
                    terms.append("\(coefficient)\(cleanedVariable)^{\(power)}")
                }
            }
        }

        if terms.isEmpty {
            return "0"
        }

        return terms.enumerated().map { index, term in
            if index == 0 {
                return term
            }
            if term.hasPrefix("-") {
                return "- " + term.dropFirst()
            }
            return "+ \(term)"
        }.joined(separator: " ")
    }

    private static func latexToken(_ token: String) -> String {
        let cleaned = cleanToken(token)
        if cleaned.contains("/") {
            let parts = cleaned.split(separator: "/", omittingEmptySubsequences: false)
            if parts.count == 2, !parts[1].isEmpty {
                let numerator = String(parts[0])
                let denominator = String(parts[1])
                return #"\frac{"# + numerator + "}{" + denominator + "}"
            }
        }
        return cleaned
    }

    private static func cleanToken(_ token: String) -> String {
        token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func sanitizeLabelForLatex(_ label: String) -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "x"
        }

        return trimmed.replacingOccurrences(of: " ", with: #"\ "#)
    }

    private static func sanitizeVariable(_ variable: String) -> String {
        let trimmed = variable.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "x" : trimmed
    }
}

public struct MatrixRowReductionPanels: Equatable, Codable, Sendable {
    public var sourceLabel: String
    public var refEntries: [[String]]
    public var rrefEntries: [[String]]
    public var separatorAfterColumn: Int?

    public init(
        sourceLabel: String,
        refEntries: [[String]],
        rrefEntries: [[String]],
        separatorAfterColumn: Int? = nil
    ) {
        self.sourceLabel = sourceLabel
        self.refEntries = refEntries
        self.rrefEntries = rrefEntries
        self.separatorAfterColumn = separatorAfterColumn
    }
}

public struct MatrixMasterComputationResult: Equatable, Codable, Sendable {
    public var answer: String
    public var diagnostics: [String]
    public var steps: [String]
    public var reusablePayloads: [MatrixMasterReusablePayload]
    public var structuredObjects: [MatrixMathObject]
    public var rowReductionPanels: MatrixRowReductionPanels?

    public init(
        answer: String,
        diagnostics: [String],
        steps: [String],
        reusablePayloads: [MatrixMasterReusablePayload] = [],
        structuredObjects: [MatrixMathObject] = [],
        rowReductionPanels: MatrixRowReductionPanels? = nil
    ) {
        self.answer = answer
        self.diagnostics = diagnostics
        self.steps = steps
        self.reusablePayloads = reusablePayloads
        self.structuredObjects = structuredObjects
        self.rowReductionPanels = rowReductionPanels
    }
}

public struct MatrixMasterShellSnapshot: Equatable, Codable, Sendable {
    public var selectedDestination: MatrixMasterDestination
    public var selectedMode: MatrixMasterMathMode
    public var updatedAt: Date

    public init(
        selectedDestination: MatrixMasterDestination,
        selectedMode: MatrixMasterMathMode,
        updatedAt: Date
    ) {
        self.selectedDestination = selectedDestination
        self.selectedMode = selectedMode
        self.updatedAt = updatedAt
    }
}

public struct MatrixLibraryVectorItem: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var entries: [String]
    public var savedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        entries: [String],
        savedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.entries = entries
        self.savedAt = savedAt
    }
}

public struct MatrixLibraryHistoryEntry: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var title: String
    public var detail: String
    public var recordedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.recordedAt = recordedAt
    }
}

public struct MatrixLibrarySnapshot: Equatable, Codable, Sendable {
    public var vectors: [MatrixLibraryVectorItem]
    public var history: [MatrixLibraryHistoryEntry]
    public var updatedAt: Date

    public init(
        vectors: [MatrixLibraryVectorItem] = [],
        history: [MatrixLibraryHistoryEntry] = [],
        updatedAt: Date = Date()
    ) {
        self.vectors = vectors
        self.history = history
        self.updatedAt = updatedAt
    }
}

public struct MatrixDimensions: Equatable, Codable, Sendable {
    public var rows: Int
    public var columns: Int

    public init(rows: Int, columns: Int) {
        self.rows = max(1, rows)
        self.columns = max(1, columns)
    }
}

public enum MatrixInputValidationError: Error, Equatable, LocalizedError, Sendable {
    case emptyMatrixEntry(row: Int, column: Int)
    case invalidMatrixEntry(row: Int, column: Int, value: String)
    case zeroDenominatorMatrixEntry(row: Int, column: Int, value: String)
    case emptyVectorEntry(vectorIndex: Int, entryIndex: Int)
    case invalidVectorEntry(vectorIndex: Int, entryIndex: Int, value: String)
    case zeroDenominatorVectorEntry(vectorIndex: Int, entryIndex: Int, value: String)
    case basisRequiresAtLeastOneVector
    case inconsistentVectorLength(expected: Int, actual: Int, vectorIndex: Int)

    public var errorDescription: String? {
        switch self {
        case let .emptyMatrixEntry(row, column):
            return "Entry (\(row), \(column)) is empty."
        case let .invalidMatrixEntry(row, column, value):
            return "Entry (\(row), \(column)) is not a valid integer, fraction, or decimal: \(value)."
        case let .zeroDenominatorMatrixEntry(row, column, value):
            return "Entry (\(row), \(column)) has a zero denominator: \(value)."
        case let .emptyVectorEntry(vectorIndex, entryIndex):
            return "Vector \(vectorIndex + 1), entry \(entryIndex + 1) is empty."
        case let .invalidVectorEntry(vectorIndex, entryIndex, value):
            return "Vector \(vectorIndex + 1), entry \(entryIndex + 1) is not valid: \(value)."
        case let .zeroDenominatorVectorEntry(vectorIndex, entryIndex, value):
            return "Vector \(vectorIndex + 1), entry \(entryIndex + 1) has a zero denominator: \(value)."
        case .basisRequiresAtLeastOneVector:
            return "A basis requires at least one vector."
        case let .inconsistentVectorLength(expected, actual, vectorIndex):
            return "Vector \(vectorIndex + 1) has length \(actual), expected \(expected)."
        }
    }
}

public enum MatrixInputTokenIssue: Equatable, Sendable {
    case empty
    case invalid
    case zeroDenominator
}

public enum MatrixInputTokenValidator {
    public static func issue(for token: String) -> MatrixInputTokenIssue? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .empty
        }

        if trimmed.contains("/") {
            return validateFraction(trimmed)
        }

        if Int(trimmed) != nil {
            return nil
        }

        if Double(trimmed) != nil {
            return nil
        }

        return .invalid
    }

    private static func validateFraction(_ token: String) -> MatrixInputTokenIssue? {
        let parts = token.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let numerator = Int(parts[0]),
              let denominator = Int(parts[1]) else {
            return .invalid
        }

        _ = numerator
        return denominator == 0 ? .zeroDenominator : nil
    }
}

public struct MatrixDraftInput: Equatable, Codable, Sendable {
    public private(set) var rows: Int
    public private(set) var columns: Int
    public private(set) var entries: [[String]]

    public init(rows: Int = 3, columns: Int = 3, fillWith value: String = "0") {
        let safeRows = max(1, rows)
        let safeColumns = max(1, columns)

        self.rows = safeRows
        self.columns = safeColumns
        self.entries = Array(
            repeating: Array(repeating: value, count: safeColumns),
            count: safeRows
        )
    }

    public init(entries: [[String]], fillMissingWith value: String = "0") {
        let safeEntries = entries.isEmpty ? [[value]] : entries
        let rowCount = safeEntries.count
        let columnCount = max(1, safeEntries.map(\.count).max() ?? 1)

        self.rows = rowCount
        self.columns = columnCount
        self.entries = safeEntries.map { row in
            if row.count == columnCount {
                return row
            }

            if row.count > columnCount {
                return Array(row.prefix(columnCount))
            }

            return row + Array(repeating: value, count: columnCount - row.count)
        }
    }

    public var dimensions: MatrixDimensions {
        MatrixDimensions(rows: rows, columns: columns)
    }

    public func value(atRow row: Int, column: Int) -> String {
        guard row >= 0, row < rows, column >= 0, column < columns else {
            return ""
        }

        return entries[row][column]
    }

    public mutating func setValue(_ value: String, row: Int, column: Int) {
        guard row >= 0, row < rows, column >= 0, column < columns else {
            return
        }

        entries[row][column] = value
    }

    public mutating func addRow(fillWith value: String = "0") {
        entries.append(Array(repeating: value, count: columns))
        rows += 1
    }

    public mutating func removeLastRow() {
        guard rows > 1 else {
            return
        }

        entries.removeLast()
        rows -= 1
    }

    public mutating func addColumn(fillWith value: String = "0") {
        for rowIndex in entries.indices {
            entries[rowIndex].append(value)
        }
        columns += 1
    }

    public mutating func removeLastColumn() {
        guard columns > 1 else {
            return
        }

        for rowIndex in entries.indices {
            entries[rowIndex].removeLast()
        }
        columns -= 1
    }

    public func validatedEntries() throws -> [[String]] {
        for rowIndex in entries.indices {
            for columnIndex in entries[rowIndex].indices {
                let rawValue = entries[rowIndex][columnIndex]
                if let issue = MatrixInputTokenValidator.issue(for: rawValue) {
                    switch issue {
                    case .empty:
                        throw MatrixInputValidationError.emptyMatrixEntry(
                            row: rowIndex + 1,
                            column: columnIndex + 1
                        )
                    case .invalid:
                        throw MatrixInputValidationError.invalidMatrixEntry(
                            row: rowIndex + 1,
                            column: columnIndex + 1,
                            value: rawValue
                        )
                    case .zeroDenominator:
                        throw MatrixInputValidationError.zeroDenominatorMatrixEntry(
                            row: rowIndex + 1,
                            column: columnIndex + 1,
                            value: rawValue
                        )
                    }
                }
            }
        }

        return entries
    }
}

public struct VectorDraftInput: Equatable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public private(set) var entries: [String]

    public init(id: UUID = UUID(), name: String = "", entries: [String] = ["0", "0", "0"]) {
        self.id = id
        self.name = name
        self.entries = entries.isEmpty ? ["0"] : entries
    }

    public var dimension: Int { entries.count }

    public mutating func setValue(_ value: String, at index: Int) {
        guard index >= 0, index < entries.count else {
            return
        }

        entries[index] = value
    }

    public mutating func appendEntry(defaultValue: String = "0") {
        entries.append(defaultValue)
    }

    public mutating func removeLastEntry() {
        guard entries.count > 1 else {
            return
        }

        entries.removeLast()
    }

    public mutating func resize(to dimension: Int, fillWith value: String = "0") {
        let safeDimension = max(1, dimension)

        if entries.count < safeDimension {
            entries.append(contentsOf: Array(repeating: value, count: safeDimension - entries.count))
        } else if entries.count > safeDimension {
            entries = Array(entries.prefix(safeDimension))
        }
    }

    public func validatedEntries(vectorIndex: Int) throws -> [String] {
        for entryIndex in entries.indices {
            let rawValue = entries[entryIndex]
            if let issue = MatrixInputTokenValidator.issue(for: rawValue) {
                switch issue {
                case .empty:
                    throw MatrixInputValidationError.emptyVectorEntry(
                        vectorIndex: vectorIndex,
                        entryIndex: entryIndex
                    )
                case .invalid:
                    throw MatrixInputValidationError.invalidVectorEntry(
                        vectorIndex: vectorIndex,
                        entryIndex: entryIndex,
                        value: rawValue
                    )
                case .zeroDenominator:
                    throw MatrixInputValidationError.zeroDenominatorVectorEntry(
                        vectorIndex: vectorIndex,
                        entryIndex: entryIndex,
                        value: rawValue
                    )
                }
            }
        }

        return entries
    }
}

public struct BasisDraftInput: Equatable, Codable, Sendable {
    public var name: String
    public private(set) var vectors: [VectorDraftInput]

    public init(name: String = "Basis", vectors: [VectorDraftInput] = [
        VectorDraftInput(name: "v1"),
        VectorDraftInput(name: "v2")
    ]) {
        self.name = name

        if vectors.isEmpty {
            self.vectors = [VectorDraftInput(name: "v1")]
        } else {
            self.vectors = vectors
        }
    }

    public var vectorCount: Int { vectors.count }

    public var dimension: Int {
        vectors.first?.dimension ?? 1
    }

    public mutating func addVector(named name: String? = nil) {
        let nextIndex = vectors.count + 1
        let vector = VectorDraftInput(
            name: name ?? "v\(nextIndex)",
            entries: Array(repeating: "0", count: dimension)
        )
        vectors.append(vector)
    }

    public mutating func removeLastVector() {
        guard vectors.count > 1 else {
            return
        }

        vectors.removeLast()
    }

    public mutating func updateVector(_ vector: VectorDraftInput, at index: Int) {
        guard index >= 0, index < vectors.count else {
            return
        }

        let previousDimension = dimension
        var updated = vector
        let newDimension = max(1, updated.dimension)
        updated.resize(to: newDimension)
        vectors[index] = updated

        if newDimension != previousDimension {
            alignVectors(to: newDimension)
        }
    }

    public mutating func alignVectors(to dimension: Int) {
        let safeDimension = max(1, dimension)

        for index in vectors.indices {
            vectors[index].resize(to: safeDimension)
        }
    }

    public mutating func increaseDimension(by increment: Int = 1) {
        alignVectors(to: dimension + max(1, increment))
    }

    public mutating func decreaseDimension(by decrement: Int = 1) {
        alignVectors(to: max(1, dimension - max(1, decrement)))
    }

    public func validatedVectors() throws -> [[String]] {
        guard !vectors.isEmpty else {
            throw MatrixInputValidationError.basisRequiresAtLeastOneVector
        }

        let expectedLength = vectors[0].dimension
        var validated: [[String]] = []

        for (vectorIndex, vector) in vectors.enumerated() {
            guard vector.dimension == expectedLength else {
                throw MatrixInputValidationError.inconsistentVectorLength(
                    expected: expectedLength,
                    actual: vector.dimension,
                    vectorIndex: vectorIndex
                )
            }

            validated.append(try vector.validatedEntries(vectorIndex: vectorIndex))
        }

        return validated
    }

}
