# MatrixUI instructions

## Owns
- shared design tokens
- reusable SwiftUI components
- matrix/vector/basis editors
- result cards
- step displays
- inspector components
- empty and error states
- sync status and recovery-status UI primitives where shared
- accessibility helpers

## Must not own
- core math algorithms
- persistence implementation
- feature-specific business rules

## Design rules
- answer-first presentation
- optimize quick compute/save/reuse flows before educational chrome
- strong accessibility labels
- scalable layouts for larger text
- reuse components across platforms where sensible
- allow platform-specific composition above the primitive layer
- make sync/account-state components understandable without technical jargon

## Test expectations
- snapshot/smoke tests where feasible
- accessibility labels on reusable controls
- editor interaction tests
- accessibility checks for shared sync/account-state components
