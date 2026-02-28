# Task: Milestone B Solve + Reuse Baseline

## Goal
Ship the first concrete Milestone B vertical slice by replacing the Solve exact placeholder with a real REF/RREF flow and wiring the first result-reuse adapters across feature surfaces.

## Scope
- Implement exact Solve computation for augmented matrices with rational REF/RREF row reduction.
- Return row-operation trace, solution classification (unique/infinite/inconsistent), and Solve diagnostics.
- Emit typed reusable payloads from Solve results (coefficient matrix and unique-solution vector).
- Add feature-level reuse adapters to prefill Analyze/Operate inputs from Solve output payloads.
- Expose Solve diagnostics/steps/reuse actions in shared result surfaces and add reuse UI smoke assertions.

## Out of scope
- Full Milestone B feature inventory (Operate expression engine, determinant, inverse, rank/trace, LU/QR/SVD/eigen workflows, and full Library history/sync UI).
- Numeric decomposition implementations beyond existing placeholders.
- Production cloud transport/account integration.

## Affected modules
- MatrixDomain
- MatrixExact
- MatrixFeatures
- MatrixUI
- MatrixMasterMobileUITests
- MatrixMasterMacUITests

## Inputs / references
- `instructions.md`
- `docs/START_HERE.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/UX_SPEC.md`
- `docs/TEST_STRATEGY.md`
- `docs/session-logs/2026-02-28-milestone-a-closure-quality.md`

## Planned changes
- Extend domain request/result contracts to carry matrix inputs and typed reuse payloads.
- Replace the exact Solve placeholder with a rational row-reduction engine and classification output.
- Wire coordinator-level payload-application adapters for cross-destination prefill.
- Show answer, diagnostics, steps, and Solve reuse actions in the feature/result UI.
- Add unit coverage for unique/infinite/inconsistent Solve paths and reuse payload application.
- Add UI smoke checks for Solve reuse action exposure on mobile and Mac shells.

## Tests to add or update
- `Packages/MatrixExact/Tests/MatrixExactTests/MatrixExactTests.swift`
- `Packages/MatrixFeatures/Tests/MatrixFeaturesTests/MatrixFeaturesTests.swift`
- `Packages/MatrixDomain/Tests/MatrixDomainTests/MatrixDomainTests.swift`
- `Apps/MatrixMasterMobileUITests/MatrixMasterMobileUITests.swift`
- `Apps/MatrixMasterMacUITests/MatrixMasterMacUITests.swift`

## Docs to update
- `docs/tasks/TASK-0005-milestone-b-solve-reuse-baseline.md`
- `docs/ARCHITECTURE.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/FEATURE_MATRIX.md`
- `docs/START_HERE.md`
- `docs/session-logs/2026-02-28-milestone-b-solve-reuse-baseline.md`

## Acceptance criteria
- Exact Solve no longer returns placeholder text for Solve destination requests.
- Solve returns row-operation trace and classifies system as unique/infinite/inconsistent.
- Solve emits reusable matrix/vector payloads and feature adapters apply them into destination drafts.
- Solve UI surfaces diagnostics, steps, and explicit reuse actions.
- Updated package/UI tests cover Solve classification and reuse-path visibility.
- Milestone B remains in-progress overall; only this checkpoint is marked complete.

## Notes
This task establishes the first Milestone B checkpoint and intentionally does not claim full Milestone B completion.
