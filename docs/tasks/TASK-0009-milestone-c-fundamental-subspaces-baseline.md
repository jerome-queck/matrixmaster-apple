# Task: Milestone C Fundamental Subspaces Baseline

## Goal
Start Milestone C (Spaces and bases) with a clean first checkpoint that brings witness-oriented fundamental-subspace reasoning into Analyze without starting later Milestone C workflows.

## Scope
- Extend Analyze exact and numeric outputs with column-space, row-space, and null-space basis witnesses.
- Add explicit rank-nullity identity diagnostics in Analyze.
- Emit reusable Analyze payloads for subspace-basis matrices where nontrivial basis vectors are available.
- Update status/roadmap/matrix docs to mark Phase 3 checkpoint 1 complete.

## Out of scope
- Span-membership input workflows and explicit membership certificates.
- Dedicated linear-independence/dependence workflow surfaces.
- Ordered-basis and coordinate-vector workflows.
- Subspace sum/intersection/direct-sum helpers.
- Any Phase 4+ work (linear maps, orthogonality, advanced topics).

## Affected modules
- MatrixExact
- MatrixNumeric
- MatrixFeatures
- docs

## Inputs / references
- `instructions.md`
- `CODEX_HANDOFF_PLAN.md`
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK-0008-milestone-b-core-mvp-closure.md`

## Planned changes
- Add Analyze basis-witness extraction from pivot/RREF summaries in exact and numeric engines.
- Add Analyze rank-nullity identity diagnostics in exact and numeric modes.
- Add Analyze reusable payloads for column/row/null basis matrices.
- Add regression coverage for the new Analyze outputs and payloads.
- Record the checkpoint and status updates in roadmap/matrix/task/session docs.

## Tests to add or update
- `Packages/MatrixExact/Tests/MatrixExactTests/MatrixExactTests.swift`
- `Packages/MatrixNumeric/Tests/MatrixNumericTests/MatrixNumericTests.swift`
- `Packages/MatrixFeatures/Tests/MatrixFeaturesTests/MatrixFeaturesTests.swift`

## Docs to update
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK-0009-milestone-c-fundamental-subspaces-baseline.md`
- `docs/session-logs/2026-02-28-milestone-c-fundamental-subspaces-baseline.md`

## Acceptance criteria
- Analyze exact and numeric outputs include witness-oriented column/row/null basis summaries.
- Analyze exact and numeric diagnostics include explicit rank-nullity identity checks.
- Analyze emits reusable basis-matrix payloads for nontrivial fundamental-subspace bases.
- Updated package and scheme tests pass on macOS, iPhone simulator, and iPad simulator.
- Phase 3 is marked in-progress with checkpoint 1 complete, without starting the next Milestone C checkpoint.

## Notes
This checkpoint is intentionally scoped to fundamental-subspace witness output inside Analyze to keep Milestone C progression incremental.
