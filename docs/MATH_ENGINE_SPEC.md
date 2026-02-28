# Math engine specification

## Goal

Provide a mathematically credible engine that supports both educational exact workflows and performant numeric workflows.

## Fundamental design rule

The engine must maintain two explicit lanes:

- **Exact lane**
- **Numeric lane**

The UI must never leave the user guessing which lane produced a result.

---

## Scalar support

### Exact lane
Support:
- integers
- rational numbers
- symbolic names where needed for certain educational workflows
- optionally exact polynomial/rational expressions for advanced exact tasks

### Numeric lane
Support:
- real floating-point values
- complex floating-point values

---

## Field handling

Make the active field explicit whenever it changes mathematics:

- `R`
- `C`

Examples where the field matters:
- eigenvalues
- diagonalizability
- inner products in complex spaces
- polynomial factorization behavior

---

## Exact lane responsibilities

Use the exact lane for:

- Gaussian elimination and Gauss-Jordan elimination over rationals
- REF and RREF
- pivot/free variable analysis
- homogeneous and nonhomogeneous solution sets
- determinant by elimination
- determinant by cofactor expansion for small matrices
- adjugate / cofactor / minor workflows
- inverse by row reduction
- inverse by adjugate for small matrices
- Cramer's rule
- span membership
- linear independence/dependence
- basis extraction
- coordinate vectors
- subspace sum and intersection through coordinate/system logic
- exact null space basis
- exact change-of-basis matrices
- exact characteristic polynomial for small matrices
- exact minimal polynomial for advanced exact workflows

### Exact engine implementation notes
- use arbitrary-precision integer support
- an internal BigInt adapter may wrap one approved small SPM dependency if needed
- build rational numbers as normalized sign + numerator + denominator
- reduce fractions aggressively
- avoid silent conversion to floating-point
- keep derivation steps aligned with the exact operations performed

---

## Numeric lane responsibilities

Use the numeric lane for:

- dense matrix decomposition
- LU decomposition
- QR decomposition
- SVD
- eigenvalue/eigenvector workflows
- least squares
- norms and residuals
- matrix powers for larger numeric cases
- conditioning and warnings
- later sparse/iterative workflows

### Numeric engine implementation notes
- use Accelerate-backed operations where practical
- standardize tolerance handling
- provide residual checks and reconstruction checks
- prefer stable algorithms over pretty formulas

---

## Algorithm policy by feature

### Systems of linear equations
Primary method:
- exact row reduction in exact mode
- stable numeric decomposition in numeric mode for large dense systems

Current implementation baseline (Phase 4 closure):
- exact Solve uses rational Gauss-Jordan reduction on augmented matrices
- numeric Solve uses tolerance-aware floating-point row reduction on augmented matrices
- Solve emits row-operation trace steps and classifies systems as unique / infinitely many / inconsistent
- Solve emits reusable payloads for coefficient matrices, reduced matrices, and unique-solution vectors when available
- exact Operate covers matrix/vector arithmetic, transpose/trace/powers, matrix-vector products, and expression-routed operations
- numeric Operate covers the same operation family with tolerance-aware parsing and reusable payload output
- exact Analyze computes determinant, rank, nullity, trace, and rendered inverse-matrix output over rationals
- numeric Analyze computes rank, nullity, trace, determinant, LU and QR summaries, SVD-baseline singular spectrum, dominant-eigen baseline, and rendered inverse-matrix output with tolerance reporting
- exact and numeric Analyze now emit column-space, row-space, and null-space basis witnesses from pivot/RREF analysis
- exact and numeric Analyze now emit rank-nullity identity diagnostics and reusable basis-matrix payloads
- exact and numeric Analyze now support span-membership workflows with basis vectors and target-vector coefficients when in span
- exact and numeric Analyze now support independence/dependence workflows with explicit dependence coefficients when dependent
- exact and numeric Analyze now support coordinate-vector workflows for ordered basis input with coefficient outputs when uniquely determined
- exact and numeric Analyze now report full coordinate-family diagnostics for non-unique coordinate systems with witness plus every nullspace-basis direction payload
- fundamental-subspace basis payload matrices now use consistent vectors-as-columns orientation for column/row/null outputs
- exact and numeric Spaces workflows now support basis test/extract, basis extend/prune, subspace sum/intersection, and direct-sum checks via explicit `spacesKind` routing
- Spaces editor workflows now include abstract-space presets for polynomial spaces (`P_n(F)`) and matrix spaces (`M_mxn(F)`) that prefill canonical basis templates
- exact and numeric Analyze now support dedicated linear-map workflows with definition by matrix or basis-image matrix input
- exact and numeric Analyze now compute kernel/range basis witnesses, rank/nullity, and injective-surjective-bijective diagnostics for linear maps
- exact and numeric Analyze now compute basis-relative map matrices (`[T]^beta_gamma`), change-of-coordinates matrices, and basis-change similarity diagnostics with trace/determinant invariants
- exact and numeric linear-map diagnostics now provide explicit similarity not-applicable guidance when input describes a non-endomorphism (`R^m -> R^n`, `m != n`)

