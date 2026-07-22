# Migration Debt Ledger

This file records only active architecture migration or compatibility-retirement
debt. Current supported behavior belongs in `docs/`; execution rules belong in
the nearest `AGENTS.md`; exact validation commands belong in
`docs/development/maintain-and-release/testing.md`; completed work belongs in
component history.

## Active debt

Last audited: 2026-07-22.

```text
toolbox-product-debt: none
architecture-migration-debt: test ownership and affected-test routing
```

The App SDK explicit-contract migration is complete. Its durable replacement
contract is documented in `docs/framework/`, and its completed evidence is in
the component history; no migration roadmap or phase evidence remains here.

## Active migration: test ownership and affected-test routing

### Problem record

- Owner: repository test runner and `tests/runner/`.
- Observable effect: a change owned by one App capability can select its whole
  App family, a monolithic App GUI class, the complete documentation suite, and
  an App isolation contract that is also selected implicitly by another step.
  Small changes therefore pay for unrelated tests and can execute the same
  canonical test more than once.
- Focused evidence: `BuildTaskEfficiencyGuardrailTest` and the route listing
  produced by `labkitValidationPlanForChangedPaths(..., Mode="fast")`.
- Completion criteria: changed-file validation compiles each supported change
  into a deterministic, duplicate-free set of tests owned by the deepest
  affected source scope; every public App follows the same path contract; and
  framework changes expand through explicit downstream impact rules rather
  than family-wide or repository-wide accidents.
- Removal condition: delete this roadmap after the new layout, route compiler,
  App/framework impact contracts, focused documentation routing, and final
  guardrails are active with no migration fallback. Move the durable rules to
  `tests/AGENTS.md` and the supported user workflow to the testing manual.

### Objective

Keep the public task set small. `buildtool changedFast` remains the single
local pre-push changed-file entry point. It must use an owner-minimal plan that
selects the smallest sound affected-test closure for any tracked change. Full
`headless` and `gui` tasks remain the clean-room integration proof used by CI;
the changed-file plan must not pretend to replace them.

Optimize selection before considering execution parallelism. Broad official
runs remain single-process unless a separate end-to-end benchmark proves that
worker startup, license use, discovery, reporting, and tail latency repay the
extra orchestration.

### Mainline roadmap baseline

Complete and land this roadmap on `main` before creating the implementation
branch. The standalone mainline commit is the durable decision record used to
review every later phase. The implementation branch starts from that commit;
its final squash merge may remove this active-debt entry after reaching the
zero-debt state, but it must not erase the rationale that established the
migration's constraints and completion criteria.

Do not treat a pushed feature branch as a substitute for this baseline. A
branch can be rebased, abandoned, or squash-merged; `main` is the stable place
to preserve an accepted migration design.

### Non-goals

- Do not add one build task, runner, or route manifest per App.
- Do not route by changed line count, commit size, filename special cases, or
  the current names of a few representative Apps.
- Do not use historical duration to omit a required test.
- Do not keep a permanent legacy family fallback or an allowlist of unmigrated
  test files after this branch is complete.
- Do not weaken full PR or main-push CI.

### Durable ownership model

Every production and test path resolves to an owner key. Owner keys are data,
not public task names:

```text
apps/<family>/<app_slug>/<scope>
labkit_framework/<area>/<scope>
project/<topic>/<scope>
```

For an App, `<scope>` is either a source capability name with the leading `+`
removed, or one of these stable product-level scopes:

```text
appContract   definition, projectSpec, createSession, and the entrypoint
workbench     product assembly and cross-capability presentation
smoke         the cheapest downstream launch/layout/callback proof
```

Tests use explicit physical kind paths. Internal plans must never rely on an
unprefixed `apps/...` selector whose meaning changes according to GUI flags:

```text
tests/cases/unit/apps/<family>/<app_slug>/appContract/
tests/cases/unit/apps/<family>/<app_slug>/<capability>/
tests/cases/unit/apps/<family>/<app_slug>/workbench/

tests/cases/gui/apps/<family>/<app_slug>/smoke/
tests/cases/gui/apps/<family>/<app_slug>/<capability>/
tests/cases/gui/apps/<family>/<app_slug>/workbench/

tests/cases/contract/apps/<family>/<app_slug>/<contract>/
tests/cases/contract/apps/shared/<contract>/

tests/cases/unit/labkit_framework/<area>/<scope>/
tests/cases/gui/labkit_framework/<area>/<scope>/
tests/cases/contract/labkit_framework/<area>/<scope>/
```

