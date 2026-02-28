# Task: Milestone C Spaces Composition Workflows

## Goal
Deliver the next Milestone C checkpoint by adding dedicated Spaces workflows for basis extraction/testing, basis extension/pruning, and subspace composition (sum/intersection/direct-sum), while extending coordinate diagnostics and ensuring randomize controls are available on every matrix/vector entry tab.

## Scope
- Add a dedicated `Spaces` destination and workflow kind selection in shared domain and feature routing.
- Implement exact and numeric Spaces workflows for:
  - basis test / extract
  - basis extend / prune
  - subspace sum
  - subspace intersection
  - direct-sum check
- Extend coordinate-vector workflows with non-unique-family diagnostics and nullspace-direction payload output.
- Ensure randomize controls are available anywhere matrix/vector entry is performed across destination tabs.
- Update Phase 3 status docs and implementation matrix for checkpoint 3.

## Out of scope
- Phase 4 linear-map/change-of-basis workflows.
- Orthogonality/least-squares workflows.
- Full math-typesetting pass across all result surfaces.

## Affected modules
- MatrixDomain
- MatrixExact
- MatrixNumeric
- MatrixFeatures
- MatrixUI
- MatrixAutomation
- docs

## Inputs / references
- `instructions.md`
- `CODEX_HANDOFF_PLAN.md`
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK-0010-milestone-c-span-independence-coordinates.md`
- `docs/session-logs/2026-02-28-milestone-c-span-independence-coordinates.md`

## Planned changes
- Extend `MatrixMasterDestination` and request contracts with `spaces` routing and `MatrixSpacesKind`.
- Add Spaces configuration UI and feature-coordinator validation/request building for one- and two-subspace workflows.
- Implement exact and numeric Spaces computations with witness-oriented diagnostics and reusable payloads.
- Expand coordinate workflow outputs for non-unique coordinate families.
- Add/refresh tests across domain, engines, features, UI, automation, and platform UI test bundles.
- Record checkpoint 3 completion in roadmap/status/spec/matrix/task/session docs.

## Tests to add or update
- `Packages/MatrixDomain/Tests/MatrixDomainTests/MatrixDomainTests.swift`
- `Packages/MatrixExact/Tests/MatrixExactTests/MatrixExactTests.swift`
- `Packages/MatrixNumeric/Tests/MatrixNumericTests/MatrixNumericTests.swift`
- `Packages/MatrixFeatures/Tests/MatrixFeaturesTests/MatrixFeaturesTests.swift`
- `Packages/MatrixUI/Tests/MatrixUITests/MatrixUITests.swift`
- `Packages/MatrixAutomation/Tests/MatrixAutomationTests/MatrixAutomationTests.swift`
- `Apps/MatrixMasterMobileUITests/MatrixMasterMobileUITests.swift`
- `Apps/MatrixMasterMacUITests/MatrixMasterMacUITests.swift`

## Docs to update
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK-0011-milestone-c-spaces-composition-workflows.md`
- `docs/session-logs/2026-02-28-milestone-c-spaces-composition-workflows.md`

## Acceptance criteria
- Dedicated Spaces workflows support basis test/extract and basis extend/prune in exact and numeric modes.
- Dedicated Spaces workflows support subspace sum/intersection/direct-sum checks with basis/dimension diagnostics.
- Coordinate workflows provide non-unique-family diagnostics and reusable nullspace-direction payloads when uniqueness fails.
- Randomize controls are available on all matrix/vector entry tabs.
- Updated package and scheme tests pass on macOS, iPhone simulator, and iPad simulator.
- Phase 3 docs reflect checkpoint 3 completion without starting Phase 4 implementation.

## Notes
This checkpoint is intentionally bounded to Spaces/basis/subspace workflows and coordinate diagnostics, keeping linear maps and global math-formatting upgrades as subsequent work. Follow-up scheduling: coordinate-family diagnostics polish + math typography baseline in Phase 4 checkpoint 1, abstract-space presets in Phase 4 checkpoint 2+.
