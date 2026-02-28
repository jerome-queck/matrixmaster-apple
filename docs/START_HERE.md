# Start here

This file tells Codex exactly how to begin work in a fresh Matrix Master repository.

## Step 1 - Read the governing docs

Read in this order:

1. `instructions.md`
2. `CODEX_HANDOFF_PLAN.md`
3. `docs/PRODUCT_REQUIREMENTS.md`
4. `docs/UX_SPEC.md`
5. `docs/ARCHITECTURE.md`
6. `docs/MATH_ENGINE_SPEC.md`
7. `docs/PERSISTENCE_AND_EXPORTS.md`
8. `docs/DEPENDENCY_POLICY.md`
9. `docs/IMPLEMENTATION_ROADMAP.md`
10. `docs/TEST_STRATEGY.md`

## Owner-locked decisions

Before building, internalize these confirmed decisions:

- the native workspace format is `.mmws`
- the first public release ships on iPhone, iPad, and Mac together
- the product posture is calculator/productivity first
- one small BigInt SPM dependency is allowed if justified and wrapped
- minimal polynomial and Jordan form should appear in normal Analyze navigation when they ship
- cloud sync across the user's own devices is part of the product baseline
- this repository is the primary greenfield implementation, not a patch/diff against an older codebase

## Step 2 - Create the repository skeleton

Create:

- app shells under `Apps/`
- internal packages under `Packages/`
- docs folders and templates
- local `instructions.md` files for each package and app shell

Do this before large-scale coding.

## Step 3 - Record baseline decisions

Create and confirm these first ADRs:

- `ADR-0001-platform-baseline.md`
- `ADR-0002-dual-engine-strategy.md`
- `ADR-0003-native-workspace-format.md`
- `ADR-0004-exact-arithmetic-dependency-budget.md`
- `ADR-0005-cloud-sync-baseline.md`

If later dependencies are needed beyond the approved BigInt budget, create additional ADRs.

## Step 4 - Build the foundation before features

First build:

- workspace
- package graph
- shared design tokens
- matrix/vector editor primitives
- domain models
- result and step models
- persistence shell
- sync capability shell
- navigation shell

Do not jump straight to advanced algebra features.

## Step 5 - Deliver vertical slices

Build one vertical slice at a time:
- Solve
- Operate
- Analyze
- Library

Each slice should be usable before moving on.

## Step 6 - Keep docs in sync

Any time architecture, UX, scope, persistence, or sync behavior changes:
- update the relevant doc
- add or amend an ADR where appropriate
- record what changed in the session log

## Step 7 - Hold the quality bar

Do not call a feature done unless:
- it builds
- it has tests
- the UX is coherent
- accessibility is considered
- docs are current

## Start order checklist

- [x] create root docs and local instructions files
- [x] create workspace and packages
- [x] create design system and app shell
- [x] create local persistence and sync foundations
- [x] build editors and shared result views
- [x] ship milestone A
- [x] ship milestone B
- [ ] continue through roadmap

Current status:
- Milestone B is complete for the Core MVP workflow set.
- Phase 3 (Spaces and bases) is complete with checkpoints 1, 2, and 3 delivered.
- Phase 4 (Linear maps and basis changes) is complete.
- Solve now runs in both exact and numeric modes with augmented-matrix row reduction, classification, and reusable payload output.
- Operate now supports matrix/vector arithmetic, matrix-vector products, transpose/trace/powers, and expression routing in both exact and numeric engines.
- Analyze now covers exact determinant/rank/nullity/trace/inverse, numeric determinant/rank/nullity/trace/LU/QR/SVD-baseline/eigen-baseline/inverse summaries, Phase 3 checkpoint 1 fundamental-subspace witnesses (column/row/null space bases with rank-nullity identity summaries), Phase 3 checkpoint 2 basis workflows (span-membership, independence/dependence, and coordinate-vector certificates), Phase 3 checkpoint 3 coordinate-family diagnostics for non-unique coordinate systems, and Phase 4 linear-map workflows (define-by-matrix/define-by-basis-images, kernel/range, injective-surjective-bijective checks, basis-relative map matrices, coordinate-change matrices, and similarity diagnostics).
- Spaces now provides dedicated exact and numeric workflows for basis test/extract, basis extend/prune, subspace sum, subspace intersection, and direct-sum checks with reusable basis payload output, plus abstract-space preset templates for polynomial spaces and matrix spaces.
- Matrix and vector editor tabs now expose randomize actions anywhere users manually fill entries.
- Basis editors now expose explicit dimension controls so vectors are no longer locked to the default 3-entry shape.
- Coordinate-family diagnostics now include full multi-solution parameterizations with every nullspace basis direction reused as payload output.
- Similarity diagnostics now include explicit not-applicable guidance when linear-map input is not an endomorphism.
- Result surfaces now apply baseline math typography rendering for exponent, subscript, and fraction notation in answers, diagnostics, and steps.
- Phase 5 (Orthogonality and least squares) is the next implementation phase.
- Library now includes persistence-backed vector save/load/delete, history logging, JSON export baseline, and sync-state-aware local-first write tracking.
