# Documentation governance

## Purpose

These docs exist to keep the repository navigable for both humans and coding agents.

The goal is not to create paperwork confetti. The goal is to keep decisions, scope, and quality rules explicit.

## Documentation categories

### Stable docs
These should change infrequently and describe enduring truths:
- `instructions.md`
- `docs/ARCHITECTURE.md`
- `docs/DEPENDENCY_POLICY.md`

### Evolving product docs
These change as the app grows:
- `docs/PRODUCT_REQUIREMENTS.md`
- `docs/UX_SPEC.md`
- `docs/IMPLEMENTATION_ROADMAP.md`
- `docs/FEATURE_BACKLOG.md`

### Operational docs
These guide work and history:
- ADRs in `docs/decisions/`
- task records
- session logs
- PR summaries

## Update rules

Update docs when:
- architecture changes
- a dependency is added or removed
- a major workflow changes
- feature scope changes
- a milestone is completed
- a test strategy changes materially

## Anti-duplication rules

- record a decision once, then reference it
- do not restate the same acceptance criteria in five files
- use ADRs for decisions, not random scattered notes
- move superseded plans to history or mark them obsolete

## Required recurring artifacts

For each meaningful feature task:
- task record
- code/test changes
- doc updates if relevant
- session summary

For each major architectural decision:
- ADR

## Local instructions

Each package/app shell has a local `instructions.md` file.
Those files should explain:
- what that module owns
- what it must not own
- test expectations
- design constraints

## Reviewing docs

When reviewing docs, check:
- is the information still true?
- is it duplicated elsewhere?
- is it actionable?
- is it specific enough for a new contributor or coding agent?

## Doc quality bar

A good doc is:
- concrete
- short enough to read
- specific enough to execute
- updated when reality changes

A bad doc is:
- vague
- duplicated
- outdated
- full of fake certainty or generic filler