A test has one lowest meaningful owner. A test that independently loops over
many Apps is not independently routable and must become selectable per-App
cases. A test that genuinely compares or constrains multiple Apps belongs to
`contract/apps/shared`, not beneath one App or family.

App GUI `smoke` contains only a bounded structural proof. File parsing,
exports, repeated rendering, visual permutations, and complete workflows live
under their owning capability or `workbench`; they must not accumulate in
`smoke` merely to make routing appear simple.

### Owner-minimal route behavior

Resolve each changed path before constructing test selections. Do not build a
conservative plan, compress away exact tests, and then try to shrink the plan.

| Changed owner | Required owner-minimal closure |
| --- | --- |
| App capability source | Matching unit capability when present; matching GUI capability when present; that App's smoke; that App's isolated-path contract |
| App entrypoint, definition, projectSpec, or createSession | App `appContract`; App smoke; App isolated-path contract |
| App workbench source | App `workbench` unit/GUI; App smoke; App isolated-path contract |
| Exact test file | That file, unless the same canonical tests are already selected by a required owner scope |
| Shared test fixture/helper | Direct test consumers discovered from qualified calls; unknown consumers fall back conservatively |
| Framework source | Direct framework scope plus the framework impact closure defined below |
| App manual, component history, or generated App site output | Focused documentation integrity, link, App-manual, history, and generated-output contracts |
| Documentation renderer or discovery policy | Complete documentation contract suite |
| Runner or build routing source | Focused runner/build self-contracts |
| Unknown tracked path | Full non-GUI fallback, with the unresolved path printed |

During migration only, a missing capability test directory may fall back to
the App scope, then family scope. Every fallback must be printed as a migration
gap. Remove both fallback levels before completing this migration.

### Framework impact closure

Framework changes are not equivalent. Classify them before selecting
downstream Apps.

#### Leaf facade areas

Changes under `labkit.image`, `thermal`, `dta`, `rhs`, and `biosignal` select:

1. the deepest matching framework unit/contract scope;
2. framework GUI coverage only when the changed scope owns GUI behavior;
3. direct App capability consumers discovered from qualified calls to the
   affected facade area or public symbol;
4. the smoke test of each directly affected App when the public behavior can
   reach product assembly.

An internal helper change that cannot be mapped safely to one public symbol
uses the entire facade area as its public impact boundary. It must not fall
back to unrelated App families.

#### App SDK public contracts

Changes to `labkit.app.Definition`, layout specs, view snapshots, event values,
callback context, project contracts, and public diagnostic contracts select:

1. their direct framework unit/contract tests;
2. independently selectable headless App contract cases for every App that
   constructs or consumes the changed contract;
3. framework GUI tests for changed UI semantics;
4. a minimal downstream App GUI smoke portfolio covering all affected semantic
   features.

If every App consumes the public contract, all cheap headless App contract
cases are required. Do not substitute two arbitrary Apps for this proof.

#### Runtime and platform internals

Changes to App runtime, reconciliation, platform adapters, callback dispatch,
project restoration, or lifecycle internals select:

1. the matching framework unit and structural GUI scopes;
2. all cheap headless App contracts affected by that runtime boundary;
3. the smallest downstream GUI smoke portfolio that covers the changed
   semantic features;
4. all App GUI smoke tests only when the changed boundary is universal and no
   sound feature-specific portfolio exists.

Unknown `labkit.app.internal` paths are universal App-runtime changes. Prefer a
safe all-smoke fallback over an incorrectly narrow plan, and print why the
fallback was necessary.

#### Semantic feature coverage

App and framework smoke tests declare stable route-feature tags through
official MATLAB test tags. Use concepts such as layout node kind, typed event
kind, managed interaction, project restoration, axes presentation, or file
selection. Do not tag tests with transient bug names or implementation files.

The framework impact rule produces required feature tags. For downstream GUI
proof, select a deterministic minimum-cost set of smoke tests whose union
covers all required features:

1. correctness filters candidates by required features and actual consumer
   ownership;
2. ignored local timing artifacts may rank otherwise equivalent candidates;
3. no timing data uses a stable lexical tie break;
4. a missing feature candidate falls back to every affected App smoke and
   reports the metadata gap;
