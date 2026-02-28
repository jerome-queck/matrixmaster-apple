# Task: Milestone A Closure and Quality Parity

## Goal
Close the remaining Milestone A checklist gaps so the foundation checkpoint is complete, test-verified, and documented consistently.

## Scope
- Remove iOS launch-screen configuration warning from simulator/runtime test runs.
- Add explicit accessibility labels for shell/editor primitives used in common workflows.
- Add or update UI tests to verify accessibility exposure in mobile and Mac shells.
- Re-verify full scheme test execution on iPhone, iPad, and Mac.
- Update bootstrap/roadmap-adjacent docs to reflect Milestone A completion state.

## Out of scope
- Real Solve algorithm vertical slice (exact REF/RREF implementation).
- Full result reuse execution flow implementation.
- Production cloud sync transport/account integration.

## Affected modules
- MatrixMaster project build settings
- MatrixUI
- MatrixMasterMobileUITests
- MatrixMasterMacUITests
- repository milestone/checklist docs

## Inputs / references
- `instructions.md`
- `docs/START_HERE.md`
- `docs/REPO_BOOTSTRAP_CHECKLIST.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/ARCHITECTURE.md`
- `docs/DEPENDENCY_POLICY.md`
- `docs/tasks/TASK-0002-milestone-a-foundation-primitives.md`
- `docs/tasks/TASK-0003-risk-hardening-persistence-sync.md`

## Planned changes
- Add generated launch-screen Info.plist key for mobile target debug/release configs.
- Add VoiceOver-friendly accessibility labels to matrix/vector/basis draft input fields.
- Extend UI tests to validate shell accessibility surfaces and input labels.
- Run full test verification across package and scheme levels.
- Mark completed checklist items and record milestone closure status.

## Tests to add or update
- Mobile UI test for first matrix input accessibility label.
- Mac UI shell accessibility smoke assertion.
- Full scheme tests:
  - `MatrixMasterMobile` on iPhone and iPad simulators
  - `MatrixMasterMac` on macOS

## Docs to update
- `docs/REPO_BOOTSTRAP_CHECKLIST.md`
- `docs/START_HERE.md`
- `docs/ARCHITECTURE.md`
- `docs/DEPENDENCY_POLICY.md`
- `docs/session-logs/2026-02-28-milestone-a-closure-quality.md`
- this task record

## Acceptance criteria
- iOS app runs without the previous launch-screen warning in test launch logs.
- Shell/editor accessibility labels are present for core input workflow controls.
- Mobile and Mac UI smoke coverage includes accessibility-focused assertions.
- Package tests and full iPhone/iPad/Mac scheme tests pass.
- Milestone A checklist/docs reflect completed status.

## Notes
Milestone A closure here means foundation readiness and quality baseline completion. Milestone B continues with real Solve/reuse feature implementation.
