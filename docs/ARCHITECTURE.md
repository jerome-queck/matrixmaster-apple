# Architecture

## Overview

Matrix Master should be a modular Swift codebase with shared logic and thin app shells.

The architecture should make it easy to:
- test algorithms independently of UI
- add workflows without turning the app into a giant state blob
- keep exact and numeric computation engines separate
- share code across iPhone, iPad, and Mac while preserving platform polish and first-release parity
- sync eligible user data across devices without giving up local responsiveness

## Repository modules

### Apps

#### `Apps/MatrixMasterMobile`
Responsibilities:
- iPhone and iPad app shell
- platform-specific scene and navigation setup
- mobile-specific windowing and quick actions

#### `Apps/MatrixMasterMac`
Responsibilities:
- Mac app shell
- menu commands
- multiwindow behavior
- Mac-only inspectors and keyboard affordances

For the first public release, both app shells must expose the same core workflows even when their navigation chrome differs.

### Packages

#### `MatrixDomain`
Owns:
- scalar domain descriptors
- matrix/vector data types
- basis and subspace types
- linear map types
- result and step models
- request/response contracts
- validation errors
- shared identifiers and tags

#### `MatrixExact`
Owns:
- arbitrary-precision integer abstraction or wrapper
- rational arithmetic
- exact matrix algorithms
- exact system solving
- determinant/cofactor/adjugate logic
- span / basis / coordinate algorithms
- exact characteristic/minimal polynomial logic for manageable sizes
- an internal adapter around any approved BigInt dependency

#### `MatrixNumeric`
Owns:
- dense real/complex matrix representations
- Accelerate wrappers
- LU / QR / SVD / eigen workflows
- least squares routines
- tolerance profiles
- residual and conditioning diagnostics
- later sparse/iterative functionality

#### `MatrixPersistence`
Owns:
- SwiftData models
- workspace snapshot formats, including the native `.mmws` workspace document
- import/export codecs
- migration/versioning
- recent items and library metadata
- sync metadata, change journals, and conflict recovery policy
- private-cloud replication services for eligible user data

#### `MatrixUI`
Owns:
- design tokens
- matrix editor views
- vector and basis editors
- reusable result cards
- step timelines
- inspectors
- empty states
- accessibility helper wrappers
- reusable sync status components where needed

#### `MatrixFeatures`
Owns:
- user-facing feature coordinators and flows
- Solve, Operate, Analyze, Library feature modules
- tool search registry
- workflow orchestration
- cross-feature result handoff
- sync-aware library and recovery actions

#### `MatrixAutomation`
Owns:
- App Intents
- Spotlight/Shortcuts exposure
- future automation entry points

## Dependency direction

Prefer this dependency flow:

```text
Apps -> MatrixFeatures -> {MatrixUI, MatrixPersistence, MatrixExact, MatrixNumeric, MatrixDomain, MatrixAutomation}
MatrixUI -> MatrixDomain
MatrixPersistence -> MatrixDomain
MatrixExact -> MatrixDomain
MatrixNumeric -> MatrixDomain
MatrixAutomation -> MatrixDomain
MatrixDomain -> (no internal package dependencies)
```

Keep `MatrixDomain` at the bottom. It should not import feature or UI code.

## App-wide data flow

1. User edits an object in a feature editor.
2. Editor validates and constructs a typed request.
3. Feature coordinator selects exact or numeric engine.
4. Engine returns a result object plus optional derivation steps and diagnostics.
5. Feature layer stores the result in current workspace state.
6. UI renders the result summary, steps, and reuse actions.
7. Persistence stores eligible state locally first, then syncs it opportunistically when cloud state allows.

## State model

Use a layered state approach:

### Ephemeral view state
- focused field
- selected tab
- expanded step sections
- transient filters
- unsaved input warnings
- in-flight sync banners or retry prompts

### Workspace state
- current matrices/vectors/bases/maps
- current tool mode
- recent results
- session-local named objects
- current export preferences

### Persistent state
- saved library items
- workspace snapshots
- settings
- theme/accessibility preferences where appropriate
- recent file references
- versioned migrations
- sync identifiers, revision markers, tombstones, and last-known sync status

## Cloud sync model

Use a local-first sync model:
- every user write commits locally first
- eligible persistent items replicate through the user's private cloud account
- sync should cover saved workspaces, saved library objects, folders/tags, and continuity-relevant settings
- ephemeral UI state, caches, undo stacks, and device-only affordances stay local
- signed-out or unavailable cloud state must leave the app fully usable locally
- no real-time multi-user collaboration is required in v1

For conflicts, prefer recovery over silent data loss:
- metadata-only conflicts can use deterministic last-writer-wins rules where safe
- divergent workspace content should preserve a recoverable copy rather than silently overwriting one version
- deletions should propagate through tombstones rather than rely on implicit delete behavior

## Feature composition

Each feature should expose:
- input model
- request builder
- validation rules
- result renderer
- reuse adapters
- persistence adapters if needed
- sync/recovery affordances where persisted user data is involved

Do not let one feature reach directly into another feature's private implementation.

## Concurrency model

Use Swift concurrency, not ad hoc callback tangles.

Recommended structure:
- computation actors for long-running math
- cancelable tasks for user-triggered operations
- request hashing for duplicate suppression if helpful
- factorization caches for repeated computations
- clear separation between UI state updates and engine execution
- background sync tasks isolated from UI rendering concerns

## Result model

All results should conform to a common shape conceptually:
- identity
- kind
- primary output
- secondary diagnostics
- derivation steps
- explanation metadata
- reusable payloads
- export payloads

This enables a shared result surface across workflows.

## Error model

Distinguish:
- parse errors
- validation errors
- unsupported-operation errors
- mathematical impossibility
- numeric instability warnings
- persistence/import errors
- sync/account-state errors

These should be typed and mapped to user-friendly copy.

## Search and tool discovery

Maintain a tool registry with:
- tool id
- display name
- search keywords
- category
- supported input object types
- feature route
- examples

This supports search and command palette behavior.

## Architecture guardrails

- no all-knowing app singleton
- no giant feature enum with dozens of unrelated responsibilities
- no algorithm code inside view bodies
- no persistence model leakage into math engine internals
- no hidden dependency on old repository concepts
- no cloud-first design that breaks offline use
