# Implementation roadmap

## Roadmap philosophy

Build vertical slices that become user-valuable early.

Do not wait to "finish the engine" before shipping usable workflows. But also do not throw raw math kernels into the UI without a coherent app shell.

---

## Current status (2026-03-01)

- Phase 0 complete.
- Phase 1 complete.
- Phase 2 (Milestone B Core MVP workflows) complete.
- Phase 3 (Spaces and bases) is complete.
- Phase 3 checkpoint 1 is complete: Analyze now emits column/row/null space basis witnesses and rank-nullity identity summaries in exact and numeric modes.
- Phase 3 checkpoint 2 is complete: Analyze now supports span membership, independence/dependence, and coordinate-vector workflows with witness certificates in exact and numeric modes.
- Phase 3 checkpoint 3 is complete: dedicated Spaces workflows now cover basis testing/extraction, basis extension/pruning, and subspace sum/intersection/direct-sum helpers in exact and numeric modes, with coordinate-family diagnostics expanded for non-unique coordinate solutions.
- Phase 4 (Linear maps and basis changes) is complete.
- Phase 5 (UI-first math presentation overhaul) is complete.
- Phase 6 (Orthogonality and least squares) is next.
- Phase 7 (Advanced topics) follows Phase 6.

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
- follow-up items completed in Phase 4:
  - richer multi-solution coordinate-family displays now emit a full family parameterization and one payload per nullspace basis direction.
  - baseline math-typography rendering upgrades now normalize superscript/subscript/fraction rendering across result surfaces.
  - Spaces abstract-space presets now provide polynomial and matrix-space template scaffolds.
  - similarity diagnostics now provide explicit non-endomorphism guidance when comparison is not applicable.

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

### Completion status (2026-02-28)
- complete:
  - Analyze now exposes a dedicated Linear Maps workflow in exact and numeric modes.
  - Linear maps support map definition by standard matrix and by basis-image matrix input.
  - Exact and numeric outputs now include kernel/range bases, rank/nullity, and injective-surjective-bijective decisions with witness payloads.
  - Basis-relative map matrices (`[T]^beta_gamma`) now compute in both modes with reusable payload output.
  - Change-of-coordinates matrices now compute for compatible basis pairs, including forward and inverse direction payloads.
  - Similarity diagnostics now verify basis-change similarity for endomorphisms, report trace/determinant invariants, and emit explicit not-applicable guidance for non-endomorphism input.
  - Spaces now includes abstract-space preset templates for polynomial spaces (`P_n(F)`) and matrix spaces (`M_mxn(F)`) with direct apply actions to generating sets.
  - Coordinate-family diagnostics now provide full parameterized family output beyond a single nullspace direction.
  - Basis editors now expose explicit dimension controls so vector length can be resized directly instead of staying at the default 3-entry shape.
  - Result rendering now applies baseline math typography formatting across answer/diagnostics/steps.

### Exit criteria
- users can move naturally between abstract maps and matrix representations

---

## Phase 5 - UI-first math presentation overhaul

### Goals
- make math output look like math objects instead of plain text blocks
- deliver structured rendering for matrix/vector/polynomial result payloads
- expose explicit REF/RREF matrix panels in Solve and elimination-backed Analyze workflows
- ship Spaces editor UX v2:
  - native polynomial-space element entry (coefficient-form over `{1, x, x^2, ...}`)
  - native matrix-space element entry/editing while preserving coordinate-vector internals
- standardize result information architecture:
  - answer object
  - diagnostics object
  - optional derivation/steps object
- preserve accessibility/performance parity on iPhone, iPad, and Mac while introducing richer rendering

### Completion status (2026-03-01)
- checkpoint 1 complete:
  - shared structured math object model and renderer now cover matrix grid/bracket, vector stack, and polynomial coefficient views.
  - shared result surfaces now render object-aware cards with plain-text fallback.
- checkpoint 2 complete:
  - Solve and elimination-backed Analyze now show explicit REF/RREF matrix panels.
  - duplicate object rendering between row-reduction panels and object cards is now filtered.
- checkpoint 3 complete:
  - Spaces now supports native polynomial-space element editors.
  - Spaces now supports native matrix-space element editors that map to coordinate-vector internals.
- cross-platform verification complete:
  - package tests (`MatrixDomain`, `MatrixUI`, `MatrixFeatures`) pass.
  - app suites (`MatrixMasterMobile`, `MatrixMasterMac`) pass, including new Phase 5 UI coverage.

### Exit criteria
- major result surfaces render matrix/vector/polynomial outputs as structured math objects
- Solve/Analyze row-reduction workflows expose explicit REF/RREF matrix views
- spaces workflows support direct polynomial/matrix-style element entry in addition to basis presets
- follow-up backlog item:
  - reintroduce result-object copy/export controls (`plain`, `markdown`, `latex`) only after final formatting UX pass

---

## Phase 6 - Orthogonality and least squares

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

## Phase 7 - Advanced topics

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
Ship after Phase 6 with:
- UI-first math presentation overhaul
- spaces and bases
- transformations
- orthogonality and least squares
- cross-device sync behavior stable enough for normal use

### Advanced/study expansion
Ship Phase 7 later as targeted expansions rather than blocking the main product
