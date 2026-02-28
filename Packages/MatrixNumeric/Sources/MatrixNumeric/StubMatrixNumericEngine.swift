import Foundation
import MatrixDomain

public enum MatrixNumericEngineError: Error, Equatable {
    case nonNumericModeRequest
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

        return MatrixMasterComputationResult(
            answer: "Numeric placeholder result for \(request.destination.title)",
            diagnostics: ["Tolerance and residual diagnostics will be added in numeric workflows."],
            steps: ["Bootstrap numeric lane shell executed."]
        )
    }
}
