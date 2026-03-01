# Screen flows

This file describes the intended user flows for the major surfaces.

## 1. Solve flow

### Entry
User taps **Solve**.

### Initial screen
Show:
- matrix/system input editor
- toggle for coefficient matrix + RHS vector vs full augmented matrix
- exact/numeric mode selector if relevant
- presets and paste controls
- primary action: **Solve**

### After solve
Show:
1. primary answer summary card
2. structured math object cards (matrix/vector/polynomial views where applicable)
3. explicit REF/RREF matrix panels
4. consistency and solution-count classification diagnostics
5. reuse actions:
   - save result
   - send coefficient matrix to Analyze
   - send solution vector to Operate
6. step trace
7. explanation card
8. save/reuse actions (result-object copy/export remains follow-up)

### Branch flows
- inverse via row reduction from solve result
- null-space basis for homogeneous system
- export steps or matrix data

---

## 2. Operate flow

### Entry
User taps **Operate**.

### Initial screen
Show:
- named matrix tray
- matrix/vector editor
- expression entry or visual builder
- examples
- primary action: **Evaluate**

### After evaluate
Show:
1. result object
2. result type and dimensions
3. reuse actions
4. optional derivation summary
5. explanation/theory if relevant
6. export/copy

### Branch flows
- save as named matrix
- send square result to Analyze
- send vector result to Spaces or Orthogonality if supported later

---

## 3. Analyze flow

### Entry
User taps **Analyze**.

### Analyze categories
Provide a clear segmented or sidebar organization:
- Matrix properties
- Subspaces and bases
- Linear maps
- Eigen and canonical forms
- Result presentation and formatting
- Orthogonality and least squares
- Applied/later extras when populated

### Matrix properties subflow
Tools:
- determinant
- rank
- trace
- inverse
- LU / QR / SVD
- symmetry/invertibility checks

### Subspaces and bases subflow
Tools:
- span membership
- independence
- basis extraction
- column/row/null spaces
- coordinates and dimension
- Spaces presets for `P_n(F)` and `M_mxn(F)` that prefill generating sets

### Linear maps subflow
Tools:
- define map (by matrix or basis images)
- kernel/range
- injective/surjective/bijective
- basis-relative matrix representation `[T]^beta_gamma`
- change-of-coordinates matrices
- similarity from basis change (with trace/determinant invariants)
- explicit "similarity not applicable" diagnostics when basis input describes a non-endomorphism map

### Eigen and canonical forms subflow
Tools:
- eigenvalues/eigenvectors
- eigenspaces
- characteristic polynomial
- diagonalization
- minimal polynomial when implemented
- Jordan form when implemented
- fast powers

### Orthogonality and least-squares subflow
Tools:
- inner products
- norms/distances
- Gram-Schmidt
- projections
- least squares

### Result presentation and formatting subflow
Current baseline:
- matrix-looking result rendering (grid/bracket object view)
- vector/polynomial object rendering
- explicit REF/RREF matrix panels for elimination workflows
- structured answer/diagnostics/steps cards with reusable payload actions
- destination-scoped result visibility (results shown only in the tab where they were computed)

### Applied/later extras subflow
Tools:
- sparse/iterative extras later

---

## 4. Library flow

### Entry
User taps **Library**.

### Initial screen
Show:
- recent items
- saved objects
- workspaces
- search
- filter chips or folders/tags
- sync/account status summary

### Library item actions
Each item should support:
- open/use
- rename
- duplicate
- export
- delete
- inspect metadata
- inspect sync state where relevant

### Branch flows
- open full workspace
- insert object into active workflow
- batch export selected items later if desired
- review recovery copy after sync conflict
- retry sync for item or account state when applicable

---

## 5. Global search / command palette flow

### Trigger
- Mac: keyboard shortcut
- iPad with keyboard: same shortcut
- iPhone: search field on Library/Analyze

### Search targets
- tools
- saved objects
- recent actions
- help topics later

### Action examples
- "determinant"
- "null space"
- "least squares"
- "Gram-Schmidt"
- "recent workspace"

---

## 6. Reuse flow

Every result page should provide a consistent reuse menu:
- use as input in another workflow
- save to library
- duplicate into named object
- copy/export

This should be consistent across Solve, Operate, and Analyze to reduce cognitive load.

---

## 7. Sync/account-state flow

### Normal path
User saves or updates a workspace.

Show:
- saved locally confirmation
- sync state that updates to synced when available
- last-updated metadata in Library item detail

### Offline or signed-out path
Show:
- local-only or waiting-to-sync state
- plain-language explanation
- no blocking of math workflows

### Conflict path
If concurrent edits diverge:
- preserve a recoverable copy
- show a clear Library recovery entry
- let the user open both versions and clean up later
