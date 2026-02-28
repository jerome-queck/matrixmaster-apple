# Task: Milestone A Foundation Primitives

## Goal
Establish a clean Milestone A checkpoint with real input primitives, local `.mmws` persistence baseline, and sync-state shells across the greenfield SwiftUI multiplatform foundation.

## Scope
- Expand domain input models for matrix, vector, and basis drafting.
- Add validation contracts for exact-friendly token entry.
- Add reusable matrix/vector/basis editor primitives with shared design tokens.
- Add `.mmws` document model + codec shell and file-backed snapshot storage baseline.
- Add sync coordinator contracts + in-memory coordinator behavior.
- Wire feature coordination to use draft validation and sync coordinator transitions.

## Out of scope
- Full Solve/Operate/Analyze algorithm implementations.
- Production cloud sync backend integration.
- Advanced algebra workflows and decomposition engines.

## Affected modules
- MatrixDomain
- MatrixUI
- MatrixPersistence
- MatrixFeatures
- MatrixMasterMobile app shell
- MatrixMasterMac app shell

## Inputs / references
- `instructions.md`
- `docs/START_HERE.md`
- `CODEX_HANDOFF_PLAN.md`
- `BOOTSTRAP_PROMPT_FOR_CODEX.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/REPO_BOOTSTRAP_CHECKLIST.md`
- ADR-0001 through ADR-0005

## Planned changes
- Add `MatrixDraftInput`, `VectorDraftInput`, `BasisDraftInput`, and shared validation errors.
- Add matrix/vector/basis editor views and shared design tokens in `MatrixUI`.
- Add `MatrixWorkspaceDocument` with `.mmws` constants and JSON codec.
- Add file-backed snapshot store shell and sync coordinator shell in `MatrixPersistence`.
- Wire coordinator validation, local-first snapshot save, and sync-state transitions.

## Tests to add or update
- Domain validation and draft-behavior tests.
- UI constructibility tests for editor primitives.
- Persistence codec/store/sync coordinator tests.
- Feature coordinator validation and snapshot-restore tests.

## Docs to update
- `docs/REPO_BOOTSTRAP_CHECKLIST.md`
- `docs/session-logs/2026-02-28-milestone-a-foundation-primitives.md`
- this task record

## Acceptance criteria
- Matrix/vector/basis input primitives exist and compile in shared packages.
- `.mmws` v1 document constants and codec shell exist with passing round-trip tests.
- Feature coordinator validates inputs before running computations.
- Snapshot persistence shell supports file-backed save/load baseline.
- Sync-state shell supports local-only, syncing, synced, and needs-attention transitions.

## Notes
This task is a Phase 1/Milestone A foundation checkpoint and is intentionally scoped to infrastructure and reusable primitives rather than full workflow completeness.
