# Feature matrix

This file maps the requested linear algebra inventory to implementation surfaces, computation modes, and milestones.

## Legend

- **Surface** - where the user encounters the feature
- **Mode** - Exact, Numeric, or Both
- **Milestone** - roadmap phase in which the feature should land

---

## 0. Supported universes of objects

### Scalars / fields
- real scalars - Both - Foundation
- complex scalars - Numeric first, exact later only if justified - Core MVP
- explicit field selection (`R` / `C`) - Both - Core MVP

### Vectors
- vectors in `R^n` - Both - Foundation
- vectors in `C^n` - Numeric first - Core MVP
- coordinate vectors relative to bases - Exact/Both - Spaces and bases

### Matrices
- general `m x n` matrices - Both - Foundation
- square matrices - Both - Foundation
- identity matrices - Both - Foundation
- invertible matrices - Both - Core MVP
- elementary matrices - Exact/Both - Core MVP

### Abstract vector spaces
- polynomial spaces `P_n(F)` represented by basis - Exact/Both - Spaces and bases
- matrix spaces as vector spaces - Exact/Both - Spaces and bases
- function spaces represented through finite-dimensional chosen bases - Numeric/Exact depending basis - Later in spaces/orthogonality expansion

### Linear maps / operators
- maps in `L(V,W)` with basis metadata - Both - Linear maps phase
- endomorphisms in `L(V)` - Both - Linear maps phase
- operator-specific eigen workflows - Both - Linear maps/eigen phase

---

## 1. Vectors and basic vector operations

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| vector addition | Operate | Both | Core MVP |
| scalar multiplication | Operate | Both | Core MVP |
| matrix-vector product | Operate | Both | Core MVP |
| dot product | Operate / Orthogonality | Both | Orthogonality |
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
| permutation formula | Analyze advanced | Exact | Advanced |
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
| vector space definition and examples | Theory / Analyze | N/A + coordinate-backed tools | Spaces and bases |
| subspace test | Analyze / Spaces | Exact/Both | Spaces and bases |
| intersection of subspaces | Analyze / Spaces | Exact/Both | Spaces and bases |
| sum of subspaces | Analyze / Spaces | Exact/Both | Spaces and bases |
| direct sums | Analyze / Spaces | Exact/Both | Spaces and bases |
| polynomial spaces | Spaces | Exact/Both | Spaces and bases |
| matrix spaces | Spaces | Exact/Both | Spaces and bases |

---

## 8. Span and membership

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| linear combination writing | Operate / Spaces | Both | Core MVP / Spaces |
| span definition/explanation | Spaces | Both | Spaces and bases |
| membership in span | Spaces | Exact/Both | Spaces and bases |

---

## 9. Linear independence and dependence

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| independence definitions | Spaces | Both | Spaces and bases |
| independence tests | Spaces | Exact/Both | Spaces and bases |
| dependence relations | Spaces | Exact/Both | Spaces and bases |

---

## 10. Bases, coordinates, dimension

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| basis testing | Spaces | Exact/Both | Spaces and bases |
| dimension | Spaces / Analyze | Exact/Both | Spaces and bases |
| ordered basis handling | Spaces | Exact/Both | Spaces and bases |
| coordinate vector | Spaces / Linear maps | Exact/Both | Spaces and bases |
| basis extension/pruning | Spaces advanced | Exact/Both | Spaces and bases |

---

## 11. Fundamental subspaces, rank, rank-nullity

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| column space | Analyze | Exact/Both | Spaces and bases |
| row space | Analyze | Exact/Both | Spaces and bases |
| null space | Analyze | Exact/Both | Spaces and bases |
| four fundamental subspaces dashboard | Analyze advanced | Exact/Both | Spaces and bases |
| rank | Analyze | Both | Core MVP |
| rank-nullity theorem summary | Analyze | Exact/Both | Spaces and bases |

---

## 12. Linear transformations

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| define linear transformation | Analyze / Linear Maps | Both | Linear maps phase |
| kernel | Linear Maps | Exact/Both | Linear maps phase |
| range/image | Linear Maps | Exact/Both | Linear maps phase |
| rank and nullity of map | Linear Maps | Exact/Both | Linear maps phase |
| injective/surjective/bijective | Linear Maps | Exact/Both | Linear maps phase |
| isomorphisms | Linear Maps explanations | Exact/Both | Linear maps phase |

---

## 13. Matrix representations and change of basis

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| matrix representation `[T]^\beta_\gamma` | Linear Maps | Exact/Both | Linear maps phase |
| coordinate maps | Spaces / Linear Maps | Exact/Both | Linear maps phase |
| composition as matrix multiplication | Linear Maps explanation | Both | Linear maps phase |
| change-of-coordinates matrices | Linear Maps / Spaces | Exact/Both | Linear maps phase |
| changing matrix representations | Linear Maps | Exact/Both | Linear maps phase |

---

## 14. Similarity and invariants

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| similarity definition | Analyze / Linear Maps | Both | Linear maps / eigen phase |
| trace similarity invariant | Analyze | Both | Linear maps / eigen phase |
| determinant similarity invariant | Analyze | Both | Linear maps / eigen phase |
| same operator different basis => similar matrices | Linear Maps | Both | Linear maps / eigen phase |

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
| minimal polynomial | Analyze / Eigen and canonical forms | Exact first | Advanced |
| Jordan canonical form | Analyze / Eigen and canonical forms | Exact first | Advanced |

---

## 18. Inner product spaces, norms, distances

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| inner product definition | Orthogonality | Both | Orthogonality |
| standard inner product on `R^n` | Orthogonality / Operate | Both | Orthogonality |
| standard Hermitian product on `C^n` | Orthogonality | Numeric/Both | Orthogonality |
| integral-based product on basis-defined function spaces | Orthogonality advanced | Depends on representation | Later |
| Frobenius inner product | Orthogonality / Analyze | Both | Orthogonality |
| induced norm | Orthogonality | Both | Orthogonality |
| Cauchy-Schwarz | Explanation / checks | Both | Orthogonality |
| triangle inequality | Explanation / checks | Both | Orthogonality |

---

## 19. Orthogonality, Gram-Schmidt, projections

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| orthogonality test | Orthogonality | Both | Orthogonality |
| orthonormal set/basis | Orthogonality | Both | Orthogonality |
| Fourier coefficients | Orthogonality | Both | Orthogonality |
| projection onto vector | Orthogonality | Both | Orthogonality |
| Gram-Schmidt | Orthogonality | Both | Orthogonality |
| projection onto subspace | Orthogonality | Both | Orthogonality |
| orthogonal complement | Orthogonality | Both | Orthogonality |

---

## 20. Least squares

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| least-squares solution | Orthogonality / Analyze | Numeric first | Orthogonality |
| projection interpretation | Orthogonality explanation | Both | Orthogonality |

---

## 21. Applications and extended roadmap

| Feature | Surface | Mode | Milestone |
|---|---|---:|---|
| PageRank demo | Advanced / Examples | Numeric | Advanced |
| SVD and PCA | Advanced / Applied | Numeric | Advanced |
| FEM examples | Advanced / Examples | Numeric | Advanced |


---

## 22. Library, persistence, and sync

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
