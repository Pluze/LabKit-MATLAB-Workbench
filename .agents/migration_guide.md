# Migration Debt Ledger

This file records only active architecture migration or compatibility-retirement
debt. Current supported behavior belongs in `docs/`; execution rules belong in
the nearest `AGENTS.md`; exact validation commands belong in
`docs/development/maintain-and-release/testing.md`; completed work belongs in
component history.

## Active debt

Last audited: 2026-07-23.

```text
toolbox-product-debt: none
architecture-migration-debt: test-framework-contract-routing
```

### Test framework contract routing

Owner: `tests/`.

Observable effect: capability changes can miss direct behavioral tests when
those tests are physically grouped under `workbench`; changed validation also
pays for route listing and canonical rediscovery before executing exact tests.

This section is the sole active roadmap. Human documentation continues to
describe only the current supported test framework until the atomic cutover
delivers a new current architecture.

#### Outcome

The replacement keeps three decisions independent:

```text
Source owner          what production subject changed
Behavior contract     what observable behavior must remain true
Execution environment how the selected evidence must run
```

The source tree determines the subject and its default boundary. Stable
contract rules determine the evidence required for that source role. Test
metadata states only facts that cannot be derived safely from paths or
measured results.

The final framework must:

- select direct scientific, state, persistence, presentation, rendering,
  result, product, or system behavior at risk;
- avoid repository-wide discovery for focused and changed validation when
  the affected owner closure is known;
- fail planning when required evidence is missing;
- run each exact discovered test identity once;
- replace repeated App definition, isolation, and smoke wrappers with
  parameterized conformance specs;
- delete the old directory kinds, substring selectors, list-and-rediscover
  chain, route-feature tags, artifact layout, and task-name compatibility.

This migration does not change App behavior, scientific formulas, output
schemas, saved-project compatibility, public entrypoints, or the `+labkit`
runtime API.

#### Baseline evidence

Measured on 2026-07-23 with MATLAB R2025a on Apple silicon:

- the official catalog contains 621 tests across 204 classes;
- the App source tree contains 145 capability directories, while only 22 App
  unit scopes match a production capability name;
- 31 of 55 App unit test files are grouped under `workbench`;
- changing `cic.analysisRun.computeCIC` currently selects only the CIC
  isolated-path contract and App smoke, not `ComputeCICTest`;
- current full grouped discovery takes about 13.37 seconds, and one recursive
  discovery takes about 12.65 seconds;
- compiling the current two-route CIC calculation plan takes about
  20.24 seconds: 16.92 seconds to list route matches and 3.32 seconds to
  rediscover canonical name groups;
- runner implementation, build integration, and their direct guardrails total
  about 3,457 nonblank, non-comment MATLAB lines.

Disposable official-`matlab.unittest` prototypes compared 63 wrapper classes
with three parameterized conformance classes producing the same 63 identities:

| Structure | MATLAB files | Effective lines | Discovery median | Execution median |
| --- | ---: | ---: | ---: | ---: |
| One wrapper per App and contract | 63 | 441 | 1.331 s | 14.915 s |
| Three parameterized conformance classes | 4 | 54 | 0.080 s | 0.647 s |

Parameterized identities remained independently selectable. One synthetic App
selected exactly its definition, isolation, and smoke identities and executed
those three in 0.429 seconds.

An owner-first CIC prototype provided five scientific, two result, two
presentation, and one product method:

- complete App-owner discovery took 0.254 seconds;
- exact calculation-file discovery took 0.101 seconds;
- planning the calculation change into nine exact test objects took
  0.319 seconds;
- executing those nine objects took 1.087 seconds;
- removing the result and presentation specs produced a deterministic
  missing-contract error.

The current real CIC unit, contract, and GUI owner folders contain twelve
tests. Discovering those scopes has a 0.285-second median; discovering the
current calculation test file directly takes 0.049 seconds.

Branch progress measured on 2026-07-23 (not a final acceptance benchmark):

