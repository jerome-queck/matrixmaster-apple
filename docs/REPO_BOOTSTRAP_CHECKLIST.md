# Repository bootstrap checklist

Use this as the build-from-zero startup checklist.

## Documentation bootstrap
- [x] create `instructions.md`
- [x] create `README.md`
- [x] create `CODEX_HANDOFF_PLAN.md`
- [x] create `BOOTSTRAP_PROMPT_FOR_CODEX.md`
- [x] create all required files under `docs/`
- [x] create ADRs 0001 through 0005
- [x] create template files
- [x] create local `instructions.md` files under `Apps/` and `Packages/`

## Workspace bootstrap
- [x] create Xcode workspace
- [x] create mobile app shell
- [x] create Mac app shell
- [x] create internal package structure
- [x] register the native `.mmws` workspace type and versioning plan
- [x] plan or enable the private-cloud sync capability path
- [x] verify clean build on iPhone, iPad, and Mac

## Foundation bootstrap
- [x] create design token layer
- [x] create matrix editor primitives
- [x] create vector/basis editor primitives
- [x] create domain models
- [x] create result/step models
- [x] create persistence shell
- [x] create sync state models/coordinator contracts
- [x] create navigation shell

## Quality bootstrap
- [x] configure tests
- [x] add baseline fixtures
- [x] add first UI smoke tests
- [x] add persistence round-trip tests
- [x] add first sync/offline state tests with mocks or fixtures
- [x] verify accessibility labels on shell
- [x] document any approved dependencies

## Milestone readiness
- [x] foundation is stable enough for Solve
- [x] result reuse mechanism is planned
- [x] first-public-release parity across iPhone, iPad, and Mac is planned explicitly
- [x] cloud sync and local-fallback behavior are planned explicitly
- [x] docs and code structures agree