5. CI still runs the complete GUI suite.

Historical timings are advisory and remain under ignored `artifacts/`. They
must never be tracked design state or affect whether a required feature is
covered.

### Route compiler contract

Replace the current sequence of loosely coupled plan steps with a compiler
that separates correctness from execution:

1. Collect added, modified, renamed, and deleted paths. A rename contributes
   both old and new owners when they differ.
2. Resolve each path into kind, owner key, scope, and impact class.
3. Expand direct tests, per-App contracts, framework consumers, semantic GUI
   features, and focused project contracts.
4. Resolve the deepest existing physical test scope. A zero-match required
   scope is a planning failure, not a passing run.
5. Discover the official MATLAB suite once and compile every logical target to
   canonical test identities.
6. Union canonical identities and attach all reasons to the surviving test.
   A test executes at most once even if source, test, docs, and contract paths
   selected it independently.
7. Execute a bounded non-GUI group and, when required, a hidden-GUI group.
   Do not launch one runner execution per changed file.
8. Print owners, resolved scopes, fallback decisions, canonical test count,
   duplicate count removed, and the latest advisory duration estimate.

The route compiler may be rewritten rather than preserving
`fastPlanSteps`, `compressPlanSteps`, or the current step representation. Keep
`runLabKitTests` as the official discovery/execution foundation and keep the
public build task names stable.

### Required guardrails

Guardrails discover current Apps and framework areas from the repository; they
must not duplicate the App catalog.

- Every public App has `appContract`, GUI `smoke`, and independently selectable
  isolated-path coverage.
- Unit and GUI App tests do not live directly at
  `tests/cases/<kind>/apps/<family>/`.
- A nested App test scope matches a real source capability or one of the
  stable product-level scopes.
- An ordinary App capability change does not select another App.
- Framework leaf-facade changes select only actual consumers plus direct
  framework tests.
- Universal App SDK/runtime changes cover all required headless App contracts
  and all required semantic GUI features.
- An exact changed test remains selected after production scopes are merged.
- Unknown paths retain the full non-GUI fallback.
- Compiled canonical identities are unique and every required target matches
  at least one test.
- Route tests assert ownership and set relationships, not a fixed repository
  test count or timing threshold.

### Migration phases

Implement one phase at a time. Keep each checkpoint behaviorally coherent and
use focused runner/build self-tests until the branch is ready for its one
`changedFast` gate.

#### Phase 1: characterize and protect the current behavior

1. Add route-listing fixtures for an App root file, App capability file,
   framework leaf facade, App SDK public contract, runtime internal, docs,
   exact test, shared helper, rename, deletion, and unknown path.
2. Record current canonical selections and measured wall times in ignored
   artifacts for comparison; do not encode current counts as permanent policy.
3. Add a failing regression proving that one canonical test cannot appear in
   two executable groups.

Exit: route self-tests describe every impact class and reproduce the current
duplicate App isolation selection.

#### Phase 2: introduce explicit owners and compile once

1. Add the path-to-owner resolver and explicit `unit/`, `contract/`, and
   `gui/` physical suite targets.
2. Remove the `groupMatchesSuite` rule that implicitly adds `contract/apps` to
   every `apps/...` target.
3. Compile logical selections to canonical test identities, union duplicates,
   preserve all reasons, and execute bounded non-GUI/GUI groups.
4. Make zero-match required selections fail with owner diagnostics.

Exit: the existing test tree still runs, implicit contract expansion is gone,
and no canonical test executes twice.

#### Phase 3: migrate App unit and contract ownership

1. Move single-App unit tests from family roots into App roots.
2. Move each test into `appContract`, `workbench`, or its real capability.
3. Split family aggregate tests into independently selectable per-App cases.
4. Refactor isolated-path coverage into one reusable implementation with one
   independently selectable case per App.
5. Keep truly cross-App contracts under `contract/apps/shared`.

Migrate one family per checkpoint. After the final family, enable the strict
path guardrail and delete the family fallback before merging the branch.

Exit: an App capability source change resolves to that App and capability
without selecting family siblings.

#### Phase 4: create the cheap App proof kernel

1. Give every App a direct headless `appContract` test.
2. Extract one bounded GUI `smoke` test per App.
3. Move parsing, export, repeated-render, permutation, and complete workflow
   methods out of smoke and into capability/workbench files.
