# Task: Milestone B Core MVP Closure

## Goal
Close Milestone B by completing remaining Core MVP workflow gaps and aligning docs/status artifacts to a clean checkpoint.

## Scope
- Replace the numeric Solve placeholder with a real augmented-matrix row-reduction workflow.
- Preserve Solve parity with exact mode for solution classification and reuse payload output.
- Expand numeric Analyze decomposition baseline to explicitly expose SVD-oriented singular-spectrum output.
- Keep Operate/Analyze/Library Milestone B scope bounded to already-delivered workflows; do not begin Phase 3 work.
- Update roadmap/status/docs to mark Milestone B complete.

## Out of scope
- Phase 3+ workflows (spaces/bases, linear maps, orthogonality, advanced topics).
- Full symbolic/theorem-level determinant narratives (cofactor/permutation deep traces).
- Production cloud transport/account integration beyond current local-first sync baseline.

## Affected modules
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
- `docs/tasks/TASK-0005-milestone-b-solve-reuse-baseline.md`
- `docs/tasks/TASK-0006-milestone-b-analyze-numeric-reuse.md`
- `docs/tasks/TASK-0007-milestone-b-ui-shell-polish.md`

## Planned changes
- Implement numeric Solve elimination/classification payload flow in `MatrixNumeric`.
- Add regression tests for numeric Solve and numeric Analyze SVD-baseline outputs.
- Add feature-coordinator test coverage confirming numeric Solve no longer uses pending placeholders.
- Mark Milestone B completion in roadmap/start/status docs and implementation matrix.
- Record closure session log with validation results and remaining follow-ups.

## Tests to add or update
- `Packages/MatrixNumeric/Tests/MatrixNumericTests/MatrixNumericTests.swift`
- `Packages/MatrixFeatures/Tests/MatrixFeaturesTests/MatrixFeaturesTests.swift`

## Docs to update
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK-0008-milestone-b-core-mvp-closure.md`
- `docs/session-logs/2026-02-28-milestone-b-core-mvp-closure.md`

## Acceptance criteria
- Numeric Solve no longer returns a pending placeholder and returns classification + reusable payloads.
- Analyze numeric output includes explicit SVD-baseline singular-spectrum reporting.
- Updated package and scheme tests pass on macOS, iPhone simulator, and iPad simulator.
- Milestone B is marked complete in status/roadmap docs without starting Phase 3 implementation.
