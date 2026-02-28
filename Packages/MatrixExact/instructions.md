# MatrixExact instructions

## Owns
- arbitrary-precision integer abstraction or wrapper
- rational arithmetic
- exact row reduction
- determinant / cofactors / adjugate
- exact inverse workflows
- exact basis/span/coordinate algorithms
- exact polynomial workflows where in scope

## Must not own
- SwiftUI concerns
- persistence layer
- platform navigation
- vague numeric shortcuts that silently lose exactness

## Design rules
- never silently coerce exact values to floating-point
- keep step traces aligned with actual operations
- centralize normalization and simplification
- if a BigInt package is used, wrap it behind an internal adapter and keep the dependency surface narrow
- make error cases explicit

## Test expectations
- arithmetic fixtures
- elimination fixtures
- determinant/inverse identities
- basis and coordinate fixtures
- regression tests for tricky rational cases
