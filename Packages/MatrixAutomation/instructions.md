# MatrixAutomation instructions

## Owns
- App Intents
- Shortcuts/Spotlight surfacing
- quick actions and discovery integrations

## Must not own
- core algorithms
- primary persistence logic
- feature business logic beyond invoking public feature contracts

## Design rules
- expose only high-value actions
- keep intent parameters simple
- respect privacy/local-first behavior and avoid surfacing sync internals that do not help the user

## Test expectations
- basic intent availability and invocation where feasible
- serialization/parameter mapping sanity tests
