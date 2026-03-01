# Feature matrix

This file maps the requested linear algebra inventory to implementation surfaces, computation modes, and milestones.

## Legend

- **Surface** - where the user encounters the feature
- **Mode** - Exact, Numeric, or Both
- **Milestone** - roadmap phase in which the feature should land

## Current implementation checkpoint (2026-03-01)

- Milestone A foundation checkpoint is complete.
- Milestone B Core MVP closure now includes:
  - Solve in both exact and numeric modes with augmented-matrix REF/RREF, row-operation traces, and unique/infinite/inconsistent classification
  - homogeneous-system input controls and right-hand-side vector separation in Solve editor surfaces
  - Operate workflows in exact and numeric modes for matrix/vector arithmetic, matrix-vector product, transpose, trace, powers, and expression-driven operation selection
  - Analyze exact coverage for determinant, rank, nullity, trace, and inverse output over rationals
  - Analyze numeric coverage for determinant, rank, nullity, trace, LU, QR, SVD-baseline singular spectrum, dominant-eigen baseline, and inverse output with tolerance diagnostics
  - result reuse routing across Solve/Analyze/Operate/Library with payload-aware actions
  - Library baseline with persistence-backed save/load/delete, history, and export actions plus sync-status-aware local-first write tracking
  - bottom-anchored reuse actions and pinned run-action bar across destination views
- Milestone C (Spaces and bases) checkpoint 1 now includes:
  - Analyze exact and numeric column-space basis witnesses from pivot columns
  - Analyze exact and numeric row-space basis witnesses from nonzero RREF rows
  - Analyze exact and numeric null-space basis witnesses from free-variable parameterization
  - Analyze rank-nullity identity diagnostics and reusable basis payloads
- Milestone C (Spaces and bases) checkpoint 2 now includes:
  - Analyze span-membership workflows with basis vectors and target-vector witness coefficients
  - Analyze linear-independence/dependence workflows with dependence-relation coefficients when dependent
  - Analyze coordinate-vector workflows with ordered basis input and coordinate outputs when uniquely determined
  - standardized basis payload orientation for fundamental-subspace reusable matrices (vectors-as-columns)
- Milestone C (Spaces and bases) checkpoint 3 now includes:
  - dedicated Spaces workflows for basis test/extract and basis extend/prune
  - dedicated Spaces workflows for subspace sum/intersection/direct-sum checks
  - coordinate-vector non-unique diagnostics with witness and nullspace-direction payloads
  - randomize controls on all matrix/vector-entry destination tabs
- Phase 4 (Linear maps and basis changes) now includes:
  - Analyze linear-map workflow routing for exact and numeric modes with map definition by matrix or basis-image matrix input
  - kernel/range basis witnesses plus rank/nullity and injective/surjective/bijective decisions
  - basis-relative map matrices (`[T]^beta_gamma`) and change-of-coordinates matrices with reusable payload output
  - similarity diagnostics from basis change, including trace/determinant invariant checks and explicit non-endomorphism messaging when similarity is not applicable
  - Spaces abstract-space presets (`P_n(F)` and `M_mxn(F)`) with canonical-basis template application
  - explicit basis-dimension controls so vector size can be customized beyond the default 3-entry draft
  - full coordinate-family parameterization diagnostics for non-unique coordinate workflows
  - baseline math typography rendering upgrades across answer/diagnostic/step result surfaces
- Phase 5 (UI-first math presentation overhaul) now includes:
  - structured matrix/vector/polynomial rendering across shared result surfaces
  - object-aware result cards with deduplicated answer/diagnostic/object content
  - explicit REF/RREF panels for Solve and elimination-backed Analyze workflows
  - native polynomial-space and matrix-space element entry editors in Spaces
- Milestones A through E (Phase 5) are complete for currently in-scope computational and presentation workflows.
- Phase 6 is now Orthogonality and least squares (next).
- Phase 7 remains Advanced topics.
- Remaining rows in this matrix that target later phases (theory depth, orthogonality, and advanced topics) remain intentionally in-progress.

---

## 0. Supported universes of objects

### Scalars / fields
- real scalars - Both - Foundation
- complex scalars - Numeric first, exact later only if justified - Core MVP
- explicit field selection (`R` / `C`) - Both - Core MVP

