# ADR-0005: Cloud sync baseline

## Status
Accepted

## Context
Matrix Master is meant to be a serious calculator/productivity tool across iPhone, iPad, and Mac. The user wants cloud sync as part of the app, but the product should still behave like a reliable local-first tool rather than a cloud-only system that fails when connectivity is unavailable.

## Decision
Adopt a local-first, user-private cloud sync baseline with these rules:
- every write commits locally first
- eligible saved data syncs across the user's own devices through a private Apple-cloud path
- saved workspaces and saved library objects are in scope for v1 sync
- manual import/export remains supported
- the app remains fully usable offline or when the user is signed out of cloud services
- v1 does not attempt real-time multi-user collaboration
- when concurrent edits conflict, preserve a recoverable copy rather than silently dropping one version

## Rationale
This approach:
- gives the product real cross-device continuity
- preserves offline responsiveness and local trustworthiness
- fits the calculator/productivity posture better than collaboration-heavy scope creep
- protects user work from silent data loss during conflicts

## Alternatives considered
- keep the app local-only with manual export/import
- make the app cloud-first or cloud-only
- build multi-user collaboration in v1
- sync every bit of transient UI state and cache data

## Consequences
- persistence models need stable identifiers, timestamps, and sync metadata
- the Library UX needs sync status and recovery surfaces
- the test plan must cover offline, account-state, delete, and conflict scenarios
- collaboration, if desired later, should be treated as a separate product/architecture decision

## Follow-up
Document concrete sync scope, recovery UX, and persistence behavior in `docs/PERSISTENCE_AND_EXPORTS.md`, `docs/UX_SPEC.md`, `docs/ARCHITECTURE.md`, and `docs/TEST_STRATEGY.md`.
