# Matrix Master repository instructions

This file is the top-level execution contract for all work in this repository.

## Mission

Build Matrix Master as a native Apple-platform linear algebra app that is:

- mathematically correct
- intuitive for first-time users
- powerful for repeat users
- accessible
- local-first with cloud sync
- modular and maintainable

## Build-from-scratch rule

This repository must be authored from scratch.

You may inspect the previous Matrix Master app only to understand:
- product intent
- user workflows
- feature grouping
- useful UX patterns

You must **not**:
- copy code
- port files
- translate components line-by-line
- preserve old architecture for convenience
- import any legacy workspace state as implementation scaffolding
- frame the work as a patch, diff, or retrofit against an existing codebase

## Platform targets

Support:
- iPhone
- iPad
- Mac

The first public release must ship on iPhone, iPad, and Mac together.
The codebase should share as much logic as possible while allowing platform-specific UX where it improves usability.

## Owner-locked decisions

These decisions are already made and should not be reopened casually:

- the new native codebase uses a fresh workspace format with the `.mmws` extension
- the first public release ships on iPhone, iPad, and Mac together
- the product should feel like a calculator/productivity tool first
- one small BigInt SPM dependency is allowed for exact arithmetic if it is justified and wrapped behind internal interfaces
- minimal polynomial and Jordan form should live in normal Analyze navigation when they ship, not behind a hidden Advanced bucket
- cloud sync across the user's own devices is a first-class product feature while preserving local-first/offline behavior
- this repository is the primary greenfield implementation, not a patch stream layered onto an older codebase

## Global engineering rules

1. Keep exact and numeric math paths separate.
2. Prefer internal package boundaries over a monolithic target.
3. Every feature should be discoverable through obvious navigation or search.
4. Every computational workflow should support result reuse.
5. Every user-facing result should prefer:
   - answer
   - diagnostics
   - actions
   - steps
   - explanation
6. Accessibility is part of the definition of done.
7. Documentation must be updated alongside implementation.
8. Dependencies require justification and documentation.
9. Preserve offline usability even when cloud sync is unavailable.

## Mandatory reading order for Codex

Before making changes:
1. this file
2. `docs/START_HERE.md`
3. the relevant local `instructions.md`
4. relevant ADRs in `docs/decisions/`
5. the task record based on `docs/templates/TASK_TEMPLATE.md`

## Required docs

These docs are mandatory and must remain current:

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

## Coding style

- Write clear Swift.
- Prefer explicit names over dense abbreviations.
- Keep view files focused on presentation and view state.
- Put domain logic in domain packages, not inside SwiftUI views.
- Keep algorithm implementations testable without the UI.
- Avoid speculative generic frameworks unless they simplify real work.

## Documentation style

- Write for future maintainers, not for a mythical perfect memory.
- Do not duplicate the same rules in ten places.
- Record decisions once and link to them.
- Keep examples concrete.

## Testing rule

No meaningful math or workflow feature is complete without tests.

At a minimum, each feature should have:
- unit tests for core logic
- fixture tests for representative examples
- workflow tests where state transitions matter
- sync/offline coverage where persisted user data changes

## Accessibility rule

For common tasks, users must be able to:
- navigate controls with VoiceOver
- use larger text without broken layout
- complete workflows with keyboard input on iPad/Mac
- understand status and errors without relying on color alone

## Definition of done

A change is done when:
- code builds cleanly
- tests pass
- docs are updated
- accessibility for common tasks was considered
- the change fits the roadmap
- no unrelated churn was introduced

## Session output format

At the end of each focused work session, record:

- what changed
- what tests were added or updated
- what docs changed
- what remains
- what risks or open questions remain

Use the session template in `docs/templates/SESSION_LOG_TEMPLATE.md`.