### Vectors
- vectors in `R^n` - Both - Foundation
- vectors in `C^n` - Numeric first - Core MVP
- coordinate vectors relative to bases - Exact/Both - Spaces and bases (checkpoints 2 and 3)

### Matrices
- general `m x n` matrices - Both - Foundation
- square matrices - Both - Foundation
- identity matrices - Both - Foundation
- invertible matrices - Both - Core MVP
- elementary matrices - Exact/Both - Core MVP

### Abstract vector spaces
- polynomial spaces `P_n(F)` represented by basis - Exact/Both - Phase 4 (preset templates complete)
- matrix spaces as vector spaces - Exact/Both - Phase 4 (preset templates complete)
- direct polynomial element entry (coefficient-form editor) - Exact/Both - Phase 5 (UI overhaul)
- direct matrix-space element entry (matrix-object editor) - Exact/Both - Phase 5 (UI overhaul)
- function spaces represented through finite-dimensional chosen bases - Numeric/Exact depending basis - Later in spaces/orthogonality expansion

### Linear maps / operators
- maps in `L(V,W)` with basis metadata - Both - Phase 4 (complete)
- endomorphisms in `L(V)` - Both - Phase 4 (complete)
- operator-specific eigen workflows - Both - Linear maps/eigen phase

---

## 1. Vectors and basic vector operations

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| vector addition | Operate | Both | Core MVP |
| scalar multiplication | Operate | Both | Core MVP |
| matrix-vector product | Operate | Both | Core MVP |
| dot product | Operate / Orthogonality | Both | Phase 6 (Orthogonality) |
| linear combinations | Operate / Spaces | Both | Core MVP / Spaces |

---

## 2. Matrices and matrix algebra

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| matrix addition | Operate | Both | Core MVP |
| scalar multiplication | Operate | Both | Core MVP |
| matrix multiplication | Operate | Both | Core MVP |
| transpose | Operate | Both | Core MVP |
| symmetric-matrix recognition | Analyze | Both | Core MVP |
| trace | Operate / Analyze | Both | Core MVP |
| trace linearity/invariants explanation | Analyze | Both | Linear maps/eigen phase |
| matrix powers | Operate | Both | Core MVP |
| fast powers through diagonalization | Analyze / Operate | Both | Eigen phase |

---

## 3. Systems of linear equations and row reduction

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| augmented matrix entry | Solve | Both | Foundation/Core MVP |
| elementary row operations | Solve | Exact/Both | Core MVP |
| REF | Solve | Exact/Both | Core MVP |
| RREF | Solve | Exact/Both | Core MVP |
| explicit REF/RREF matrix panels in result UI | Solve / Analyze | Exact/Both | Phase 5 (UI overhaul) |
| Gaussian elimination | Solve | Exact/Both | Core MVP |
| Gauss-Jordan elimination | Solve | Exact/Both | Core MVP |
| analyze number of solutions | Solve | Exact/Both | Core MVP |
| pivot/free variable analysis | Solve | Exact/Both | Core MVP |
| homogeneous systems | Solve | Exact/Both | Core MVP |

---

## 4. Invertibility and elementary matrices

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| invertibility recognition | Analyze / Solve | Both | Core MVP |
| inverse via row reduction | Solve / Analyze | Exact/Both | Core MVP |
| elementary matrices | Analyze / Solve | Exact/Both | Core MVP |
| invertibility characterizations | Analyze explanations | Both | Core MVP |

---

## 5. LU decomposition

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| LU decomposition | Analyze | Numeric first, exact optional | Core MVP |
| solve multiple systems with same matrix | Solve / Library later | Numeric first | Later optimization |
| determinant via LU | Analyze | Numeric | Core MVP |

---

## 6. Determinants

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| determinant definition/explanation | Analyze | Both | Core MVP |
| minors and cofactors | Analyze | Exact | Core MVP |
| cofactor expansion | Analyze | Exact | Core MVP |
| permutation formula | Analyze advanced | Exact | Phase 7 (Advanced topics) |
| determinant via elimination | Analyze | Both | Core MVP |
| multiplicativity theorem | Analyze explanation/tests | Both | Core MVP |
| invertibility test by determinant | Analyze | Both | Core MVP |
| adjugate matrix | Analyze | Exact | Core MVP |
| inverse via adjugate | Analyze | Exact | Core MVP |
| Cramer's rule | Solve / Analyze | Exact | Core MVP |

