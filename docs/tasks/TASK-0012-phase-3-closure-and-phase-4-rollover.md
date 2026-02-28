# Task: Phase 3 Closure and Phase 4 Rollover Planning

## Goal
Close Phase 3 (Spaces and bases) as complete in project status docs and explicitly schedule all remaining non-blocking follow-ups into the relevant upcoming phase checkpoints.

## Scope
- Mark Phase 3 complete in status docs.
- Remove ambiguity between completed Phase 3 computational scope and deferred theory/UX expansion rows.
- Record scheduled carry-over work with explicit phase/checkpoint targets.
- Add closure session documentation for traceable handoff into Phase 4.

## Out of scope
- New Phase 4 implementation work (linear maps and basis-change computation).
- Additional engine or UI feature coding beyond documentation closure.

## Affected modules
- docs

## Inputs / references
- `instructions.md`
- `CODEX_HANDOFF_PLAN.md`
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/FEATURE_BACKLOG.md`
- `docs/tasks/TASK-0011-milestone-c-spaces-composition-workflows.md`
- `docs/session-logs/2026-02-28-milestone-c-spaces-composition-workflows.md`

## Planned changes
- Update `START_HERE` and roadmap status to indicate Phase 3 completion and Phase 4 readiness.
- Update feature-matrix milestone labels where rows are intentionally deferred beyond Phase 3.
- Add explicit carry-over scheduling to backlog and milestone docs:
  - coordinate-family diagnostics polish
  - math typography baseline
  - abstract-space presets
- Add Phase 3 closure task/session records.

## Tests to add or update
- No code-path changes; no additional automated tests required.

## Docs to update
- `docs/START_HERE.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_MATRIX.md`
- `docs/FEATURE_BACKLOG.md`
- `docs/tasks/TASK-0011-milestone-c-spaces-composition-workflows.md`
- `docs/session-logs/2026-02-28-milestone-c-spaces-composition-workflows.md`
- `docs/tasks/TASK-0012-phase-3-closure-and-phase-4-rollover.md`
- `docs/session-logs/2026-02-28-phase-3-closure-and-phase-4-rollover.md`

## Acceptance criteria
- Status docs clearly state Phase 3 is complete.
- Remaining non-blocking items are documented with concrete target phase/checkpoint assignments.
- Feature matrix no longer implies deferred rows are unfinished Phase 3 deliverables.
- Closure and rollover decisions are captured in task/session records.

## Notes
This is a documentation-only closure task to unblock Phase 4 start without hidden Phase 3 carry-over ambiguity.
