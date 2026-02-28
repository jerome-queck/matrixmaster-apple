# Dependency policy

## Principle

Default to Apple frameworks and internal code.

Add external dependencies only when they clearly reduce risk or implementation cost in a way that is hard to justify doing internally.

## Approval rule

Every new dependency requires:
- a short ADR
- reason for inclusion
- alternatives considered
- maintenance/risk note
- removal/escape plan if relevant

## Likely acceptable dependencies

### Arbitrary-precision integer support
One small maintained SPM package for big integer arithmetic is approved in principle because exact rational workflows are central and Swift does not provide a built-in arbitrary-precision integer type.

Guardrails:
- keep this to one dependency, not a pile of symbolic-math cargo
- wrap it behind an internal adapter inside `MatrixExact`
- document the concrete package and version in an ADR before merging
- keep an exit path so the wrapper can be replaced later

### Complex helper library
Only if native or internal support becomes awkward and the chosen library materially simplifies numeric complex operations.

### Math rendering helper
Only if native text rendering proves insufficient for readable formula display and export consistency.

## Likely unnecessary dependencies

Avoid adding dependencies for:
- generic state management frameworks
- routing frameworks
- analytics SDKs
- UI component megabundles
- persistence wrappers over SwiftData
- math libraries that duplicate Accelerate-backed numeric work without clear benefit

## Rules for dependency use

- keep the list minimal
- prefer stable, well-maintained packages
- pin versions deliberately
- document why the dependency exists
- isolate wrappers around third-party APIs so replacement is feasible
- treat every dependency other than the single approved BigInt budget as default-deny until justified

## Dependency health review

At each major milestone, review:
- still needed?
- version current enough?
- security/license concerns?
- replaceable with built-in APIs now?

The app should not become a dependency petting zoo.
