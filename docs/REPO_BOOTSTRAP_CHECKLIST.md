# Repository bootstrap checklist

Use this as the build-from-zero startup checklist.

## Documentation bootstrap
- [ ] create `instructions.md`
- [ ] create `README.md`
- [ ] create `CODEX_HANDOFF_PLAN.md`
- [ ] create `BOOTSTRAP_PROMPT_FOR_CODEX.md`
- [ ] create all required files under `docs/`
- [ ] create ADRs 0001 through 0005
- [ ] create template files
- [ ] create local `instructions.md` files under `Apps/` and `Packages/`

## Workspace bootstrap
- [x] create Xcode workspace
- [x] create mobile app shell
- [x] create Mac app shell
- [x] create internal package structure
- [ ] register the native `.mmws` workspace type and versioning plan
- [ ] plan or enable the private-cloud sync capability path
- [ ] verify clean build on iPhone, iPad, and Mac

## Foundation bootstrap
- [ ] create design token layer
- [ ] create matrix editor primitives
- [ ] create vector/basis editor primitives
- [x] create domain models
- [x] create result/step models
- [x] create persistence shell
- [x] create sync state models/coordinator contracts
- [x] create navigation shell

## Quality bootstrap
- [x] configure tests
- [ ] add baseline fixtures
- [x] add first UI smoke tests
- [x] add persistence round-trip tests
- [ ] add first sync/offline state tests with mocks or fixtures
- [ ] verify accessibility labels on shell
- [ ] document any approved dependencies

## Milestone readiness
- [ ] foundation is stable enough for Solve
- [ ] result reuse mechanism is planned
- [ ] first-public-release parity across iPhone, iPad, and Mac is planned explicitly
- [ ] cloud sync and local-fallback behavior are planned explicitly
- [ ] docs and code structures agree
