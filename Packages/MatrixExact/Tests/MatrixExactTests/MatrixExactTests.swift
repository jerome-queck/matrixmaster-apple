import XCTest
import MatrixDomain
@testable import MatrixExact

final class MatrixExactTests: XCTestCase {
    func testExactEngineAcceptsExactMode() async throws {
        let engine = StubMatrixExactEngine()
        let request = MatrixMasterComputationRequest(
            destination: .solve,
            mode: .exact,
            inputSummary: "Sample"
        )

        let result = try await engine.compute(request)
        XCTAssertTrue(result.answer.contains("Exact"))
    }

    func testExactEngineRejectsNumericMode() async {
        let engine = StubMatrixExactEngine()
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
