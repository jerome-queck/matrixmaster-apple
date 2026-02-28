# Bootstrap prompt for Codex

Paste the following into Codex at the start of a fresh repository session.

---

Build **Matrix Master** from scratch as a native SwiftUI multiplatform app for **iOS, iPadOS, and macOS**.

## Important constraints

- The workspace is intentionally empty. Do **not** assume any legacy files exist.
- You may treat the older Matrix Master repository only as a product archaeology source, not as an implementation source.
- Do **not** copy, port, translate, or paraphrase old source code.
- Author all code and documentation fresh in this repository.
- Treat the output repository as the primary, first-of-its-kind codebase. Do not frame the work as a patch, diff, or retrofit.
- Prioritize UX, clarity, mathematical correctness, accessibility, and maintainability.

## What to do first

1. Read `CODEX_HANDOFF_PLAN.md`.
2. Create the documentation and instruction files described there before writing major app code.
3. Create a new SwiftUI multiplatform workspace and internal package structure.
4. Build the app incrementally in milestones, not as one giant drop.

## Locked owner decisions

Treat these as already confirmed:

- use a fresh native workspace format with the `.mmws` extension
- ship the first public release on iPhone, iPad, and Mac together
- make the product feel calculator/productivity first, with explanations as support rather than the main chrome
- allow one small BigInt SPM dependency for exact arithmetic if it is justified and wrapped
- expose minimal polynomial and Jordan form through normal Analyze navigation when they ship, not a hidden Advanced bucket
- include cloud sync for the user's own devices while preserving local-first/offline behavior
- build the new repository as the primary greenfield implementation, not as a patch stream against an older codebase

## Product priorities

The app should feel centered around four destinations:

- Solve
- Operate
- Analyze
- Library

Preserve these product ideas:

- offline-first use with cloud sync continuity across the user's devices
- intuitive first-run workflows
- step-by-step math derivations
- result reuse across tools
- history and saved objects
- export and reporting
- optional tutor-style explanations

## Required architecture

Use internal packages/modules for:

- MatrixDomain
- MatrixExact
- MatrixNumeric
- MatrixPersistence
- MatrixUI
- MatrixFeatures
- MatrixAutomation

Use:
- SwiftUI
- SwiftData for metadata and local library state
- Apple-account-backed private-cloud sync for eligible workspace/library data while preserving offline operation
- Accelerate for numeric linear algebra where relevant
- Swift Charts where visualizations help
- App Intents for system integration
- XCTest for automated tests

## Core math rule

Maintain separate **exact** and **numeric** computation lanes.

### Exact lane
Use for:
- row reduction
- determinants
- inverses
- adjugates/cofactors
- Cramer's rule
- span / basis / coordinate / subspace logic
- exact change-of-basis
- educational steps

### Numeric lane
Use for:
- LU / QR / SVD / eigen
- least squares
- large dense matrices
- tolerance-aware diagnostics
- later sparse/iterative workflows

The UI must clearly label whether a result is exact or approximate.

## UX rule

Every result screen must show:
1. the answer
2. key diagnostics
3. reuse actions
4. steps
5. explanation
6. export/share actions

Every major workflow must support:
- direct entry
- paste
- load from library
- use previous result

## Milestone order

### Milestone A
Foundation:
- docs
- workspace
- packages
- design system
- matrix editor
- core models
- navigation shell
- sync capability shell and local persistence baseline

### Milestone B
Core MVP:
- system solver with REF/RREF
- matrix operation expression engine
- determinant
- inverse via row reduction
- analysis basics: rank, trace, LU, QR, SVD, eigen
- persistence/history/result reuse
- cloud sync baseline for saved workspaces and library items

### Milestone C
Spaces and bases:
- span
- linear independence
- basis extraction
- coordinate vectors
- column/row/null spaces
- rank-nullity summaries

### Milestone D
Linear maps:
- kernel/range
- injective/surjective/bijective checks
- basis-relative matrix representations
- change of basis
- similarity

### Milestone E
Orthogonality:
- inner products
- norms
- Gram-Schmidt
- projections
- least squares

### Milestone F
Later exact/applied expansion:
- minimal polynomial
- Jordan form
- sparse/iterative tools
- PCA/SVD extras

## Documentation process

Before and during coding, create and maintain:

- `instructions.md`
- `README.md`
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
- local `instructions.md` files inside Apps/ and Packages/
- ADRs under `docs/decisions/`
- templates under `docs/templates/`

## Working rules

- Keep code modular.
- Do not create a giant all-knowing app file.
- Prefer plain, readable Swift over clever abstraction acrobatics.
- Add dependencies only with an ADR.
- Update docs whenever architecture or behavior changes.
- Keep accessibility and keyboard support in scope from the start.
- Keep Mac UX genuinely native.
- Keep manual import/export available even when cloud sync exists.

## Output expectations

At the end of each milestone:
- summarize what was built
- list what remains
- list tests added
- list docs updated
- identify any unresolved decisions

Start by creating the repository structure and the markdown files in the plan.
