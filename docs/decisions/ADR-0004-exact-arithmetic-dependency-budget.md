# ADR-0004: Exact arithmetic dependency budget

## Status
Accepted

## Context
Exact rational workflows need arbitrary-precision integer support, but the project should avoid turning into a dependency bazaar.

## Decision
Permit at most one small maintained SPM dependency for BigInt support in the exact engine if implementation experience shows it materially reduces risk or complexity.

Guardrails:
- wrap the dependency behind an internal adapter in `MatrixExact`
- keep the public domain model independent from the dependency
- record the concrete package and version in an ADR before merging it
- treat every other dependency as still requiring separate justification

## Rationale
This keeps the exact engine practical without blowing a hole in the project's minimal-dependency posture. BigInt support is the one place where Swift's standard library leaves a real gap.

## Alternatives considered
- author the entire exact stack with zero third-party packages
- adopt a larger symbolic-math dependency set
- use fixed-width integers and accept overflow risk

## Consequences
The package gets a narrow dependency budget where it actually helps, while preserving replaceability and limiting long-term maintenance exposure.

## Follow-up
When a concrete BigInt package is selected, amend or supersede this ADR with the exact package name, version, license, and wrapper plan.
