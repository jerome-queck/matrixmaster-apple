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
- [ ] create Xcode workspace
- [ ] create mobile app shell
- [ ] create Mac app shell
- [ ] create internal package structure
- [ ] register the native `.mmws` workspace type and versioning plan
- [ ] plan or enable the private-cloud sync capability path
- [ ] verify clean build on iPhone, iPad, and Mac

## Foundation bootstrap
- [ ] create design token layer
- [ ] create matrix editor primitives
- [ ] create vector/basis editor primitives
- [ ] create domain models
- [ ] create result/step models
- [ ] create persistence shell
- [ ] create sync state models/coordinator contracts
- [ ] create navigation shell

## Quality bootstrap
- [ ] configure tests
- [ ] add baseline fixtures
- [ ] add first UI smoke tests
- [ ] add persistence round-trip tests
- [ ] add first sync/offline state tests with mocks or fixtures
- [ ] verify accessibility labels on shell
- [ ] document any approved dependencies

## Milestone readiness
- [ ] foundation is stable enough for Solve
- [ ] result reuse mechanism is planned
- [ ] first-public-release parity across iPhone, iPad, and Mac is planned explicitly
- [ ] cloud sync and local-fallback behavior are planned explicitly
- [ ] docs and code structures agree
