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