Outputs:
- consistency
- unique / infinite / no solution
- free variable description
- parametric solution form
- null space basis for homogeneous systems
- row-operation trace where applicable

### Determinant
Default:
- elimination/LU based

Educational alternates:
- cofactor expansion for small matrices
- permutation formula only for tiny matrices or explicit teaching mode

### Inverse
Default:
- row reduction exact mode for educational/symbolic cases
- factorization-backed numeric inverse only when necessary

The UI should encourage solving systems directly rather than pushing inverse as the first hammer for every nail.

### LU decomposition
Use for:
- repeated solves
- determinant computation
- instructional comparison with elimination

### Basis and span workflows
Reduce to:
- system solving
- pivot analysis
- rank logic
- coordinate construction

Every yes/no decision should provide a witness:
- coefficients
- dependence relation
- extracted basis
- decomposition

### Fundamental subspaces
Compute:
- column space basis from pivot columns of original matrix
- row space basis from nonzero rows of echelon/reduced form
- null space basis from free-variable parameterization
- optional left null space later if exposed explicitly
- reusable basis-matrix payloads should encode basis vectors as columns regardless of source subspace

### Linear transformations
Support definitions by:
- matrix
- images of basis vectors
- coordinate formula when feasible

Compute:
- kernel
- range
- rank
- nullity
- injectivity/surjectivity/bijectivity
- matrix representation relative to selected bases

### Change of basis
Treat basis order as part of the type-level meaning.
Coordinate results must always display the basis they belong to.

### Eigen and diagonalization
Numeric mode:
- use stable library-backed routines
- report approximate results with tolerance and reconstruction diagnostics

Exact mode:
- use symbolic characteristic polynomial and exact eigenspace logic only on manageable sizes

### Minimal polynomial and Jordan form
Keep these as later exact-first workflows.
Do not present Jordan form as a numerically stable everyday feature for floating-point inputs.
When these tools ship, place them in normal Analyze eigen/canonical-form navigation and search rather than a hidden Advanced-only area.

### Inner products and orthogonality
Support:
- standard real inner product
- standard complex Hermitian inner product
- Frobenius matrix inner product
- basis-defined finite-dimensional inner products
- optional polynomial/function-space inner products via finite basis representations

### Gram-Schmidt
Implement with:
- clear step tracing
- numerical safeguards in numeric mode
- degeneracy handling and near-dependence warnings

### Least squares
Preferred numeric computation:
- QR or SVD based

Normal equations:
- explain conceptually
- do not make them the default numeric path

---

## Step-trace policy

Not every algorithm needs the same step depth.

### Full educational trace
Use for:
- row reduction
- determinant by cofactor or elimination
- inverse by row reduction
- span / basis / null space derivations
- Gram-Schmidt

### Summary trace
Use for:
- LU / QR / SVD / eigen numeric workflows
- least squares
- large matrix operations

### No trace or minimal trace
Use when:
- output would be overwhelmingly large
- the computation is library-backed and the educational value of full internals is low

---

## Tolerance policy

Numeric workflows must centralize tolerance handling.

For each numeric result, be able to report:
- absolute / relative tolerance profile
- residual norm
- reconstruction error where relevant
- warning if a classification is near a threshold

Examples:
- rank depends on tolerance
- diagonalizable classification may be numerically ambiguous
- near-singular matrices require warning copy

---

## Engine API shape

The exact syntax is up to implementation, but conceptually each engine function should accept:
- typed request
- computation options
- trace level
- field or numeric mode
- cancellation context if needed

And should return:
- typed result
- diagnostics
- warnings
- optional steps
- reusable payloads

---

## Math quality guardrails

- never silently coerce exact results to approximate ones
- never hide field assumptions
- never label a tolerance-sensitive numeric classification as absolutely exact
- never default to an unstable method just because it is short to write
