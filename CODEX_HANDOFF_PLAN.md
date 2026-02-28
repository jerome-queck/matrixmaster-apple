# Matrix Master - Ground-Up Codex Build Plan

## Purpose

This document is the master handoff package for building **Matrix Master** from an empty workspace using Codex. It assumes **no legacy source files are present**. Any older repository may be consulted only as a **product and workflow reference**. **No code, file layout, or implementation should be copied or ported from the old repository, and the deliverable should be treated as a first-of-its-kind primary codebase rather than a patch stream.**

The mission is to build a **native SwiftUI multiplatform app** for **iPhone, iPad, and Mac** with a strong emphasis on:

- fast, intuitive workflows
- mathematically correct computations
- exact and numeric computation modes
- high accessibility
- local-first persistence with cloud sync
- reusable results and explanation-on-demand

---

## Hard constraints

1. **Build everything from scratch.**
   - Do not copy old files.
   - Do not mirror the old file tree just because it exists.
   - Do not translate TypeScript or React code into Swift line by line.
   - Re-derive algorithms from mathematics and platform APIs.

2. **Use the old repo only as inspiration for product behavior.**
   - Preserve ideas like:
     - three obvious primary workflows
     - offline-first operation
     - step-by-step derivations
     - result handoff between tools
     - history / saved objects / export / documentation
   - Do not preserve its code architecture.

3. **Target Apple platforms cleanly.**
   - Shared SwiftUI experience across iOS, iPadOS, and macOS.
   - Mac should feel native, not like a stretched phone UI.
   - iPad should use a two-pane or split-view layout where appropriate.
   - iPhone should optimize for fast single-task workflows.

4. **Treat UX as a first-class requirement.**
   - Every common task should be discoverable within 1-2 interactions.
   - Answer-first results.
   - Progressive disclosure for advanced tools.
   - Reuse previous results without retyping.

5. **Mathematical correctness beats breadth.**
   - Ship stable, correct features before exotic ones.
   - Separate exact symbolic workflows from floating-point workflows.
   - Show field assumptions and tolerance behavior explicitly.

---

## Owner-confirmed decisions

These decisions are locked for this package:

- use a fresh native workspace format with the `.mmws` extension
- ship the first public release on iPhone, iPad, and Mac together
- keep the product posture calculator/productivity first
- allow one small BigInt SPM dependency for exact arithmetic if it is justified, wrapped, and documented in an ADR
- place minimal polynomial and Jordan form in normal Analyze information architecture when they ship, not in a hidden Advanced-only area
- include cloud sync for the user's own devices while preserving local-first/offline behavior
- treat the deliverable repository as the primary greenfield implementation, not a patch/diff against an older codebase

---

## Product behaviors worth carrying forward conceptually

These ideas are worth preserving conceptually:

- offline-first workspace
- cross-device continuity through cloud sync
- three primary top-level workflows:
  - Solve
  - Operate
  - Analyze
- advanced tools discoverable without clogging first-run surfaces
- step-by-step elimination and worked results
- library / history / project state
- export and share flows
- optional tutor-style explanations
- ability to take a result and reuse it in another tool

This is the **behavioral DNA** of the new app, even though the codebase itself is greenfield.

---

## Delivery strategy

Codex must execute work in the following order:

1. create documentation and repo instructions
2. create the Xcode workspace and internal package structure
3. build the shared domain and math engine foundations
4. build the matrix/vector input system
5. ship the first vertical slice:
   - Solve
   - Operate
   - Analyze
6. add persistence, export, history, and cloud sync
7. add the vector-space / basis layer
8. add linear transformations and change-of-basis workflows
9. add orthogonality, projections, and least squares
10. add advanced exact and applied topics later

Codex should not jump ahead to Jordan form, PCA, plugin systems, or sparse iterative solvers before the core workflows are solid.

---

## Final repository shape

Codex should create a new repository with this shape:

