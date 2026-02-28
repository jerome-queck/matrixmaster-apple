# Task: Bootstrap Xcode Foundation (Phase 0)

## Goal
Create a buildable, greenfield native SwiftUI multiplatform foundation that opens directly in Xcode and is ready for immediate app-shell iteration.

## Scope
- Create a native Xcode workspace/project in-repo.
- Create iPhone+iPad and Mac app shells.
- Create internal Swift packages and baseline package dependency graph.
- Add baseline unit and UI test targets for both app shells.
- Ensure project assets/configuration are committed (no generator required by the user).

## Out of scope
- Feature completeness for Solve/Operate/Analyze/Library math workflows.
- Full persistence/sync implementation.
- Advanced algorithm implementations.

## Affected modules
- MatrixMasterMobile app shell
- MatrixMasterMac app shell
- MatrixDomain
- MatrixUI
- MatrixFeatures
- MatrixExact
- MatrixNumeric
- MatrixPersistence
- MatrixAutomation

## Inputs / references
- `instructions.md`
- `docs/START_HERE.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/UX_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/PERSISTENCE_AND_EXPORTS.md`
- `docs/DEPENDENCY_POLICY.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/TEST_STRATEGY.md`
- ADR-0001 through ADR-0005

## Planned changes
- Add package manifests, sources, and baseline tests for all internal modules.
- Add SwiftUI shell views and lightweight coordinators suitable for immediate UI bootstrapping.
- Add Xcode project/workspace with mobile and Mac app + test targets.
- Add shared schemes for apps and tests.

## Tests to add or update
- Baseline package unit tests in each internal package.
- App unit tests for mobile and Mac shell defaults.
- App UI smoke tests for launch/navigation shell visibility.

## Docs to update
- Task record for this bootstrap task.
- Session log for this focused work session.

## Acceptance criteria
- Project opens directly in Xcode from committed workspace/project files.
- Mobile app target runs on iPhone and iPad simulators.
- Mac app target runs on Mac.
- Unit/UI test targets are present and runnable.
- Internal package structure exists with passing baseline tests.

## Notes
This task is a foundation checkpoint aligned with Implementation Roadmap Phase 0 bootstrap exit criteria.
