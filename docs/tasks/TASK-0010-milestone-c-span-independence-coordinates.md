# Task: Milestone C Span, Independence, and Coordinates

## Goal
Deliver the next Milestone C checkpoint by adding explicit basis-oriented Analyze workflows for span membership, linear independence/dependence, and coordinate vectors, while resolving basis-payload orientation ambiguity from checkpoint 1.

## Scope
- Add Analyze workflow selection for matrix properties, span membership, independence/dependence, and coordinate-vector computation.
- Route basis vectors and target vectors through domain requests for Analyze workflows.
- Implement exact and numeric engine support for span-membership certificates, dependence certificates, and coordinate-vector results.
- Standardize reusable fundamental-subspace basis payload orientation to vectors-as-columns across column/row/null outputs.
- Update Phase 3 status docs and implementation matrix for checkpoint 2.

## Out of scope
- Dedicated non-Analyze spaces surfaces for basis extraction/testing workflows.
- Subspace sum/intersection/direct-sum helpers.
- Phase 4+ linear-map/change-of-basis workflows.

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
- `docs/tasks/TASK-0009-milestone-c-fundamental-subspaces-baseline.md`
- `docs/session-logs/2026-02-28-milestone-c-fundamental-subspaces-baseline.md`

## Planned changes
- Extend `MatrixMasterComputationRequest` with Analyze-kind selection plus basis/target vector inputs.
- Add Analyze configuration controls and feature-coordinator routing/validation for basis workflows.
- Implement exact and numeric Analyze handlers for span-membership, independence/dependence, and coordinate-vector workflows.
- Update exact/numeric regression tests and feature/UI tests for new Analyze behaviors.
- Record checkpoint 2 completion and remaining Phase 3 backlog in roadmap/status docs.

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
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK-0010-milestone-c-span-independence-coordinates.md`
- `docs/session-logs/2026-02-28-milestone-c-span-independence-coordinates.md`

## Acceptance criteria
- Analyze supports basis-oriented span-membership workflows with coefficient witness output when representable.
- Analyze supports independence/dependence workflows with explicit dependence-relation coefficients when dependent.
- Analyze supports coordinate-vector workflows with coefficient outputs for uniquely represented vectors and clear diagnostics otherwise.
- Fundamental-subspace reusable basis payload matrices are consistently vectors-as-columns for column/row/null-space outputs.
- Updated package and scheme tests pass on macOS, iPhone simulator, and iPad simulator.
- Phase 3 docs reflect checkpoint 2 completion without starting the following checkpoint.

## Notes
This checkpoint is intentionally bounded to basis-oriented Analyze workflows and payload-orientation cleanup before broader spaces-surface and subspace-composition work.