```text
MatrixMaster/
  instructions.md
  README.md
  BOOTSTRAP_PROMPT_FOR_CODEX.md
  CODEX_HANDOFF_PLAN.md

  Apps/
    MatrixMasterMobile/
      instructions.md
    MatrixMasterMac/
      instructions.md

  Packages/
    MatrixDomain/
      instructions.md
    MatrixExact/
      instructions.md
    MatrixNumeric/
      instructions.md
    MatrixPersistence/
      instructions.md
    MatrixUI/
      instructions.md
    MatrixFeatures/
      instructions.md
    MatrixAutomation/
      instructions.md

  docs/
    START_HERE.md
    PRODUCT_REQUIREMENTS.md
    UX_SPEC.md
    ARCHITECTURE.md
    MATH_ENGINE_SPEC.md
    PERSISTENCE_AND_EXPORTS.md
    IMPLEMENTATION_ROADMAP.md
    TEST_STRATEGY.md
    DOCUMENTATION_GOVERNANCE.md
    DEPENDENCY_POLICY.md
    FEATURE_BACKLOG.md
    REPO_BOOTSTRAP_CHECKLIST.md

    decisions/
      ADR-0001-platform-baseline.md
      ADR-0002-dual-engine-strategy.md
      ADR-0003-native-workspace-format.md
      ADR-0004-exact-arithmetic-dependency-budget.md
      ADR-0005-cloud-sync-baseline.md

    templates/
      ADR_TEMPLATE.md
      TASK_TEMPLATE.md
      SESSION_LOG_TEMPLATE.md
      PR_SUMMARY_TEMPLATE.md
```

This markdown-first structure is deliberate. It forces Codex to encode product, architecture, and quality rules before the repo accumulates unstructured code.

---

## Required build stack

Codex should build with these principles:

- **Language:** Swift
- **UI:** SwiftUI
- **Persistence:** SwiftData for metadata and local library state
- **Cloud sync:** user-private Apple-cloud sync for eligible workspace/library data
- **Documents:** Codable workspace snapshots and optional document support
- **Numeric linear algebra:** Accelerate / BLAS / LAPACK / sparse solvers where relevant
- **Charts:** Swift Charts where visualization helps
- **Automation:** App Intents for search / shortcuts / quick actions
- **Testing:** XCTest plus targeted UI automation

External dependencies are allowed only when they reduce serious risk and are recorded in an ADR. One small maintained arbitrary-precision integer package is approved in principle for exact rational arithmetic, provided it is wrapped behind an internal adapter. Everything else should default to Apple frameworks and internal code.

---

## Core architectural decisions

### 1. Dual engine strategy

The app must have two distinct computation lanes:

#### Exact lane
Use for:
- row reduction over rationals
- determinant / cofactors / adjugate
- inverse by row reduction or adjugate
- Cramer's rule
- span / basis / coordinate / null space logic
- exact change-of-basis
- exact characteristic and minimal polynomial for small matrices
- educational derivations

#### Numeric lane
Use for:
- large dense matrices
- floating-point or complex numeric input
- LU / QR / SVD / eigen workflows
- least squares
- condition estimates and residual checks
- later sparse and iterative workflows

Do not blur these modes. The UI should always show whether an answer is exact, approximate, tolerance-sensitive, or field-dependent.

### 2. Shared object model

Codex should define clean types for:
- scalar domains
- vectors
- matrices
- finite-dimensional abstract spaces
- bases and ordered bases
- coordinate vectors
- subspaces as spans with metadata
- linear maps and their representations
- inner products
- computation requests
- computation results
- proof / derivation steps
- saved workspaces and exports

### 3. Feature modules

Matrix Master should not be one giant app target with all logic inside view files. Use internal modules with strong boundaries:

- `MatrixDomain` - canonical types and protocols
- `MatrixExact` - exact arithmetic and symbolic algorithms
- `MatrixNumeric` - numeric algorithms and Accelerate wrappers
- `MatrixPersistence` - SwiftData, file import/export, snapshot versioning, sync coordination
- `MatrixUI` - reusable editors, cards, inspectors, result views
- `MatrixFeatures` - user-facing workflows and feature coordinators
- `MatrixAutomation` - App Intents, Spotlight/Shortcuts hooks

### 4. Local-first sync model

- every write lands locally first
- sync eligible saved workspaces and library objects across the user's own devices
- keep manual export/import even when sync exists
- no real-time collaboration in v1
- recover from divergent edits with preserved copies instead of silent overwrite

