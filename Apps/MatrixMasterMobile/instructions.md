# MatrixMasterMobile instructions

## Owns
- iPhone and iPad app shell
- mobile navigation
- mobile scenes
- compact and regular size-class composition

## UX rules
- iPhone should optimize for focused workflows
- iPad should take advantage of split view and keyboard support
- avoid desktop-style clutter on phone
- keep the feel calculator/productivity first rather than courseware-first
- result reuse should remain easy on touch devices
- for the first public release, mobile must stay in core-workflow parity with Mac even when presentation differs
- keep sync/account state visible in Library and relevant detail surfaces without turning the phone UI into a settings-heavy surface

## Must not own
- domain logic
- algorithm implementations
- persistence internals

## Testing expectations
- common task smoke tests
- layout sanity in compact and regular widths
- keyboard support checks on iPad where relevant
- sync state and recovery-surface smoke tests on mobile layouts
