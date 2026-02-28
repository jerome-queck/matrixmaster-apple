# MatrixDomain instructions

## Owns
- shared math object models
- scalar domain descriptors
- vectors, matrices, bases, subspaces, linear maps
- result and step contracts
- validation and error types
- identifiers, tags, and shared option structs

## Must not own
- SwiftUI views
- persistence implementation details
- Accelerate wrappers
- feature navigation logic

## Design rules
- keep types explicit and readable
- preserve field/basis metadata where it changes semantics
- avoid leaking UI concerns into domain types
- prefer immutable value types where practical

## Test expectations
- domain invariants
- Codable round-trips where applicable
- clear equality/hash behavior for stable identifiers and reusable payloads