### 5. Platform shells

- `MatrixMasterMobile`: iPhone + iPad UX
- `MatrixMasterMac`: native Mac UX, menus, keyboard shortcuts, multiple windows

---

## User experience blueprint

### Top-level navigation

The app should present four primary destinations:

1. Solve
2. Operate
3. Analyze
4. Library

Advanced topics should appear within Analyze and Library, not as first-launch clutter.
When minimal polynomial and Jordan form ship, place them under Analyze's eigen/canonical forms family rather than a catch-all Advanced bucket.

### Platform-specific layout

#### iPhone
- Tab-based or compact root navigation
- One focused task per screen
- Bottom action bar for calculate/reset/save/use result

#### iPad
- Split-view with sidebar + detail
- easy drag/drop or panel reuse where appropriate
- keyboard-friendly editing and search

#### Mac
- full sidebar + detail + inspector pattern where useful
- command menus
- search/command palette
- multiwindow support for independent workspaces
- robust drag/drop and copy/paste flows

### Result presentation pattern

Every result screen should use this order:

1. Answer
2. Key facts / diagnostics
3. Reuse actions
4. Steps
5. Explanation / theory
6. Export / share

### Input principles

Every tool must support:
- direct entry
- paste
- load from library
- use previous result

The matrix editor must support:
- adding/removing rows and columns
- paste CSV / TSV / bracket syntax
- exact fractions
- complex input where relevant
- validation without being hostile
- quick random-fill presets for testing and demos

---

## Feature scope by milestone

### Milestone A - Foundation and shell
Codex must create:

- workspace and packages
- app shells for mobile and Mac
- design system tokens
- matrix and vector editors
- core domain models
- result model and step model
- workspace shell navigation
- sync capability shell and local change-tracking baseline
- documentation baseline
- build/test scripts
- CI stub if desired

**Acceptance gate**
- app launches on iPhone, iPad, and Mac
- user can create/edit a matrix
- app persists a simple workspace
- documentation structure exists and is populated

### Milestone B - Core MVP
Build the first serious vertical slice:

- system solving with REF/RREF
- row-operation trace
- solution classification
- matrix operations expression engine
- determinant
- inverse via row reduction
- rank and trace
- LU / QR / SVD / eigen basics in numeric mode
- result reuse between modules
- save/load/history
- cloud sync baseline for saved workspaces and library items

**Acceptance gate**
- the app is useful as a daily linear algebra calculator/productivity tool for coursework and technical work
- all core operations have unit tests and fixture tests
- no workflow requires hidden expert gestures
- signed-in users can move saved work across devices without manual export/import

### Milestone C - Spaces and bases
Build:

- span membership
- linear independence tests
- basis extraction
- ordered bases
- coordinate vectors
- dimension
- column/row/null space basis views
- rank-nullity summaries
- subspace intersection/sum/direct sum helpers

**Acceptance gate**
- users can move from matrices to space-level reasoning without leaving the app
- every boolean conclusion has a certificate or witness

### Milestone D - Linear maps and basis changes
Build:

- define map by matrix or basis images
- kernel/range/rank/nullity
- injective/surjective/bijective checks
- matrix representation relative to bases
- change-of-coordinates matrices
- similarity from basis change
- reusable coordinate conversion workflows

**Acceptance gate**
- the app supports both concrete matrix work and abstract linear maps coherently

### Milestone E - Orthogonality and least squares
Build:

- inner products
- norms and distances
- orthogonality checks
- Gram-Schmidt
- orthonormal bases
- projection onto vector
- projection onto subspace
- orthogonal complements
- least squares

**Acceptance gate**
- least squares is numerically stable
- complex conjugation is handled correctly where applicable

### Milestone F - Advanced exact and applied topics
Only after the above are solid:

- minimal polynomial
- Jordan form
- sparse matrix tooling
- iterative solvers
- SVD/PCA extras
- PageRank demo
- FEM-flavored examples

**Acceptance gate**
- none of these features degrade clarity or reliability of core workflows

---

## Markdown files Codex must create before major coding

The documentation is part of the build, not an afterthought.

### Root
- `instructions.md`
- `README.md`
- `BOOTSTRAP_PROMPT_FOR_CODEX.md`
- `CODEX_HANDOFF_PLAN.md`

