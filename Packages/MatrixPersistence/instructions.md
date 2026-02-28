# MatrixPersistence instructions

## Owns
- SwiftData persistence
- snapshot encoding/decoding
- import/export formats
- versioning and migrations
- library and history storage services
- cloud sync coordination for eligible user data
- sync metadata, delete propagation, and conflict recovery policy

## Must not own
- heavy domain algorithms
- UI layout
- feature orchestration logic

## Design rules
- version schemas from day one
- prefer explicit migrations
- keep file formats clear and portable
- make `.mmws` the canonical native workspace document for the new codebase
- treat any legacy `.mmatrix` importer as compatibility-only work, not the native baseline
- local writes come before cloud sync
- keep the app usable offline or signed out of cloud services
- surface import/export and sync errors cleanly
- prefer recoverable conflict handling over silent overwrite

## Test expectations
- save/load round-trips
- migration fixtures
- invalid-file handling
- library/history indexing behavior
- sync queue/convergence tests
- conflict recovery tests
- signed-out/offline fallback tests
