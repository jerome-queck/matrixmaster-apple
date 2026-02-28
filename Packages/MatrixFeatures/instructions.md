# MatrixFeatures instructions

## Owns
- Solve, Operate, Analyze, and Library workflows
- tool registry and search metadata
- feature coordinators/view models
- result reuse across workflows
- workflow-level validation and action handling
- sync-aware Library actions and recovery flows

## Must not own
- low-level numeric kernels
- exact arithmetic internals
- persistence storage details beyond using service interfaces

## Design rules
- one feature surface should not reach into another's private state
- feature code should depend on shared contracts, not ad hoc glue
- keep common task flows obvious
- optimize for calculator/productivity speed in the first release
- preserve result reuse and discoverability
- when minimal polynomial and Jordan form ship, register them under Analyze's eigen/canonical forms grouping rather than a hidden Advanced bucket
- keep sync actions understandable and close to the affected content

## Test expectations
- workflow tests
- result handoff tests
- mode switching tests
- save/reuse/export flow checks
- sync-state and recovery-flow checks where Library behavior is involved