### Docs
- `docs/START_HERE.md`
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/UX_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/MATH_ENGINE_SPEC.md`
- `docs/PERSISTENCE_AND_EXPORTS.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/TEST_STRATEGY.md`
- `docs/DOCUMENTATION_GOVERNANCE.md`
- `docs/DEPENDENCY_POLICY.md`
- `docs/FEATURE_BACKLOG.md`
- `docs/REPO_BOOTSTRAP_CHECKLIST.md`

### Decisions
- `docs/decisions/ADR-0001-platform-baseline.md`
- `docs/decisions/ADR-0002-dual-engine-strategy.md`
- `docs/decisions/ADR-0003-native-workspace-format.md`
- `docs/decisions/ADR-0004-exact-arithmetic-dependency-budget.md`
- `docs/decisions/ADR-0005-cloud-sync-baseline.md`

### Templates
- `docs/templates/ADR_TEMPLATE.md`
- `docs/templates/TASK_TEMPLATE.md`
- `docs/templates/SESSION_LOG_TEMPLATE.md`
- `docs/templates/PR_SUMMARY_TEMPLATE.md`

### Local instructions
- `Apps/MatrixMasterMobile/instructions.md`
- `Apps/MatrixMasterMac/instructions.md`
- `Packages/MatrixDomain/instructions.md`
- `Packages/MatrixExact/instructions.md`
- `Packages/MatrixNumeric/instructions.md`
- `Packages/MatrixPersistence/instructions.md`
- `Packages/MatrixUI/instructions.md`
- `Packages/MatrixFeatures/instructions.md`
- `Packages/MatrixAutomation/instructions.md`

Codex must create these first, then code.

---

## Engineering workflow for Codex

### Session procedure
For each session:

1. read root `instructions.md`
2. read the local `instructions.md` for the area being modified
3. read any relevant ADRs
4. update or create a task entry from `docs/templates/TASK_TEMPLATE.md`
5. make changes
6. run targeted tests
7. update docs if architecture or behavior changed
8. write a session summary using the session template

### Branching and task discipline
Codex should work one milestone slice at a time:
- do not make unrelated changes
- do not reformat the world
- do not introduce speculative abstractions before they are needed
- do not add dependencies casually

### Documentation discipline
Whenever Codex changes:
- architecture -> update `ARCHITECTURE.md` and maybe an ADR
- feature scope -> update `PRODUCT_REQUIREMENTS.md` or `FEATURE_BACKLOG.md`
- workflow/UI -> update `UX_SPEC.md`
- tests or gates -> update `TEST_STRATEGY.md`

---

## Testing philosophy

Codex must implement tests in layers:

### Arithmetic tests
- fractions
- signs
- normalization
- gcd reduction
- complex arithmetic if supported in exact form

### Algorithm tests
- REF/RREF
- determinant identities
- inverse correctness
- rank-nullity invariants
- projection identities
- orthonormality after Gram-Schmidt
- diagonalization reconstruction checks

### Golden examples
Use textbook-style fixtures and expected derivations.

### Numeric sanity
Check:
- residuals
- conditioning warnings
- tolerance-based assertions
- stable decomposition reconstruction

### UI tests
Check:
- matrix editor flows
- result reuse
- platform navigation
- accessibility labels for major controls
- keyboard navigation on iPad/Mac

### Sync tests
Check:
- offline queueing and later reconciliation
- account-state fallbacks
- conflict recovery entries
- delete propagation and convergence

---

## Non-goals for the initial build

Do not prioritize these in the first wave:

- real-time collaboration
- plugins
- arbitrary scripting
- web version
- Android
- ML demo features before core algebra is strong
- automatic theorem proving beyond practical derivations

---

## Definition of done

A feature is done only when:

- it works on all intended platforms for that scope
- it has tests
- it has user-facing copy that is clear
- it has no obvious accessibility gaps in common tasks
- results are reusable or exportable where appropriate
- docs are updated
- the feature is discoverable without needing a scavenger hunt

---

## Owner-decision status

The major product-level scope questions for this package are now closed.

Use the docs in this package as the implementation contract unless the owner overrides them.
