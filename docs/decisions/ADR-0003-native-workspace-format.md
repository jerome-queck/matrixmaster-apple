# ADR-0003: Native workspace format

## Status
Accepted

## Context
The old app used the `.mmatrix` extension. The new native codebase needs a fresh canonical workspace format so it can define its own versioning, document identity, and migration story without pretending to be a byte-for-byte continuation of the legacy format.

## Decision
Adopt a new native workspace document with:
- canonical extension `.mmws`
- display name `Matrix Master Workspace`
- UTType identifier `com.matrixmaster.workspace`
- a versioned JSON payload in v1

If legacy `.mmatrix` import is added later, it is compatibility input only and not the canonical native format.

## Rationale
This keeps the new native codebase honest about being a new implementation, avoids accidental format coupling to legacy behavior, and gives the persistence layer a clean migration boundary from day one.

## Alternatives considered
- keep `.mmatrix` for continuity
- introduce multiple custom extensions immediately for every saved object type
- use only generic `.json` without a native workspace identity

## Consequences
A fresh extension means:
- document registration is clearer on Apple platforms
- migration/versioning can be designed around the new app's actual needs
- legacy import, if it exists, becomes an explicit compatibility feature instead of a hidden assumption

## Follow-up
Document the `.mmws` schema and any future compression/version changes in `docs/PERSISTENCE_AND_EXPORTS.md` and implementation ADRs as they happen.
