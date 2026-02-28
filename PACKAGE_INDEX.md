# Package index

This package contains a greenfield build handoff for Matrix Master.

It is meant to produce a new primary repository, not a patch or diff against an older codebase.

## Recommended use
1. Start with `CODEX_HANDOFF_PLAN.md`.
2. Paste `BOOTSTRAP_PROMPT_FOR_CODEX.md` into Codex for a fresh repo session.
3. Drop `instructions.md` and the `docs/` tree into the new repository.
4. Let Codex create the workspace, packages, and app shells following the roadmap.

## Main files
- `CODEX_HANDOFF_PLAN.md` - master build plan
- `BOOTSTRAP_PROMPT_FOR_CODEX.md` - first prompt to feed Codex
- `instructions.md` - root repository rules
- `docs/` - specs, roadmap, testing, governance, templates
- `Apps/*/instructions.md` - app-shell rules
- `Packages/*/instructions.md` - module rules

## Additional specs
- `docs/FEATURE_MATRIX.md` - concept-by-concept implementation map
- `docs/SCREEN_FLOWS.md` - screen and navigation flows