- the legacy local `changedFast` checkpoint treated a committed new image
  specification as generic test support, selected one `project` route, and
  ran 211 headless tests in 92.14 seconds (zero failures, one skip);
- the current complete headless profile ran 183 exact identities with zero
  failures; its migrated framework owners are `app`, `biosignal`,
  `dta`, `image`, `rhs`, and `thermal`, and its App behavior owners cover CIC,
  CSC, Chrono Overlay, EIS, VT Resistance, Gait Analysis, DIC Postprocess,
  DIC Preprocess, Focus Stack, ECG Print, RHS Preview, Response Review Stats,
  Nerve Response Analysis, T-test Wizard, Curvature, Video Marker, Batch Crop,
  FLIR Thermal, and Image Enhance. The former
  82-test/23.459-second observation is superseded; record a final
  cross-platform wall-clock benchmark after the remaining App and repository
  migration is complete;
- `Profile="changed"` now preserves the local checkpoint contract: it includes
  tracked and untracked working-tree paths, and on a clean worktree reports
  the just-created commit. Temporary-repository system specs cover both paths.

The new count is intentionally incomplete until every owner is migrated; this
comparison proves removal of the legacy `project` fallback, not final suite
coverage or a release performance claim.

These measurements select owner-scoped discovery, exact in-memory
`TestSuite` execution, parameterized conformance, pure owner/contract rules,
and fail-on-missing-contract behavior. They reject unconditional full-catalog
discovery, one-App wrapper files, canonical name rediscovery, a general MATLAB
dependency graph, manual cost tags, and a public `labkit.test` package.

#### Target ownership

Test infrastructure remains repository support code under:

```text
tests/+labkittest/
```

Do not create `+labkit/+test` or another shipped facade.

Runnable specs use owner-first paths:

```text
tests/specs/
├── apps/<family>/<app_slug>/
│   ├── product/
│   ├── project/
│   ├── session/
│   ├── workbench/
│   ├── <workflow_capability>/
│   └── journeys/
├── framework/
│   ├── app/
│   ├── image/
│   ├── thermal/
│   ├── dta/
│   ├── biosignal/
│   └── rhs/
└── system/
    ├── build/
    ├── ci/
    ├── documentation/
    ├── launcher/
    ├── packaging/
    ├── release/
    └── repository/
```

App source mapping:

| Production source | Test owner |
| --- | --- |
| `labkit_*_app.m` | `product/entrypoint` |
| `definition.m` | `product/definition` |
| `projectSpec.m` | `project` |
| `createSession.m` | `session` |
| `+workbench/buildLayout.m` | `workbench/layout` |
| `+workbench/present.m` | `workbench/presentation` |
| `+<capability>/*` | the same capability |
| complete cross-capability flow | `journeys` |

`workbench` owns composition only. Calculations, parsers, writers, renderers,
and capability-local state transitions do not use it as a fallback test
folder.

`tests/shared/` continues to own small synthetic fixtures, semantic
assertions, GUI probes, and lookup helpers.

#### Contract catalog

Each descriptor contains:

```text
Id
Owner
Contracts
Environment
Test
```

`Owner` comes from `TestSuite.BaseFolder`. `Id` comes from the official name,
including parameterization. `Test` is the discovered object executed directly.

Tests declare only:

```text
Contract:<name>
Env:<name>
```

Initial contracts:

```text
product
definition
source
scientific
state
persistence
presentation
rendering
result
system
```

Automated environments:

```text
headless
hidden-gui
isolated-process
```

Level is derived from ownership. Cost and ETA come from prior JUnit results.
Manual visual, pointer, native-dialog, real-data, and scientific review stay
outside the automated catalog and are recorded as plan manual checks.

Catalog validation rejects unknown owners or contracts, missing or multiple
environments, duplicate exact identities, automated tests marked manual, and
required owner-contract pairs with no evidence.

#### Planning rules

The planner uses a bounded structural model:

