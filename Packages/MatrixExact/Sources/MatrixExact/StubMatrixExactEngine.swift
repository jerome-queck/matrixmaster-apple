import Foundation
import MatrixDomain

public enum MatrixExactEngineError: Error, Equatable {
    case nonExactModeRequest
}

public protocol MatrixExactComputing: Sendable {
    func compute(_ request: MatrixMasterComputationRequest) async throws -> MatrixMasterComputationResult
}

public struct StubMatrixExactEngine: MatrixExactComputing {
    public init() {}

    public func compute(_ request: MatrixMasterComputationRequest) async throws -> MatrixMasterComputationResult {
        guard request.mode == .exact else {
            throw MatrixExactEngineError.nonExactModeRequest
        }

        return MatrixMasterComputationResult(
            answer: "Exact placeholder result for \(request.destination.title)",
            diagnostics: ["Field assumptions will be surfaced per feature in later phases."],
            steps: ["Bootstrap exact lane shell executed."]
        )
    }
}