---

## 7. Vector spaces and subspaces

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| vector space definition and examples | Theory / Analyze | N/A + coordinate-backed tools | Phase 4+ spaces expansion |
| subspace test | Analyze / Spaces | Exact/Both | Spaces and bases (checkpoint 3) |
| intersection of subspaces | Analyze / Spaces | Exact/Both | Spaces and bases (checkpoint 3) |
| sum of subspaces | Analyze / Spaces | Exact/Both | Spaces and bases (checkpoint 3) |
| direct sums | Analyze / Spaces | Exact/Both | Spaces and bases (checkpoint 3) |
| polynomial spaces | Spaces | Exact/Both | Phase 4 (preset templates complete) |
| matrix spaces | Spaces | Exact/Both | Phase 4 (preset templates complete) |

---

## 8. Span and membership

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| linear combination writing | Operate / Spaces | Both | Core MVP / Spaces |
| span definition/explanation | Spaces | Both | Phase 4+ spaces expansion |
| membership in span | Analyze / Spaces | Exact/Both | Spaces and bases (checkpoint 2) |

---

## 9. Linear independence and dependence

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| independence definitions | Spaces | Both | Phase 4+ spaces expansion |
| independence tests | Analyze / Spaces | Exact/Both | Spaces and bases (checkpoint 2) |
| dependence relations | Analyze / Spaces | Exact/Both | Spaces and bases (checkpoint 2) |

---

## 10. Bases, coordinates, dimension

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| basis testing | Spaces | Exact/Both | Spaces and bases (checkpoint 3) |
| dimension | Spaces / Analyze | Exact/Both | Spaces and bases (checkpoint 3) |
| ordered basis handling | Spaces | Exact/Both | Spaces and bases (checkpoint 2) |
| coordinate vector | Analyze / Spaces / Linear maps | Exact/Both | Spaces and bases (checkpoints 2 and 3) |
| basis extension/pruning | Spaces advanced | Exact/Both | Spaces and bases (checkpoint 3) |

---

## 11. Fundamental subspaces, rank, rank-nullity

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| column space | Analyze | Exact/Both | Spaces and bases (checkpoint 1) |
| row space | Analyze | Exact/Both | Spaces and bases (checkpoint 1) |
| null space | Analyze | Exact/Both | Spaces and bases (checkpoint 1) |
| four fundamental subspaces dashboard | Analyze advanced | Exact/Both | Phase 4+ spaces expansion |
| rank | Analyze | Both | Core MVP |
| rank-nullity theorem summary | Analyze | Exact/Both | Spaces and bases (checkpoint 1) |

---

## 12. Linear transformations

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| define linear transformation | Analyze / Linear Maps | Both | Phase 4 (complete) |
| kernel | Linear Maps | Exact/Both | Phase 4 (complete) |
| range/image | Linear Maps | Exact/Both | Phase 4 (complete) |
| rank and nullity of map | Linear Maps | Exact/Both | Phase 4 (complete) |
| injective/surjective/bijective | Linear Maps | Exact/Both | Phase 4 (complete) |
| isomorphisms | Linear Maps explanations | Exact/Both | Phase 4 (complete) |

---

## 13. Matrix representations and change of basis

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| matrix representation `[T]^\beta_\gamma` | Linear Maps | Exact/Both | Phase 4 (complete) |
| coordinate maps | Spaces / Linear Maps | Exact/Both | Phase 4 (complete) |
| composition as matrix multiplication | Linear Maps explanation | Both | Phase 4 (complete) |
| change-of-coordinates matrices | Linear Maps / Spaces | Exact/Both | Phase 4 (complete) |
| changing matrix representations | Linear Maps | Exact/Both | Phase 4 (complete) |

---

## 14. Similarity and invariants

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| similarity definition | Analyze / Linear Maps | Both | Phase 4 (complete) |
| trace similarity invariant | Analyze | Both | Phase 4 (complete) |
| determinant similarity invariant | Analyze | Both | Phase 4 (complete) |
| same operator different basis => similar matrices | Linear Maps | Both | Phase 4 (complete) |

