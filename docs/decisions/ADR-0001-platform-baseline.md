# ADR-0001: Platform baseline

## Status
Accepted

## Context
Matrix Master must ship on iPhone, iPad, and Mac with a shared codebase and strong platform-specific UX.

## Decision
Build the app as a SwiftUI multiplatform project with:
- a mobile app shell for iPhone and iPad
- a dedicated Mac app shell
- shared internal packages for domain, engines, persistence, UI primitives, features, and automation
- first-public-release parity across iPhone, iPad, and Mac for the core workflows

## Rationale
This gives the project:
- maximum logic sharing
- room for Mac-specific polish
- room for iPad-specific split-view and keyboard behavior
- native Apple-platform ergonomics

## Alternatives considered
- single monolithic target
- Catalyst-first approach
- web wrapper or Electron
- React Native style cross-platform approach

## Consequences
- some platform-specific tailoring is required
- app shell code is duplicated where it meaningfully differs
- package boundaries become important early
- Mac cannot be treated as a later post-launch polish bucket for the first public release

## Follow-up
Document platform-specific UX expectations in `docs/UX_SPEC.md`.
