import XCTest
import MatrixDomain
@testable import MatrixNumeric

final class MatrixNumericTests: XCTestCase {
    func testNumericEngineAcceptsNumericMode() async throws {
        let engine = StubMatrixNumericEngine()
        let request = MatrixMasterComputationRequest(
            destination: .analyze,
            mode: .numeric,
            inputSummary: "Sample"
        )

        let result = try await engine.compute(request)
        XCTAssertTrue(result.answer.contains("Numeric"))
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
