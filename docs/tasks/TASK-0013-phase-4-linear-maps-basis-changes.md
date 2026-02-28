# Task: Phase 4 Linear Maps and Basis Changes

## Goal
Deliver Phase 4 end-to-end by shipping linear-map workflows (matrix/basis-image definitions through similarity diagnostics) and closing the scheduled Phase 3 carry-over polish items (full coordinate-family diagnostics and baseline math typography rendering).

## Scope
- Extend domain contracts and request routing for Analyze linear-map workflows.
- Add Analyze linear-map workflow controls in shared feature/UI surfaces, including map definition mode selection.
- Implement exact and numeric linear-map computations for:
  - define-by-matrix
  - define-by-basis-images
  - kernel/range basis witnesses
  - rank/nullity and injective/surjective/bijective decisions
  - basis-relative matrix representations (`[T]^beta_gamma`)
  - change-of-coordinates matrices for compatible basis pairs
  - similarity diagnostics from basis change, including trace/determinant invariant reporting
- Upgrade coordinate-family diagnostics to emit full family parameterizations and all nullspace-basis directions as reusable payloads.
- Apply baseline math typography rendering upgrades across shared result surfaces.
- Add abstract-space preset templates for Spaces workflows (polynomial and matrix-space canonical basis scaffolds).
- Improve linear-map similarity diagnostics for incompatible/non-endomorphism basis input with explicit not-applicable guidance.
- Update roadmap/status/spec/matrix/task/session docs to close Phase 4 at a clean checkpoint.

## Out of scope
- Phase 5 orthogonality and least-squares workflows.
- Advanced canonical-form workflows (minimal polynomial/Jordan).
- Broad redesign of app shells/navigation beyond Analyze workflow additions.

## Affected modules
- MatrixDomain
- MatrixExact
- MatrixNumeric
- MatrixFeatures
- MatrixUI
- docs

## Inputs / references
- `instructions.md`
- `CODEX_HANDOFF_PLAN.md`
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/TEST_STRATEGY.md`
- `docs/tasks/TASK-0012-phase-3-closure-and-phase-4-rollover.md`
- `docs/session-logs/2026-02-28-phase-3-closure-and-phase-4-rollover.md`

## Planned changes
- Add `MatrixAnalyzeKind.linearMaps` and `MatrixLinearMapDefinitionKind` to shared domain request models.
- Wire linear-map configuration and request-building/validation through `MatrixFeatures` and `MatrixUI` Analyze surfaces.
- Implement exact and numeric linear-map analysis with witness-oriented diagnostics and reusable payload output.
- Expand coordinate-family non-unique diagnostics from one-direction summaries to full family parameterization output.
- Upgrade result-surface math rendering helpers for superscript/subscript/fraction formatting consistency.
- Add/refresh tests across domain, exact, numeric, features, and UI packages.
- Update status/spec/matrix docs and add this task/session record for Phase 4 closure traceability.

## Tests to add or update
- `Packages/MatrixDomain/Tests/MatrixDomainTests/MatrixDomainTests.swift`
- `Packages/MatrixExact/Tests/MatrixExactTests/MatrixExactTests.swift`
- `Packages/MatrixNumeric/Tests/MatrixNumericTests/MatrixNumericTests.swift`
- `Packages/MatrixFeatures/Tests/MatrixFeaturesTests/MatrixFeaturesTests.swift`
- `Packages/MatrixUI/Tests/MatrixUITests/MatrixUITests.swift`

## Docs to update
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/FEATURE_BACKLOG.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/SCREEN_FLOWS.md`
- `docs/TEST_STRATEGY.md`
- `docs/tasks/TASK-0013-phase-4-linear-maps-basis-changes.md`
- `docs/session-logs/2026-02-28-phase-4-linear-maps-basis-changes.md`

## Acceptance criteria
- Analyze supports linear-map workflows in exact and numeric modes for matrix and basis-image definitions.
- Kernel/range, rank/nullity, and injective/surjective/bijective diagnostics are available with reusable witness payloads.
- Basis-relative map matrices, coordinate-change matrices, and similarity diagnostics are available for compatible basis input, with explicit not-applicable diagnostics for incompatible endomorphism assumptions.
- Coordinate-family diagnostics expose full family parameterizations and all nullspace-basis directions.
- Shared result surfaces apply baseline superscript/subscript/fraction rendering upgrades.
- Required package and Xcode test suites pass.
- Phase 4 docs reflect completion without starting Phase 5 implementation.

## Notes
This task closes Phase 4 at a clean checkpoint. Phase 5 planning can proceed without reopening remaining Phase 4 follow-ups.
