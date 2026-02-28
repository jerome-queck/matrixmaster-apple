# MatrixMasterMac instructions

## Owns
- native Mac app shell
- menu commands
- keyboard shortcuts
- multiwindow/document handling if included
- Mac-specific inspectors and toolbars

## UX rules
- feel like a real Mac app
- support keyboard-first use
- make library and export flows efficient
- keep the feel calculator/productivity first rather than courseware-first
- use sidebar/detail/inspector patterns where helpful
- for the first public release, Mac must ship with the same core workflow coverage as iPhone and iPad
- surface sync/account state in a native-feeling toolbar, inspector, or Library detail location

## Must not own
- domain algorithms
- persistence internals
- feature logic beyond shell composition

## Testing expectations
- keyboard shortcut coverage for common actions
- window/navigation smoke tests
- accessibility and larger text sanity on Mac
- sync status and recovery-surface smoke tests on Mac
