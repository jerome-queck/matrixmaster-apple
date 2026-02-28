import Foundation

public enum MatrixMasterDestination: String, CaseIterable, Codable, Identifiable, Sendable {
    case solve
    case operate
    case analyze
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

public struct MatrixMasterComputationRequest: Equatable, Codable, Sendable {
    public var destination: MatrixMasterDestination
    public var mode: MatrixMasterMathMode
    public var inputSummary: String

    public init(destination: MatrixMasterDestination, mode: MatrixMasterMathMode, inputSummary: String) {
        self.destination = destination
        self.mode = mode
        self.inputSummary = inputSummary
    }
}

public struct MatrixMasterComputationResult: Equatable, Codable, Sendable {
    public var answer: String
    public var diagnostics: [String]
    public var steps: [String]

    public init(answer: String, diagnostics: [String], steps: [String]) {
        self.answer = answer
        self.diagnostics = diagnostics
        self.steps = steps
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

        var updated = vector
        updated.resize(to: dimension)
        vectors[index] = updated
    }

    public mutating func alignVectors(to dimension: Int) {
        let safeDimension = max(1, dimension)

        for index in vectors.indices {
            vectors[index].resize(to: safeDimension)
        }
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