```text
changed path or maintainer query
  -> source owner and file role
  -> required owner-contract pairs
  -> bounded framework or consumer propagation
  -> owner-scoped official discovery
  -> exact test descriptors
  -> environment execution groups
```

Reliable facts are App, workflow capability, reserved root-file role,
framework package, and system area. Qualified source references may expand a
facade consumer set but never justify unsafe narrowing. Dynamic relationships
use explicit framework propagation rules and conservative fallback.

Initial App rules:

| Changed role | Required evidence |
| --- | --- |
| scientific calculation | direct scientific plus bounded result-schema and presentation consumers |
| source parser or loader | parsing, schema, error, and relevant session reconstruction |
| state callback | transition, rollback, idempotency, and resource cleanup |
| `projectSpec.m` | create, validate, every migration edge, round trip, wrong/newer rejection |
| `createSession.m` | reconstruction, portable sources, cleanup, transactional failure |
| capability `present.m` | presentation fragment and workbench composition |
| renderer `draw.m` | semantic graphics and lifecycle; adapter only when native reconciliation changes |
| result writer | schema, units, destination, overwrite, atomicity, display/export parity |
| layout or definition | definition compilation, structural adapter, isolated launch, smoke |

Ordinary calculation and writer changes do not select smoke.

Initial framework propagation:

| Framework change | Bounded propagation |
| --- | --- |
| definition/compiler | framework definition plus every parameterized App definition |
| runtime transaction | rollback/queue plus representative product journeys |
| project envelope | framework persistence plus every App project contract |
| native adapter | adapter structure plus minimum feature-complete hidden-GUI products |
| leaf facade | direct facade plus discovered App consumers; missing evidence widens |

Every requirement carries a reason. Unknown paths select full headless and set
`Fallback=true`. Paths that should be structurally understood but are not
mapped fail the model guardrail so fallback cannot become permanent policy.

#### Maintainer interface

Target MATLAB calls:

```matlab
labkittest.plan(Profile="changed")
labkittest.run(Profile="changed")
labkittest.run(File="apps/.../computeCIC.m")
labkittest.run(Owner="apps/electrochem/cic/analysisRun")
labkittest.run(Owner="apps/electrochem/cic/analysisRun", ...
    Contract="scientific")
labkittest.explain("apps/.../computeCIC.m")
labkittest.catalog(Owner="apps/electrochem/cic")
```

`File`, `Owner`, `Contract`, and `Profile` compile a plan. They are not
executor selectors. The internal executor accepts only a compiled plan.

Target build tasks:

```text
changed
headless
gui
coverage
docs
docsCheck
listTasks
```

`headless` continues to include non-GUI system contracts. Do not add a
separate system task that permits packaging, documentation, release, or
repository contracts to be omitted.

#### Parameterized App conformance

Use three generic specs:

```text
AppDefinitionConformanceSpec
AppIsolationConformanceSpec
AppSmokeConformanceSpec
```

Parameters come from path-derived public App discovery, not a new manifest.
Each App remains exactly selectable through its parameterized identity.
App-specific defaults, migrations, science, sessions, presentation, exports,
and journeys remain in App-owned specs.

#### Execution and artifacts

Compile at most one headless and one hidden-GUI in-process group. True
isolated-process tests form a small explicit group. Broad execution remains
single-process unless an end-to-end benchmark proves a material benefit after
startup, licensing, platform, status, and tail latency.

Target artifact tree:

```text
artifacts/runs/<run-name>/
├── manifest.json
├── plan.json
├── events.jsonl
├── junit.xml
├── summary.json
├── matlab.log
└── gui/
```

`plan.json` records changes, owners, roles, contracts, propagation, exact ids,
execution groups, fallbacks, and manual checks. Progress retains current-test,
heartbeat, and ETA data.

#### Legacy deletion

The atomic cutover deletes:

- `tests/cases/unit`, `tests/cases/contract`, and `tests/cases/gui`;
- the `runLabKitTests` selector surface;
- `Suites`, substring `Tests`, raw `Tags`, `IncludeGui`, `ListOnly`, and
  `Plan` executor options;
