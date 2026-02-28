# Matrix Master

Matrix Master is a native SwiftUI multiplatform linear algebra workspace and calculator for iPhone, iPad, and Mac.

## Product goals

- make common linear algebra tasks fast, repeatable, and low-friction
- support both exact and numeric computation modes
- keep steps and explanations available on demand without turning the app into courseware chrome
- allow users to reuse results across workflows
- keep work local-first, cloud-synced across devices, and exportable
- ship iPhone, iPad, and Mac together for the first public release

## Primary workflows

- **Solve** - systems of linear equations, REF/RREF, inverse-by-row-reduction
- **Operate** - matrix and vector expressions, products, powers, trace, transpose
- **Analyze** - rank, determinant, subspaces, bases, eigen workflows, decompositions
- **Library** - saved matrices, workspaces, history, sync state, exports, reusable results

## Architectural principles

- SwiftUI multiplatform app shells
- modular internal packages
- exact and numeric engines kept distinct
- local-first persistence with cloud-backed sync
- accessibility and platform conventions treated as core requirements

## Documentation

Start here:

- `instructions.md`
- `CODEX_HANDOFF_PLAN.md`
- `docs/START_HERE.md`

## Status

This repository is intended to be the first-of-its-kind primary codebase built from this plan, not a retrofit or patch stream layered onto an older implementation.
