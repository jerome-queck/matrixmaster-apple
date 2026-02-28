# Task: Milestone B UI Shell Polish + Analyze Inverse Visibility

## Goal
Ship the next Milestone B checkpoint by resolving high-friction shell UX issues (control density, action placement, pinned run action, RHS separation) and making Analyze inverse output visible directly in results.

## Scope
- Move reuse actions to the bottom of destination content surfaces.
- Pin the run action button in a bottom safe-area bar so it remains accessible while scrolling.
- Split cramped matrix editor controls into two rows where randomize is enabled.
- Remove Solve A/b header labels and use non-text visual separation for the right-hand solution vector column.
- Ensure Analyze outputs include explicit inverse matrix values (exact and numeric paths).
- Add lightweight math-oriented display formatting for indexed symbols in result text.

## Out of scope
- Full Milestone B Operate expression engine and decomposition expansion.
- Advanced Analyze inventory (null space basis outputs, eigen workflows, QR/SVD, etc.).
- Library persistence-promotion/history UX completion.

## Affected modules
- MatrixFeatures
- MatrixUI
- MatrixExact
- MatrixNumeric
- MatrixMasterMobileUITests

## Inputs / references
- `instructions.md`
- `docs/START_HERE.md`
- `docs/UX_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/FEATURE_MATRIX.md`
- `docs/tasks/TASK-0006-milestone-b-analyze-numeric-reuse.md`

## Planned changes
- Reposition reuse actions below editor/feedback content and pin run action at the bottom.
- Rework Solve and matrix-editor control rows to reduce cramped button layouts.
- Replace Solve textual A/b headers with visual RHS-column separation only.
- Extend Analyze summaries to include concrete inverse matrix renderings.
- Update mobile UI assertions for the new Solve accessibility surface.

## Tests to add or update
- `Apps/MatrixMasterMobileUITests/MatrixMasterMobileUITests.swift`
- `Packages/MatrixExact/Tests/MatrixExactTests/MatrixExactTests.swift`
- `Packages/MatrixNumeric/Tests/MatrixNumericTests/MatrixNumericTests.swift`

## Docs to update
- `docs/START_HERE.md`
- `docs/FEATURE_MATRIX.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/tasks/TASK-0007-milestone-b-ui-shell-polish.md`
- `docs/session-logs/2026-02-28-milestone-b-ui-shell-polish.md`

## Acceptance criteria
- Reuse actions render at bottom across destination views.
- Run action remains accessible via pinned bottom bar while scrolling.
- Solve/Analyze/Operate editor controls avoid cramped single-row wrapping.
- Solve RHS solution vector is visually distinct without extra explanatory label text.
- Analyze answers include inverse matrix values when available.
- Updated package and scheme tests pass on macOS, iPhone simulator, and iPad simulator.

## Notes
This checkpoint remains within Milestone B and intentionally stops before the remaining Core MVP math inventory.