- list-only route discovery and canonical name rediscovery;
- route-feature source scanning and smoke cover heuristics;
- ineffective `fast` and `conservative` mode names;
- per-App definition, isolated-path, and smoke wrappers;
- implementation-text guardrails that pin private runner functions;
- the `changedFast` task name and every alias preserving it;
- the old split artifact roots.

The implementation branch may compare plans in a disposable shadow harness.
No dual runner, alias, old artifact contract, or transitional selector reaches
the final mainline cutover.

#### Working order

1. Model and catalog:
   - add table-driven source-owner and role fixtures;
   - implement contract/environment validation and scoped catalog discovery;
   - test missing contracts, duplicate ids, invalid owners, and invalid tags;
   - add `labkittest.explain` without changing build tasks.
2. App behavior ownership:
   - move calculations, sources, results, presentation, rendering, and state
     tests from `workbench` to real capabilities;
   - split aggregated methods into diagnosable scenarios;
   - add contract and environment metadata.
3. Parameterized conformance:
   - replace App definition, isolated-path, and smoke wrappers;
   - prove exact per-App parameter selection;
   - keep App-specific product contracts separate.
4. Planner and executor:
   - implement bounded propagation;
   - compile and run exact in-memory test objects;
   - group by environment and write run-centered artifacts;
   - connect focused file, owner, contract, and changed profiles.
5. Atomic cutover:
   - switch `buildfile.m`, CI, test-planner skill, AGENTS guidance, and the
     testing manual;
   - rename `changedFast` to `changed`;
   - update CI summaries and uploads;
   - delete the complete legacy surface.
6. Completion:
   - run the benchmark corpus and complete cross-platform CI;
   - perform required developer-led manual App checks;
   - record durable final behavior and evidence in current docs and component
     history;
   - delete this active migration entry in the final zero-debt squash.

Each checkpoint is committed and pushed when its focused evidence passes. Run
`changed` once only when the implementation branch is ready for review.

#### Acceptance gates

Selection:

- representative calculation, layout, project, session, result, facade,
  runtime, documentation, CI, and unknown fixtures select reviewed closures;
- missing required evidence fails planning;
- zero matches never pass;
- each exact identity executes at most once;
- fallback is visible and conservative.

Efficiency:

- focused files do not discover the repository catalog;
- changed validation discovers only affected owners and shared conformance;
- the representative calculation plan compiles in less than 3 seconds on the
  baseline machine, excluding MATLAB startup;
- a fixed changed-path corpus improves median end-to-end validation by at
  least 40 percent;
- broad execution stays single-process absent contrary measured evidence.

Maintainability:

- runner, planner, artifact code, and direct guardrails are at least
  25 percent smaller than the 3,457-line baseline;
- common App wrappers become no more than three conformance classes and one
  path-derived parameter provider;
- guardrails inspect public behavior and official metadata rather than
  private implementation text;
- `+labkit` gains no test package.

Delivery:

- complete headless and hidden-GUI suites pass on Linux, macOS, and Windows;
- JUnit, active-test, heartbeat, ETA, failure summaries, and debug/GUI
  artifacts remain available;
- current architecture and testing docs are updated only at cutover;
- no real lab data or identifying paths, filenames, users, devices, or
  timestamps enter fixtures or evidence.

#### Rollback and removal

Before cutover, revert a failed checkpoint within the implementation branch
while the current mainline runner remains authoritative. After cutover,
rollback means reverting the whole cutover commit, not maintaining two
frameworks.

If scoped discovery cannot prove safe narrowing, widen visibly and fix the
structural rule. Do not encode a one-off filename exception as general policy.

Removal condition: delete this complete active entry after cutover is merged,
complete CI and required manual evidence are recorded in component history,
current docs describe the delivered framework, and repository search finds no
old selector, route-feature, wrapper, task-name, or artifact compatibility.

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
