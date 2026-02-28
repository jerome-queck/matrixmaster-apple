# ADR-0006: Linear-map basis convention and similarity diagnostics

## Status
Accepted

## Context
Phase 4 introduces linear-map workflows that cross between standard-coordinate matrices, basis-image definitions, basis-relative map matrices, coordinate-change matrices, and similarity diagnostics. Without one shared convention, these workflows are easy to implement inconsistently.

## Decision
Adopt one repository-wide convention for finite-dimensional linear maps:
- basis vectors are encoded as matrix columns
- with domain basis matrix `B`, codomain basis matrix `G`, and standard map matrix `A`, use:
  - `[T]^beta_gamma = G^-1 * A * B`
- for compatible basis pairs in the same ambient space, use:
  - `C_(gamma<-beta) = G^-1 * B`
  - `C_(beta<-gamma) = B^-1 * G`
- for endomorphism similarity diagnostics, use:
  - `[T]_gamma = C_(gamma<-beta) * [T]_beta * C_(beta<-gamma)`
- similarity diagnostics should report trace and determinant invariants where representations are comparable.
- when the input map is not an endomorphism (`dim(domain) != dim(codomain)`), similarity output should be marked not applicable with explicit diagnostic guidance rather than silent omission.

## Rationale
This keeps exact and numeric implementations aligned, makes reusable payload interpretation predictable, and prevents direction/order ambiguity in basis-change and similarity outputs.

## Alternatives considered
- row-vector basis conventions
- mixed conventions by workflow (for example, basis-images as rows but kernels/ranges as columns)
- omitting explicit coordinate-change direction labels

## Consequences
- linear-map request/result implementations in exact and numeric engines share identical basis-direction semantics
- reusable payload naming can remain stable across workflows
- future eigenspace/diagonalization work can build on the same basis-change direction rules without re-litigating orientation

## Follow-up
Keep formulas and naming synchronized in:
- `docs/MATH_ENGINE_SPEC.md`
- `docs/FEATURE_MATRIX.md`
- `docs/SCREEN_FLOWS.md`
