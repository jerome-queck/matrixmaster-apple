# Product requirements

## Product statement

Matrix Master is a local-first linear algebra app for Apple platforms that helps users compute, inspect, and understand linear algebra objects and workflows without friction, while keeping important work in sync across the user's own devices.

It should feel like a serious mathematical tool without becoming a maze, and more like a fast calculator/workspace than a course shell.

## Primary user promise

A user should be able to:
- enter or paste mathematical objects quickly
- choose an operation with minimal hunting
- see the answer immediately
- inspect steps when needed
- reuse the result elsewhere
- save or export work easily
- pick up saved work on another signed-in device without unnecessary manual transfer

## Core product principles

1. **Clarity before cleverness**
2. **Answer first**
3. **Progressive disclosure**
4. **Exact when appropriate**
5. **Numerically stable when approximate**
6. **Reusable results**
7. **Local-first, cloud-synced, and exportable**
8. **Accessible and keyboard-friendly**

## First public release posture

The first public release should lean calculator/productivity first:

- quick entry, quick answer, quick reuse
- same-day iPhone, iPad, and Mac public release for the core product
- strong history, saved objects, export, sync, and keyboard efficiency
- explanations and derivations available on demand rather than dominating the interface
- study-specific extras stay out of the critical path

## Supported object universes

The product should support these object types:

- scalars over real and complex fields
- vectors in `R^n` and `C^n`
- matrices `m x n` and `n x n`
- identity, invertible, and elementary matrices
- finite-dimensional abstract spaces represented by bases
- polynomial spaces `P_n(F)`
- finite-dimensional function-like spaces represented by chosen bases
- linear maps / operators with basis-relative matrix representations

## Primary navigation

The app should expose four destinations:

- Solve
- Operate
- Analyze
- Library

## Major feature clusters

### Solve
Must include:
- augmented matrix entry
- Gaussian elimination
- Gauss-Jordan elimination
- REF / RREF
- consistency detection
- pivot/free variable analysis
- parameterized solution sets
- homogeneous systems
- inverse via row reduction
- optional LU-assisted solve later

### Operate
Must include:
- matrix addition
- scalar multiplication
- matrix multiplication
- matrix-vector product
- transpose
- trace
- powers
- named matrices
- vector arithmetic
- linear combinations
- expression builder and parser

### Analyze
Must include:
- determinant
- minors and cofactors
- adjugate
- Cramer's rule
- rank
- nullity
- column / row / null space
- span membership
- linear independence
- basis extraction
- ordered bases
- coordinate vectors
- dimension
- subspace sum/intersection/direct sum
- linear transformation analysis
- kernel / range
- injective / surjective / bijective checks
- matrix representations relative to bases
- change of basis
- similarity
- eigenvalues / eigenvectors / eigenspaces
- diagonalization
- matrix powers via diagonalization
- inner products
- norms
- distances
- orthogonality
- orthonormal bases
- Gram-Schmidt
- projection onto a vector
- projection onto a subspace
- orthogonal complement
- least squares

### Library
Must include:
- saved matrices and bases
- saved workspaces
- history
- tags or folders
- export/import
- result reuse
- report-friendly saved outputs
- sync status that is clear but not noisy
- cross-device cloud sync for user-owned data

## Sync scope for v1

Cloud sync in the first public release should cover:
- saved workspaces
- saved matrices/vectors/bases/maps
- folders, tags, and favorites if implemented
- continuity-relevant user settings where that improves cross-device flow

The app should still support manual export/import, and it should stay fully usable offline.

The first release does **not** need:
- real-time shared editing
- multi-user collaboration
- cloud-only documents that fail when connectivity is unavailable

## Must-have vs later

### Must-have for first substantial release
- Solve core
- Operate core
- determinant / inverse / rank / trace
- LU / QR / SVD / eigen basics
- span / basis / subspace essentials
- column / row / null space
- coordinate vectors and change of basis
- Gram-Schmidt / projection / least squares
- library/history/export
- cloud sync for saved workspaces and library items
- accessibility for common workflows

### Later or advanced
- minimal polynomial
- Jordan canonical form
- sparse matrix inspector
- iterative solvers
- PageRank demo
- PCA / applied SVD workspace
- FEM-flavored examples
- exercise packs and practice content

## Product non-goals for initial build

- real-time cloud collaboration or shared editing
- web version
- Android version
- plugin marketplace
- arbitrary symbolic CAS ambitions beyond required algebra workflows
- social features

## UX-level acceptance criteria

A feature is only acceptable if:
- its entry point is discoverable
- the input path is not hostile
- the result is understandable at a glance
- the explanation is available but not forced
- output can be reused without manual re-entry

## Sync-level acceptance criteria

Cloud sync is acceptable only if:
- saved work converges across the user's signed-in devices
- offline edits are queued and later reconciled
- conflicts do not silently destroy data
- sync state and failures are visible in human language

## Educational behavior

The app is not a textbook replacement, and the first release should not feel like courseware, but it should support learning by:
- exposing derivation steps
- naming pivots, free variables, subspaces, and basis roles clearly
- showing certificates/witnesses for yes-no claims
- connecting abstract and matrix viewpoints
- explaining field assumptions where results differ over `R` and `C`
