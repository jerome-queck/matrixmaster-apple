# UX specification

## UX north star

Matrix Master should feel like a calm, precise lab bench for linear algebra.

Users should not have to fight the interface to do mathematics.

## Primary UX goals

- reduce time-to-first-answer
- make advanced features discoverable without clutter
- keep results reusable
- separate editing from interpretation cleanly
- support touch, keyboard, pointer, and screen readers well
- make sync feel reliable and unobtrusive

## Product posture

The default feel should be calculator/productivity first:

- quick entry, quick answer, quick reuse
- strong recent-items, history, export, sync, and keyboard flows
- steps and explanations expand when wanted instead of crowding the first screen
- avoid syllabus-shaped or gamified chrome in the first public release

## Navigation model

### iPhone
Use a compact root navigation model with four destinations:
- Solve
- Operate
- Analyze
- Library

Avoid burying core features behind a generic "More" screen unless they are genuinely secondary.

### iPad
Use a `NavigationSplitView` or similarly clear split layout:
- sidebar for destinations and subtools
- main content for editors/results
- inspector or sheets for details, reuse actions, export, and sync state where appropriate

### Mac
Use a native Mac information architecture:
- persistent sidebar
- rich toolbar
- command menu items
- keyboard shortcuts
- multiple windows for separate workspaces when justified
- inspector panes where beneficial

## First public release parity

The first public release must include iPhone, iPad, and Mac together.
Parity means the core Solve, Operate, Analyze, and Library loops all exist on every platform, even when the shell presentation differs.
Parity also includes the same baseline cloud-sync capability and clear sync-state communication on every platform.

## Home and entry behavior

The app should open to a workspace home showing:
- recent workspaces
- recent saved objects
- quick actions for common tasks
- sample presets
- subtle sync/account state when it matters

Quick actions should include:
- solve a system
- compute determinant
- find inverse
- analyze matrix
- find basis / null space
- change coordinates
- run Gram-Schmidt
- solve least squares

## Matrix editor

The matrix editor is a core product surface and must be excellent.

### Requirements
- grid-based entry
- add/remove rows and columns
- paste CSV, TSV, or bracket syntax
- exact fraction entry
- optional complex entry
- quick fill with zero / identity / random / sample
- row and column labels where useful
- error messaging that tells the user what is wrong and where
- no forced modal detours for simple edits

### Large matrix behavior
- support scrolling in both directions
- keep headers visible where possible
- virtualize or lazily render large grids if needed
- avoid lag during typing

## Vector and basis editors

Do not force users to pretend every vector is just a skinny matrix.

Provide:
- vector editor
- set-of-vectors editor
- ordered basis editor
- basis naming support
- coordinate view where needed
- native polynomial-space entry
- native matrix-space entry

## Result views

Every result page should follow this order:

1. **Primary result**
2. **Diagnostics**
3. **Next actions / reuse**
4. **Steps**
5. **Explanation**
6. **Export**

### Primary result examples
- solution set
- determinant value
- basis list
- eigenvalue set
- decomposition form
- projection vector

### Phase 5 delivered baseline
- matrix and vector outputs render as structured objects (grid/bracket views), not plain text paragraphs
- polynomial objects render with coefficient-aware formatting rather than generic token strings
- REF/RREF matrices are exposed as explicit result panels in elimination workflows
- answer, diagnostics, reuse actions, and steps follow a consistent card structure across destinations
- destination switching does not leak result content across tabs; each tab shows only its own computed result history

Follow-up UX item:
- reintroduce copy/export controls (`plain`, `markdown`, `latex`) only after the formatting pass is finalized

### Diagnostics examples
- exact vs approximate
- field used
- invertible or singular
- rank / nullity
- residual norm
- conditioning warning
- diagonalizable over `R` vs only over `C`

## Reuse flow

Every result that creates a matrix, vector, basis, or decomposition should offer reuse actions like:
- use in Solve
- use in Operate
- use in Analyze
- save to Library
- export
- copy as text / CSV / LaTeX

This should be one tap/click away, not hidden behind extra gestures.

## Sync UX

Cloud sync should feel like a continuity feature, not a separate management task.

Principles:
- keep the app usable when offline or signed out
- show sync state in calm, human language
- avoid blocking computation because sync is delayed
- surface recovery copies when conflicts happen instead of hiding the event
- keep retry/recover actions near the affected Library items

Useful sync states:
- local only
- syncing
- synced
- needs attention

## Advanced tools discoverability

Advanced tools should still be easy to find.

Use:
- search
- command palette on Mac / keyboard-capable iPad
- categorized Analyze sections
- "related tools" suggestions on result pages

When minimal polynomial and Jordan form ship, expose them under Analyze's eigen/canonical forms grouping and search. Do not bury them under a generic Advanced bucket.

## Accessibility requirements

### VoiceOver
- every input cell must have a meaningful accessibility label
- every actionable control must have a descriptive label
- formulas should have human-readable labels, not opaque raw TeX
- result sections should have semantic grouping

### Larger text
- support layout scaling without truncating critical controls
- allow content to scroll rather than clip

### Keyboard
On iPad and Mac:
- navigate grids with arrow keys
- submit computations from keyboard
- jump between input, steps, export, and Library sync detail where relevant
- support common shortcuts for save, search, duplicate, export

### Color and motion
- never rely on color alone for meaning
- support reduced motion
- support higher contrast cleanly

## Error UX

Errors should:
- point to the problem
- tell the user what to do next
- avoid opaque system jargon
- distinguish validation errors from mathematical impossibility
- distinguish sync/account-state issues from math failures

Examples:
- "Entry (2,3) is not a valid rational or decimal number."
- "This matrix is singular, so the inverse does not exist."
- "QR decomposition requires numeric mode."
- "This workspace is saved locally and will sync when your cloud account becomes available."

## Empty states

Useful empty states:
- suggest common actions
- offer sample matrices
- explain why a section matters
- never feel like dead air

## Platform polish notes

### iPhone
- keep action buttons large and direct
- use sheets sparingly
- prefer in-place editing over deep modal stacks
- keep sync/account messaging compact and calm

### iPad
- take advantage of sidebar, toolbars, and hardware keyboard
- allow drag/reorder in library where sensible
- make conflict recovery and sync detail readable without modal chaos

### Mac
- support menu commands
- support window titles and document naming
- support drag-and-drop import/export
- use inspectors for export options or advanced settings rather than endless sheets
- make sync state visible in a toolbar or Library inspector location that feels native