4. Split measured long GUI classes first, but apply the same ownership rule to
   every App regardless of current runtime.
5. Add stable semantic feature tags to smoke tests.

Exit: all Apps participate in the same minimal route, and selecting smoke does
not recursively select heavy capability workflows.

#### Phase 5: migrate framework tests and downstream impact

1. Mirror framework unit/GUI tests by area and meaningful scope.
2. Replace hard-coded family switches with facade consumer discovery.
3. Define App SDK/runtime semantic impact rules and smoke feature tags.
4. Implement deterministic feature-cover selection with safe all-smoke
   fallback.
5. Add fixtures proving leaf facades, public SDK contracts, and runtime
   internals produce different affected closures.

Exit: framework changes run their direct proof plus the smallest sound
downstream closure; unrelated families and workflows are absent.

#### Phase 6: focus project and documentation routes

1. Split documentation integrity, links, App manuals, history, search, and
   renderer regression into independently selectable scopes.
2. Map authored and generated paths to the same logical documentation owner so
   regenerated site files do not multiply execution.
3. Keep the full documentation suite for renderer, discovery, navigation, or
   documentation-policy changes.
4. Apply the same explicit owner and canonical-union behavior to build, CI,
   release, deployment, profiling, and launcher changes.

Exit: ordinary App source/manual/history updates select the focused docs
kernel, while infrastructure changes retain comprehensive contracts.

#### Phase 7: activate and remove migration support

1. Point `changedFast` directly at the owner-minimal compiler. Remove the
   post-hoc fast-plan shrinking implementation.
2. Remove family and missing-feature migration fallbacks after every owner is
   represented.
3. Update `tests/AGENTS.md`, the testing manual, and the test-planner skill with
   only the durable workflow.
4. Run the focused route self-tests, then one final `changedFast`; rely on PR
   CI for complete headless and GUI validation.
5. Compare the representative route listings and wall times with Phase 1 and
   record the completed evidence in component history.
6. Delete this active migration entry.

Exit: no active routing debt, fallback, duplicate selection, family-root App
test, or hard-coded representative App list remains.

### Low-reasoning implementation protocol

For each phase:

1. Read only this active entry, `tests/AGENTS.md`, the affected runner source,
   and the exact affected tests.
2. Add or update the focused route contract before changing production route
   behavior.
3. Make one semantic change; do not combine path migration, route semantics,
   GUI test decomposition, and documentation focusing in one patch.
4. Use repository discovery for Apps and capabilities. Do not paste the
   current App inventory into runner code.
5. Preserve the official runner, progress, JUnit, zero-match failure, hidden
   GUI mode, and full CI tasks.
6. Run only the focused route/build test while iterating. When a moved test is
   involved, list it first and verify its canonical name is unchanged.
7. Inspect the diff for accidental source edits and sensitive fixture data.
8. Commit a coherent checkpoint and push it. Do not mark a phase complete
   until its exit condition is enforced by tests.

Stop and request design review instead of guessing when a test has multiple
plausible owners, a framework change has an undeclared dynamic consumer, a
semantic feature has no smoke candidate, or the only available downstream
proof is a long complete workflow.

## Intentional compatibility

Read-only saved-data compatibility is not automatically migration debt. Retain
it when current user files need it and the current writer emits only the
current format:

- Video Marker imports its declared legacy project variable and writes the
  current `labkitProject` envelope.
- Current App project specs migrate supported older payload versions through
  one version-aware `Migrate` entry.
- `labkit.dta` retains documented legacy field aliases beside canonical,
  unit-explicit fields until a future major-version decision.

Do not use a saved-data promise to justify old source layouts, launch
factories, migration callback collections, or undocumented UI nodes.

## Maintaining the ledger

Open an entry only for a concrete current problem with an owner, observable
effect, focused test, completion criteria, and removal condition. Do not treat
file length, helper count, or a possible future abstraction as migration debt.

Temporary MathWorks Toolbox use must record the exact source symbol, product,
owner, repository fallback, fallback test, idempotency evidence, numeric parity
outputs and tolerance, and the condition for deleting the Toolbox branch. Its
machine-readable declaration lives in `tests/runner/labkitToolboxDebt.m`.

When an entry is resolved, delete it and any debt-only guardrail in the same
change. Preserve durable decisions and evidence in the owning manual and
component history when project policy requires them.
