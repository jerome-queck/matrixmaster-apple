# Feature backlog

This file tracks future work beyond the current completed checkpoint.
Some items are explicitly scheduled for the next phase, while others remain later backlog.

## Phase transition carry-over (completed)
- Completed in Phase 4:
  - richer multi-solution coordinate-family diagnostics (full family parameterization beyond single witness + one nullspace direction)
  - math typography baseline across result surfaces (consistent superscript/subscript/fraction rendering in answer, diagnostics, and steps)
  - abstract-space presets for Spaces workflows (polynomial-space and matrix-space templates, including direct apply actions for generating sets)
- Completed in Phase 5:
  - structured matrix rendering in result surfaces (matrix brackets/grid layout instead of plain inline text)
  - structured vector/polynomial rendering for reusable math objects
  - explicit REF/RREF matrix panels for Solve and elimination-backed Analyze outputs
  - native polynomial-space element editors (for example coefficient entry against `{1, x, x^2, ...}`)
  - native matrix-space element editors that let users enter basis vectors as matrix objects directly

## Phase 6 orthogonality and least-squares scope (next)
- inner products, norms, and distance workflows
- orthogonality checks and orthonormal basis workflows
- Gram-Schmidt process views
- projection onto vectors/subspaces and orthogonal complements
- least-squares solution and residual interpretation

## UI follow-up polish
- reintroduce result-object copy/export controls (`plain`, `markdown`, `latex`) after final presentation/formatting stabilization

## Advanced algebra
- minimal polynomial
- Jordan canonical form
- permutation-form determinant teaching mode
- adjugate-only educational path toggles

When minimal polynomial and Jordan form land, expose them under normal Analyze canonical-forms navigation rather than a buried Advanced bucket.

## Sparse and iterative tools
- sparse matrix inspector
- CSR/CSC views
- Jacobi
- Gauss-Seidel
- Conjugate Gradient
- GMRES
- preconditioning tooling
- convergence plots

## Applied modules
- PageRank demo
- SVD/PCA learning workspace
- least-squares data fitting visualizer
- FEM-inspired examples

## Study tooling
- example packs
- challenge mode
- step-hint mode
- glossary cards
- theorem reference index

These stay intentionally out of the first-release critical path because the product posture is calculator/productivity first.

## Library and workflow niceties
- pinned favorites
- richer tagging
- side-by-side result comparison
- workspace snapshots/time travel
- report templates
- richer sync history inspection

## Collaboration and sharing beyond v1 sync
- shared workspaces
- real-time multi-user editing
- comment threads or annotations
- team/shared folders

Cross-device sync for a single user's own devices is part of the main product baseline now. The items above are additional cloud ambitions that should stay out of the first-release critical path.
