# MatrixNumeric instructions

## Owns
- dense numeric matrix types or wrappers
- Accelerate-backed operations
- LU / QR / SVD / eigen workflows
- least squares
- norms, residuals, reconstruction checks
- tolerance handling
- later sparse and iterative algorithms

## Must not own
- exact symbolic arithmetic
- UI rendering
- persistence
- feature routing

## Design rules
- prefer numerically stable methods
- report diagnostics and warnings
- centralize tolerance profiles
- isolate external math APIs behind wrappers

## Test expectations
- decomposition reconstruction
- residual checks
- tolerance-sensitive edge cases
- near-singular warning behavior
