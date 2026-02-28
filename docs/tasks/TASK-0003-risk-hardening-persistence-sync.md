# Task: Risk Hardening for Persistence and Sync Shells

## Goal
Remove two explicit Milestone A risk items by hardening persistence error handling and replacing purely in-memory sync shell behavior with a durable file-backed sync coordinator baseline.

## Scope
- Make workspace snapshot store operations throw explicit errors instead of swallowing failures.
- Add typed persistence/sync error models for diagnostics.
- Introduce durable sync snapshot state with pending-write and cloud-availability metadata.
- Add a file-backed sync coordinator implementation and use it in foundation app startup.
- Update coordinator logic to keep local-first behavior without falsely reporting immediate convergence.

## Out of scope
- Real cloud provider integration.
- Conflict merge policies beyond baseline state tracking.
- Full sync retry queue and account/session auth wiring.

## Affected modules
- MatrixPersistence
- MatrixFeatures

## Inputs / references
- `instructions.md`
- `docs/PERSISTENCE_AND_EXPORTS.md`
- `docs/ARCHITECTURE.md`
- `docs/TEST_STRATEGY.md`
- `docs/tasks/TASK-0002-milestone-a-foundation-primitives.md`
- `docs/session-logs/2026-02-28-milestone-a-foundation-primitives.md`

## Planned changes
- Convert `WorkspaceSnapshotStoring` APIs to throwing methods.
- Add `WorkspaceSnapshotStoreError` and `WorkspaceSyncCoordinatorError`.
- Add `WorkspaceSyncSnapshot` state model.
- Add `FileWorkspaceSyncCoordinator` and default sync-status file location.
- Update `MatrixMasterFeatureCoordinator` to surface persistence/sync failures and avoid unconditional auto-synced state.

## Tests to add or update
- Persistence tests for file-backed sync state durability and pending-write semantics.
- Feature coordinator tests for offline/local-only behavior and cloud-available convergence behavior.
- Re-run scheme-level tests on Mac and iOS simulator.

## Docs to update
- `docs/PERSISTENCE_AND_EXPORTS.md`
- `docs/ARCHITECTURE.md`
- `docs/session-logs/2026-02-28-risk-hardening-persistence-sync.md`
- this task record

## Acceptance criteria
- Snapshot load/save operations no longer silently ignore failures.
- Sync shell state persists across launches in baseline form.
- Feature coordinator state transitions distinguish local-only from synced states unless convergence is explicitly reached.
- Package and app scheme tests pass.

## Notes
This task closes known baseline risks but does not claim full production cloud sync readiness.
