# Test strategy

## Goal

Make Matrix Master trustworthy.

The app should not merely look persuasive. It should survive mathematical, workflow, persistence, and sync scrutiny.

## Test layers

### 1. Arithmetic and parser tests
Cover:
- integer sign handling
- rational normalization
- gcd reduction
- zero denominator rejection
- decimal parsing
- fraction parsing
- complex parsing if enabled
- expression parsing and precedence

### 2. Exact algorithm tests
Cover:
- REF/RREF correctness
- pivot detection
- free-variable handling
- determinant identities
- inverse reconstruction
- Cramer's rule correctness
- basis extraction
- coordinate vector correctness
- null space basis correctness
- change-of-basis round trips
- exact projection identities where supported

### 3. Numeric algorithm tests
Cover:
- LU reconstruction
- QR orthogonality and reconstruction
- SVD reconstruction
- eigenpair residual checks
- least-squares residual minimization
- tolerance-sensitive rank behavior
- conditioning warnings on near-singular examples

### 4. Persistence and migration tests
Cover:
- save/load flows
- `.mmws` snapshot round-trips
- migration fixtures
- invalid-file handling
- export/import fidelity for supported formats
- stable identifier preservation across saves and restores

### 5. Sync and account-state tests
Cover:
- local write before remote sync
- offline edit queueing and later reconciliation
- cross-device convergence for saved workspaces and library items
- signed-out or unavailable-cloud fallback behavior
- delete propagation / tombstone behavior where implemented
- conflict recovery for concurrent edits
- status transitions such as local-only, syncing, synced, and needs-attention

### 6. Workflow tests
Cover:
- result reuse
- save/load flows
- switching between exact and numeric modes
- exporting selected outputs
- reopening a saved workspace
- sync-aware Library actions and recovery flows
- Spaces preset application flows (polynomial and matrix-space templates)
- linear-map similarity diagnostics for both endomorphism and non-endomorphism inputs

### 7. UI tests
Cover:
- matrix editor keyboard navigation
- common task completion
- navigation on iPhone, iPad, and Mac
- accessibility labels for major surfaces
- larger text layout sanity for common tasks
- sync status visibility in Library and relevant item detail surfaces

## Test fixture design

Maintain a fixture catalog containing:
- tiny matrices with known exact answers
- singular and nonsingular examples
- dependent/independent vector sets
- basis and non-basis examples
- diagonalizable and non-diagonalizable matrices
- orthogonal and near-dependent sets
- least-squares examples with known solutions
- persistence fixtures with older snapshot versions
- sync fixtures with concurrent edits and delete/recover cases

## Property-style checks

Useful invariants:
- `A * A^{-1} = I` when invertible
- `det(AB) = det(A)det(B)` on manageable exact fixtures
- row rank = column rank
- rank + nullity = number of columns
- projection idempotence where relevant
- orthonormal outputs have unit norm and pairwise orthogonality
- change-of-basis round trips recover original coordinates
- basis-change similarity preserves trace and determinant for endomorphisms
- non-endomorphism linear-map inputs report similarity as not applicable with explicit diagnostics

## Golden step traces

For educational workflows, keep a curated set of golden traces:
- row reduction examples
- determinant elimination examples
- inverse by row reduction
- Gram-Schmidt steps

These protect against accidental regressions in step sequencing and explanations.

## Numeric tolerance policy

Centralize tolerances and use feature-specific thresholds where necessary.

Tests should assert:
- residuals below configured thresholds
- reconstructions within tolerance
- warnings appear when cases are ill-conditioned or near-singular

## Accessibility testing

For common tasks, verify:
- VoiceOver labels exist on primary actions and editor cells
- larger text does not break common tasks
- keyboard-only completion is possible on iPad/Mac
- critical feedback is not color-only

## CI expectations

At minimum, CI should run:
- unit tests
- algorithm tests
- persistence/migration tests
- mocked sync-state tests
- any fast UI smoke tests
- lint/format if configured

Longer-running device-based or account-backed sync suites can be split if needed, but the release process should still include real cross-device smoke coverage before shipping.

## Test completion rule

A feature is not complete if it has:
- only happy-path tests
- no regression fixtures
- no accessibility thought
- no numeric sanity checks where approximation is involved
- no offline/sync behavior coverage where persisted user data changes
