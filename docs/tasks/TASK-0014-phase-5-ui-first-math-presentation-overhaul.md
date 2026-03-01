# Task: Phase 5 UI-first Math Presentation Overhaul

## Goal
Make Phase 5 a UI-first overhaul that upgrades how math is presented and entered: matrix-looking result rendering, LaTeX-ready output paths, explicit REF/RREF visibility, and richer abstract-space editors.

## Status
- Completed on 2026-03-01.
- Completed with one scoped follow-up.
- Verification passed for package tests (`MatrixDomain`, `MatrixUI`, `MatrixFeatures`) and app suites (`MatrixMasterMobile`, `MatrixMasterMac`).
- Follow-up scope: result-object copy/export controls (`plain`, `markdown`, `latex`) were removed from UI and moved to backlog.

## Scope
- Replace plain-text-first result rendering with structured math object rendering across Solve/Analyze/Operate/Spaces.
- Introduce matrix-looking output surfaces (grid/bracket matrix views, vector stack views, polynomial object views).
- Add explicit REF/RREF result panels for Solve and elimination-backed Analyze workflows.
- Add native polynomial-space and matrix-space element editors (while retaining coordinate/basis internals).
- Apply cross-platform accessibility/performance validation for richer rendering on iPhone, iPad, and Mac.
- Keep existing computational correctness untouched while overhauling presentation/input UX.

## Out of scope
- Phase 6 orthogonality and least-squares algorithms.
- Phase 7 advanced exact/applied topics (minimal polynomial/Jordan/sparse/iterative demos).
- Broad cloud-sync architecture changes beyond format/export integration points.

## Affected modules
- MatrixUI
- MatrixFeatures
- MatrixDomain
- MatrixPersistence
- Apps/MatrixMasterMobile
- Apps/MatrixMasterMac
- docs

## Inputs / references
- `instructions.md`
- `CODEX_HANDOFF_PLAN.md`
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/FEATURE_BACKLOG.md`
- `docs/UX_SPEC.md`
- `docs/SCREEN_FLOWS.md`
- `docs/PERSISTENCE_AND_EXPORTS.md`
- `docs/TEST_STRATEGY.md`

## Planned changes
- Add shared structured math view models and reusable SwiftUI renderers for matrix/vector/polynomial objects.
- Migrate result surfaces from text-only cards to object-aware cards with plain-text fallback where needed.
- Add REF/RREF matrix panels with reuse actions and consistent accessibility labels.
- Add polynomial/matrix-space native element editors and wiring into Spaces workflows.
- Add regression tests for rendering object semantics and new editor entry flows.
- Update roadmap/matrix/flow/spec docs and add checkpoint session logs.

## Tests to add or update
- `Packages/MatrixUI/Tests/MatrixUITests/MatrixUITests.swift`
- `Packages/MatrixFeatures/Tests/MatrixFeaturesTests/MatrixFeaturesTests.swift`
- `Packages/MatrixDomain/Tests/MatrixDomainTests/MatrixDomainTests.swift`
- `Apps/MatrixMasterMobileUITests/MatrixMasterMobileUITests.swift`
- `Apps/MatrixMasterMacUITests/MatrixMasterMacUITests.swift`

## Docs to update
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/FEATURE_BACKLOG.md`
- `docs/SCREEN_FLOWS.md`
- `docs/UX_SPEC.md`
- `docs/PERSISTENCE_AND_EXPORTS.md`
- `docs/TEST_STRATEGY.md`
- `docs/tasks/TASK-0014-phase-5-ui-first-math-presentation-overhaul.md`

## Acceptance criteria
- Core result surfaces render matrices/vectors/polynomials as structured objects instead of plain text blocks.
- Solve and elimination-backed Analyze surfaces show explicit REF/RREF matrix panels.
- Result surfaces remain formatting-first and avoid duplicated matrix payload presentation.
- Spaces supports direct polynomial/matrix-space element entry workflows in addition to existing presets.
- iPhone, iPad, and Mac UI tests and package tests pass with the new presentation/input surfaces.
- Phase sequencing in status docs reflects Phase 5 UI overhaul before Phase 6 orthogonality.
- Copy/export controls are tracked as follow-up backlog scope.

## Notes
This task intentionally treats UI/UX math presentation as first-class engineering scope, not a cosmetic post-processing step.