---

## 15. Eigenvalues, eigenvectors, eigenspaces

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| eigenvalues/eigenvectors | Analyze | Both | Core MVP numeric, exact later |
| eigenspaces | Analyze | Both | Eigen phase |
| characteristic polynomial | Analyze | Exact small matrices + numeric summary | Eigen phase |
| algebraic vs geometric multiplicity | Analyze | Both | Eigen phase |

---

## 16. Diagonalization

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| diagonalization `A = PDP^{-1}` | Analyze | Both | Eigen phase |
| diagonalizable criteria | Analyze | Both | Eigen phase |
| fast powers via diagonal form | Analyze / Operate | Both | Eigen phase |

---

## 17. Minimal polynomials and Jordan form

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| minimal polynomial | Analyze / Eigen and canonical forms | Exact first | Phase 7 (Advanced topics) |
| Jordan canonical form | Analyze / Eigen and canonical forms | Exact first | Phase 7 (Advanced topics) |

---

## 18. Inner product spaces, norms, distances

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| inner product definition | Orthogonality | Both | Phase 6 (Orthogonality) |
| standard inner product on `R^n` | Orthogonality / Operate | Both | Phase 6 (Orthogonality) |
| standard Hermitian product on `C^n` | Orthogonality | Numeric/Both | Phase 6 (Orthogonality) |
| integral-based product on basis-defined function spaces | Orthogonality advanced | Depends on representation | Later |
| Frobenius inner product | Orthogonality / Analyze | Both | Phase 6 (Orthogonality) |
| induced norm | Orthogonality | Both | Phase 6 (Orthogonality) |
| Cauchy-Schwarz | Explanation / checks | Both | Phase 6 (Orthogonality) |
| triangle inequality | Explanation / checks | Both | Phase 6 (Orthogonality) |

---

## 19. Orthogonality, Gram-Schmidt, projections

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| orthogonality test | Orthogonality | Both | Phase 6 (Orthogonality) |
| orthonormal set/basis | Orthogonality | Both | Phase 6 (Orthogonality) |
| Fourier coefficients | Orthogonality | Both | Phase 6 (Orthogonality) |
| projection onto vector | Orthogonality | Both | Phase 6 (Orthogonality) |
| Gram-Schmidt | Orthogonality | Both | Phase 6 (Orthogonality) |
| projection onto subspace | Orthogonality | Both | Phase 6 (Orthogonality) |
| orthogonal complement | Orthogonality | Both | Phase 6 (Orthogonality) |

---

## 20. Least squares

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| least-squares solution | Orthogonality / Analyze | Numeric first | Phase 6 (Orthogonality) |
| projection interpretation | Orthogonality explanation | Both | Phase 6 (Orthogonality) |

---

## 21. Applications and extended roadmap

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| PageRank demo | Advanced / Examples | Numeric | Phase 7 (Advanced topics) |
| SVD and PCA | Advanced / Applied | Numeric | Phase 7 (Advanced topics) |
| FEM examples | Advanced / Examples | Numeric | Phase 7 (Advanced topics) |


---

## 22. Result presentation and formatting

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| structured matrix rendering (grid/bracket object view) | Solve / Analyze / Operate / Spaces | Both | Phase 5 (UI overhaul) |
| structured vector/polynomial object rendering | Solve / Analyze / Operate / Spaces | Both | Phase 5 (UI overhaul) |
| copy/export as plain/markdown/LaTeX result objects | Result actions / Library export | Both | Follow-up backlog |
| object-aware result layout (answer/diagnostics/steps cards) | Shared result surfaces | Both | Phase 5 (UI overhaul) |

---

## 23. Library, persistence, and sync

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| saved workspaces | Library | Both | Core MVP |
| saved matrices/vectors/bases/maps | Library / reuse | Both | Core MVP |
| history | Library | Both | Core MVP |
| export/import | Library / result actions | Both | Core MVP |
| cross-device cloud sync | Library / app-wide | Both | Core MVP |
| sync status and retry states | Library / Settings-like surfaces | Both | Core MVP |
| conflict-safe recovery copies | Library | Both | Core MVP |
| shared workspaces / collaboration | Library | Both | Backlog |
