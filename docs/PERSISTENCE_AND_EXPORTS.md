# Persistence and exports

## Goal

Keep Matrix Master local-first, durable, cloud-synced across the user's own devices, and easy to move or share manually when needed.

## Persistence split

Use three complementary layers:

### 1. Local structured persistence
Use SwiftData or an equivalent local model store for:
- library metadata
- saved item indexing
- recent items
- workspace metadata
- tags/folders/favorites
- settings
- history summaries
- sync metadata
- saved reports metadata

### 2. Versioned file payloads
Use Codable payloads for:
- full workspace snapshots
- import/export packages
- shareable matrix or basis files
- future document-based flows
- migration-safe portable artifacts

### 3. Private-cloud sync
Use a user-private Apple-cloud sync path for:
- saved workspaces
- saved library objects
- folders/tags/favorites if implemented
- continuity-relevant settings

This keeps the app responsive offline while still providing cross-device continuity.

## Persistence philosophy

The model is local-first:
- every write lands locally first
- cloud sync mirrors eligible data after the local write succeeds
- export/import remains supported even when sync is enabled
- the app must still work when the user is offline or signed out of cloud services

Cloud sync is a product feature, not the only copy of the user's work. The local store remains the durable baseline.

## Persistent entities

Recommended persistent concepts:
- `SavedMatrix`
- `SavedVectorSet`
- `SavedBasis`
- `SavedLinearMap`
- `SavedWorkspace`
- `HistoryEntry`
- `Tag`
- `Folder`
- `Favorite` if not modeled elsewhere
- `ExportRecord` (optional)
- `SyncMetadata` or equivalent embedded sync state
- `DeletionTombstone` if the sync system needs explicit delete propagation

## Workspace snapshot contents

A full workspace snapshot should capture:
- current feature/tool
- current active inputs
- named matrices/vectors/bases/maps
- recent reusable results
- settings needed to reopen the session meaningfully
- snapshot version
- stable workspace identifier
- last-modified metadata needed for sync/recovery

Keep snapshot schemas versioned from day one.

## What should sync in v1

Sync across the user's own devices should include:
- saved workspaces
- saved matrices/vectors/bases/maps
- folders/tags/favorites if those surfaces exist
- continuity-relevant preferences

Keep these local-only unless there is a later reason to sync them:
- transient editor state
- undo stacks
- temporary caches and decompositions
- device-specific window/split-view arrangement
- noisy per-keystroke history that does not help continuity

## File types

Choose clear file boundaries:

- native workspace snapshot
- interoperable object exports
- report/export output

The new native codebase should use a fresh workspace format instead of reusing `.mmatrix`.

Recommended v1 decision:
- canonical native workspace extension: `.mmws`
- display name: Matrix Master Workspace
- UTI/UTType identifier: `com.matrixmaster.workspace`
- payload shape: versioned JSON document, optionally compressible later if size demands it
- compatibility note: if legacy `.mmatrix` import is ever added, treat it as a compatibility importer only, not the canonical native format

For v1, keep single-object exports interoperable rather than inventing a custom extension for every object type:
- JSON for structured objects
- CSV / TSV for tabular matrices/vectors
- LaTeX / Markdown / plain text for human-facing export

## Export targets

Support at least:
- JSON
- CSV / TSV where appropriate
- LaTeX for displayable math objects
- Markdown for steps or reports
- PDF report output later
- plain text copy for quick sharing

## Import rules

Imports should:
- validate version and schema
- fail gracefully with actionable errors
- preserve user data where possible
- keep unsupported fields rather than discarding silently if forward compatibility is desired

## History model

History should be useful, not noisy.

Recommended history contents:
- timestamp
- tool used
- short input summary
- short result summary
- link to restorable workspace/result payload
- tags like `exact`, `numeric`, `solve`, `eigen`, `least-squares`

Prefer meaningful checkpoints over recording every tiny twitch of the editor.

## Library behavior

The library should support:
- search
- tags/folders
- previews
- sort by recent/name/type
- duplicate
- rename
- delete with confirmation for important items
- reuse directly into active workflows
- sync status indicators that explain whether an item is local-only, synced, in progress, or needs attention
- conflict recovery entries when divergent edits need review

## Sync behavior

The sync contract for v1 should be:
- per-user private sync only
- no real-time shared editing
- no requirement for continuous connectivity
- eventual convergence across the user's signed-in devices
- clear account/offline/error states in the UI

### Conflict policy

When two devices edit the same thing concurrently:
- prefer deterministic merge rules only for simple metadata such as names, tags, or sort preferences
- for divergent workspace content, preserve a recoverable copy rather than silently overwriting one side
- surface the recovery event in the Library so the user can inspect and clean up later

### Delete policy

When a synced item is deleted:
- propagate deletion intentionally through the sync layer
- keep a tombstone or equivalent marker if needed for convergence
- avoid zombie reappearance from stale devices

### Account/offline policy

When cloud sync is unavailable:
- keep the app fully usable locally
- queue eligible changes for later sync
- explain the state in normal language
- never block solving, editing, or exporting because connectivity is unavailable

## Reports

A report object should be built from reusable result/export models rather than screen scraping.

A report can include:
- title
- date
- input summary
- result summary
- selected derivation steps
- explanatory notes
- export format options

## Migration strategy

Every persisted type should have:
- schema version
- decoder with upgrade path
- migration notes when structure changes
- stable identifiers that survive sync and cross-device restoration

Do not wait until later to think about migrations. Persisted data needs a planned upgrade path from the beginning.

## Privacy posture

The default posture is:
- local-first
- private-cloud sync for the user's own data
- no remote computation required
- no analytics required for function
- manual export/import always available

Any future move toward collaboration, shared workspaces, or broader telemetry should be documented separately in additional ADRs.
