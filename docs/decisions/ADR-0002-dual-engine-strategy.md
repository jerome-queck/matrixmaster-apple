# ADR-0002: Dual engine strategy

## Status
Accepted

## Context
Matrix Master needs both educational exact workflows and performant numeric workflows. These have different algorithmic and UX needs.

## Decision
Maintain two explicit computation lanes:
- exact lane
- numeric lane

The app must label results accordingly and avoid silently mixing them.

## Rationale
This supports:
- clean rational row reduction
- exact determinant/inverse/basis reasoning
- stable numeric decompositions
- clear user expectations

## Alternatives considered
- a single floating-point engine for everything
- a single symbolic engine for everything
- ad hoc per-feature switching without a formal mode model

## Consequences
- more engine design work up front
- cleaner long-term behavior
- fewer confusing result mismatches

## Follow-up
Document algorithm assignment by feature in `docs/MATH_ENGINE_SPEC.md`.
