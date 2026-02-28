# Task: Milestone B Analyze + Numeric + Reuse Checkpoint

## Goal
Ship the next Milestone B checkpoint by adding Analyze math baselines, expanding numeric coverage beyond placeholders, and broadening reuse actions while keeping destination semantics clear.

## Scope
- Clarify Solve augmented input UX (explicit solution-vector column, homogeneous toggle, coefficient-only dimension display).
- Add quick randomize controls for Operate and Analyze matrix editors.
- Implement exact Analyze baseline for determinant, rank, trace, and inverse availability.
- Implement numeric Analyze baseline for rank, trace, determinant, and LU-factor summary diagnostics.
- Expand reusable payload coverage and reuse action routing across Solve/Analyze/Operate/Library where payload type matches.

## Out of scope
- Full Operate expression engine.
- Complete Analyze inventory (null-space bases, eigen workflows, QR/SVD, etc.).
- Library persistence promotion and history/sync UI completion.

## Affected modules
- MatrixUI
- MatrixFeatures
- MatrixExact
- MatrixNumeric
- MatrixMasterMobileUITests
- MatrixMasterMacUITests

## Inputs / references
- `instructions.md`
- `docs/START_HERE.md`
- `docs/ARCHITECTURE.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/FEATURE_MATRIX.md`
- `docs/UX_SPEC.md`
- `docs/TEST_STRATEGY.md`
- `docs/tasks/TASK-0005-milestone-b-solve-reuse-baseline.md`

## Planned changes
- Route Solve to `AugmentedSystemEditorView`.
- Keep Operate/Analyze on `MatrixGridEditorView` with randomize enabled.
- Generalize reuse action UI so payloads can route to multiple compatible destinations.
- Extend exact engine with Analyze computation path (det/rank/trace/inverse status).
- Extend numeric engine with Analyze computation path (det/rank/trace/LU summary + tolerance diagnostics).
- Add/adjust tests for editor surface controls, Analyze outputs, and cross-destination reuse behavior.

## Tests to add or update
- `Packages/MatrixUI/Tests/MatrixUITests/MatrixUITests.swift`
- `Packages/MatrixExact/Tests/MatrixExactTests/MatrixExactTests.swift`
- `Packages/MatrixNumeric/Tests/MatrixNumericTests/MatrixNumericTests.swift`
- `Packages/MatrixFeatures/Tests/MatrixFeaturesTests/MatrixFeaturesTests.swift`
- `Apps/MatrixMasterMobileUITests/MatrixMasterMobileUITests.swift`
- `Apps/MatrixMasterMacUITests/MatrixMasterMacUITests.swift`

## Docs to update
- `docs/START_HERE.md`
- `docs/FEATURE_MATRIX.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK-0006-milestone-b-analyze-numeric-reuse.md`
- `docs/session-logs/2026-02-28-milestone-b-analyze-numeric-reuse.md`

## Acceptance criteria
- Solve clearly distinguishes coefficients vs solution vector and supports homogeneous toggle.
- Operate and Analyze expose randomize matrix controls.
- Exact Analyze returns determinant/rank/trace and inverse availability summary for square matrices.
- Numeric Analyze returns rank/trace/determinant summary and LU decomposition diagnostics for square matrices.
- Reuse actions appear when reusable payloads exist and route to compatible destinations (including Library for vector payloads).
- Updated package tests and scheme tests pass on iPhone, iPad, and macOS.
