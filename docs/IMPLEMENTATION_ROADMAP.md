# Implementation roadmap

## Roadmap philosophy

Build vertical slices that become user-valuable early.

Do not wait to "finish the engine" before shipping usable workflows. But also do not throw raw math kernels into the UI without a coherent app shell.

---

## Current status (2026-02-28)

- Phase 0 complete.
- Phase 1 complete.
- Phase 2 (Milestone B Core MVP workflows) complete.
- Phase 3 (Spaces and bases) is complete.
- Phase 3 checkpoint 1 is complete: Analyze now emits column/row/null space basis witnesses and rank-nullity identity summaries in exact and numeric modes.
- Phase 3 checkpoint 2 is complete: Analyze now supports span membership, independence/dependence, and coordinate-vector workflows with witness certificates in exact and numeric modes.
- Phase 3 checkpoint 3 is complete: dedicated Spaces workflows now cover basis testing/extraction, basis extension/pruning, and subspace sum/intersection/direct-sum helpers in exact and numeric modes, with coordinate-family diagnostics expanded for non-unique coordinate solutions.
- Phase 4 (Linear maps and basis changes) is next.

---

## Phase 0 - Bootstrap

### Goals
- create repository docs
- create workspace and package skeleton
- create app shells
- define design tokens
- create local instructions files
- record initial ADRs
- record the cloud sync baseline and capability plan

### Deliverables
- all required markdown files
- workspace builds on target platforms
- package graph established
- CI/test scaffolding ready
- sync capabilities are accounted for in the repo plan
- no meaningful feature work yet beyond shell/editor primitives

### Exit criteria
- docs exist and are internally consistent
- app launches into a navigable shell
- repo is ready for vertical slice work

---

## Phase 1 - Foundation primitives

### Goals
- matrix editor
- vector editor
- set-of-vectors/basis editor
- core domain models
- request/result/step types
- reusable result UI
- workspace state shell
- persistence basics
- sync identity/change-tracking foundation

### Deliverables
- stable editor components
- validation framework
- basic save/load for sample objects
- answer/steps/explanation result layout
- local persistence models with stable identifiers
- sync status model and mockable sync coordinator contracts

### Exit criteria
- users can enter and save core objects
- editors are usable across phone, tablet, and Mac
- foundation is ready for core algebra features

---

## Phase 2 - Core MVP workflows

### Solve
- systems of equations
- REF / RREF
- Gaussian / Gauss-Jordan
- pivot/free variable analysis
- homogeneous systems
- inverse via row reduction

### Operate
- vector arithmetic
- matrix arithmetic
- transpose
- trace
- powers
- matrix-vector product
- named-object expression builder

### Analyze
- determinant
- rank
- nullity
- LU
- QR
- SVD
- eigen basics

### Library
- save/load
- history
- result reuse
- export basics
- cloud sync baseline for saved workspaces and library items
- sync status and basic recovery surfaces

### Exit criteria
- user can complete common linear algebra tasks end-to-end
- the app is genuinely useful as a repeat-use calculator/productivity tool
- core feature tests are in place
- a signed-in user can create or change saved work on one device and reopen it on another after sync

---

## Phase 3 - Spaces and bases

### Goals
- span membership
- linear independence
- basis extraction
- ordered bases
- coordinate vectors
- dimension
- column/row/null spaces
- rank-nullity summaries
- subspace sum/intersection/direct sum

### Checkpoint status (2026-02-28)
- checkpoint 1 complete:
  - Analyze exact and numeric now report witness-oriented column-space, row-space, and null-space basis summaries from RREF/pivot analysis.
  - Analyze now includes explicit rank-nullity identity diagnostics and reusable basis-matrix payloads.
- checkpoint 2 complete:
  - Analyze exact and numeric now support span-membership checks against basis vectors with coefficient certificates for witnessable representations.
  - Analyze exact and numeric now support linear-independence/dependence checks with explicit dependence-relation coefficients when dependent.
  - Analyze exact and numeric now support coordinate-vector workflows over ordered basis input with coefficient outputs and diagnostics when coordinates are not uniquely available.
  - Fundamental-subspace basis payload orientation is now standardized as vectors-as-columns for all column/row/null-space matrix payloads.
- checkpoint 3 complete:
  - dedicated Spaces destination and request routing now support basis test/extract and basis extend/prune workflows in exact and numeric modes.
  - Spaces now supports subspace sum, subspace intersection, and direct-sum checks with basis-witness payloads and dimension diagnostics.
  - coordinate-vector workflows now emit non-unique-family diagnostics with witness coordinates and nullspace-direction reuse payloads when uniqueness fails.
- follow-up items moved out of Phase 3 scope:
  - richer multi-solution coordinate-family displays beyond one witness plus one nullspace direction -> Phase 4 checkpoint 1 (workflow diagnostics polish).
  - broader math-typography rendering upgrades across result surfaces -> Phase 4 checkpoint 1 (UI rendering polish).
  - abstract-space presets (polynomial and matrix-space templates) for Spaces workflows -> Phase 4 checkpoint 2+ (spaces UX expansion).

### Exit criteria
- the app clearly bridges matrix computations and space-level reasoning
- every decision includes a witness/certificate where meaningful

---

## Phase 4 - Linear maps and basis changes

### Goals
- define maps by matrix or basis images
- kernel / range
- injective / surjective / bijective checks
- basis-relative matrix representations
- change-of-coordinates matrices
- similarity from basis change
- carry-over polish from Phase 3:
  - richer multi-solution coordinate-family diagnostics
  - baseline math typography rendering upgrades across result surfaces

### Exit criteria
- users can move naturally between abstract maps and matrix representations

---

## Phase 5 - Orthogonality and least squares

### Goals
- inner products
- norms and distances
- orthogonality checks
- Gram-Schmidt
- orthonormal bases
- Fourier-style coefficients in orthonormal bases
- projection onto vector/subspace
- orthogonal complements
- least squares

### Exit criteria
- projection and least squares workflows are clear, stable, and reusable

---

## Phase 6 - Advanced topics

### Goals
- minimal polynomial
- Jordan form
- sparse tools
- iterative solvers
- SVD/PCA extras
- applied demos

### Exit criteria
- advanced features do not compromise core app clarity
- advanced tools are discoverable through normal Analyze categories and search without bloating first-run surfaces

---

## Milestone rules

For every phase:
- complete docs updates
- keep acceptance criteria explicit
- add tests with each feature
- avoid broad speculative refactors
- keep Mac and mobile parity aligned
- do not defer Mac beyond the first public release
- keep local-first behavior intact even while sync expands

## Release guidance

### First public release rule
Whatever phase becomes the first public release, ship iPhone, iPad, and Mac together.
Parity means the core Solve, Operate, Analyze, and Library workflows, plus history/import/export/reuse/sync, all exist on every platform.

### Internal alpha
Ship after Phase 2 with:
- strong Solve
- strong Operate
- core Analyze
- Library basics
- sync foundation visible enough to shake out account/offline bugs early

### Beta
Ship after Phase 5 with:
- spaces and bases
- transformations
- orthogonality and least squares
- cross-device sync behavior stable enough for normal use

### Advanced/study expansion
Ship Phase 6 later as targeted expansions rather than blocking the main product
