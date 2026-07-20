# Testing

[Development index](../README.md) | [Architecture](../build-apps/architecture.md) |
[Maintainer Tools](../tools/README.md) | [Performance Profiling](../tools/profiling.md)

Use this page to choose the smallest supported validation entry point. The
public build-task set is intentionally small; changed-file tasks inspect the
current git diff and print why each selected scope is being run.

## How The Test System Fits Together

`buildfile.m` owns the stable human and CI commands. Those tasks select a
validation plan and call `tests/runLabKitTests.m`, which discovers official
`matlab.unittest` tests beneath `tests/cases/`, applies folder, exact-file,
name, tag, GUI, and shard selectors, then runs them with progress, JUnit,
optional HTML, and optional coverage plugins.

```text
buildtool <task>
  -> changed-file plan or explicit selection
    -> runLabKitTests discovery and selectors
      -> unit, contract, or GUI tests
        -> progress, JUnit, HTML, coverage, and debug artifacts
```

Test ownership mirrors production ownership:

- unit tests exercise deterministic calculations, parsers, and project tools;
- contract tests protect public APIs, architecture, documentation, packaging,
  release rules, and repository hygiene;
- GUI structural tests validate launch, layout, and callback wiring;
- GUI workflow tests use hidden real figures and synthetic data to validate
  semantic outcomes;
- manual testing remains responsible for file dialogs, drawing feel, visual
  quality, scientific review, and complete interactive workflows.

The changed-file planner maps modified paths to these owners. It is routing,
not a second test framework: the selected tests still run through the same
official runner used by broad build tasks and CI.

## Default Check

Run the default broad non-GUI check when you are not sure which focused scope
applies:

```bash
buildtool headless
```

If `buildtool` is not available in your shell, find your MATLAB app and add its
`bin` directory to `PATH`, then rerun the same command:

```bash
ls /Applications/MATLAB_*.app/bin/matlab
export PATH="/Applications/MATLAB_R2025a.app/bin:$PATH"
```

If MATLAB exits before printing a build-task banner such as
`** Starting headless` or a `LabKit official test run` line, treat that as a
MATLAB launcher or runtime access failure before diagnosing source or test
failures.

Every official run writes `test-progress.jsonl`, `active-test.json`, and
`active-test.txt` under its `artifacts/logs/<run-name>/` folder. The first file
records suite, test, and long-test heartbeat events. The JSON snapshot records
the latest structured state; the TXT snapshot presents the same state as a
single `START`, `RUN`, `PASS`, or `DONE` line for humans. CI gives the MATLAB
execution step a shorter timeout than the containing job so the always-run
summary and artifact upload steps can still publish these diagnostics when a
test stalls before JUnit is complete.
When a local broad task uses parallel internal shards, the orchestrator relays
each shard's human-readable active-test line at a fixed interval. It clears
the prior run's transient snapshot before worker startup, so startup cannot
look like an already completed run. A failed run prints only the failing shard
log; complete logs remain under `artifacts/logs/<run-name>-orchestrator/`.
Each active line includes that shard's elapsed time and estimated remaining
time once at least one test has completed. Local child MATLAB processes are
started through one MATLAB/Java process wrapper on macOS, Linux, and Windows;
the buildfile does not generate platform shell scripts. GitHub Actions remains
single-process because concurrent hosted MATLAB license behavior is not part
of the validated CI contract.
The probe also partitions complete test-class files among workers. Each worker
discovers only its assigned files, so methods from one class stay together and
the full test tree is not rediscovered once per shard.

## Build Tasks

Use MATLAB build tasks for the stable official entry points:

```bash
buildtool changed
buildtool changedFast
buildtool docs
buildtool docsCheck
buildtool headless
buildtool gui
buildtool coverage
buildtool listTasks
```

| Task | Use it for |
| --- | --- |
| `changedFast` | Tight local iteration from the current diff; substitutes representative GUI coverage for expensive broad GUI scopes. |
| `changed` | Conservative pre-handoff validation from the current diff. |
| `docs` | Rebuild the tracked `site/` tree from path-organized Markdown and MATLAB help contracts. |
| `docsCheck` | Regenerate documentation in a temporary folder and compare it byte-for-byte with tracked `site/`. |
| `headless` | Full non-GUI validation. |
| `gui` | Full automated GUI validation with hidden figures. |

Report and discovery tasks:

| Task | Use it for |
| --- | --- |
| `coverage` | Manual or scheduled coverage reports. |
| `listTasks` | Print the current build task catalog. |

## Choosing A Task

Prefer automatic routing before hand-picking suites:

Common choices:

| Change area | Build task |
| --- | --- |
| Tight local iteration on one known component | Focused `runLabKitTests` folder or test-name selection |
| Stable branch work before PR preparation | Focused `runLabKitTests` selection |
| Preparing a branch for PR review | `buildtool changedFast`, then `buildtool changed` |
| Direct-main integration or explicitly final handoff | `buildtool changed` |
| Rebuild documentation after editing sources or public help contracts | `buildtool docs` |
| Verify generated documentation is current | `buildtool docsCheck` |
| Full broad non-GUI validation | `buildtool headless` |
| Full automated GUI validation | `buildtool gui` |
| Coverage report | `buildtool coverage` |

`changedFast` and `changed` require a git checkout. In exported source trees,
packaged copies, or environments without git state, use `headless` or an
explicit `runLabKitTests` suite selection instead.

Documentation checks cover more than generated-file freshness. They also
verify local links, search behavior, public API coverage, executable examples,
component history metadata, and the absence of known empty history-page
boilerplate. These checks catch structural regressions; a human review is still
required to decide whether an explanation is accurate, complete, and readable.

Project style and code-quality guardrails normally scan only public repository
files. A private app workspace can opt in by placing an empty
`.labkit-accept-main-guardrails` file at the private workspace root. Accepted
roots under `private_apps/apps/` or `LABKIT_PRIVATE_APP_ROOTS` are included in
source-text quality scans and Code Analyzer reports without adding private
source to the public repository. For temporary local checks,
`LABKIT_GUARD_PRIVATE_APPS=1` includes configured private roots even without
the sentinel file.

Toolbox compatibility guardrails protect the Base MATLAB user path. Every
ordinary and release CI runner installs MATLAB without optional Toolboxes, so
the complete headless and hidden-GUI suites execute in the same dependency
baseline promised to users. Source guardrails also reject known undeclared
non-base calls under `apps/` and `+labkit/` and run representative workflows
with known Toolbox helpers shadowed on the MATLAB path. CI deliberately does
not install candidate Toolboxes or infer product ownership from an
all-products development environment: successful execution in a clean runtime
is the primary contract.

A temporary MathWorks product path is accepted only through an exact entry in
`tests/runner/labkitToolboxDebt.m` that names its source, symbol, product,
owner, no-Toolbox fallback test, idempotency test, Toolbox parity test, and
repository-owned replacement. Numeric or scientific replacements must also
prove identical inputs reproduce the same app-consumed values; stateful
operations must prove that safe repetition does not compound state or side
effects. Compare the outputs consumed by the app, including
downstream decisions or exports, within a documented tolerance. The same ID
remains active in the debt registry until the Toolbox branch is deleted. This
records debt without hiding it: dynamic invocation does not satisfy the
contract, broad product allowlists are rejected, and the Base MATLAB path must
provide comparable user-visible behavior until the Toolbox branch is deleted.

Private workspaces under `private_apps/` are separate Git repositories, so the
public `changed` and `changedFast` tasks do not discover their diffs. Validate a
private change with that workspace's own test entry point, such as
`addpath('private_apps/tests'); run_private_tests`, which can reuse the public
runner and shared guardrails.
Do not substitute the full public `headless` task only because the public
checkout has no changed paths. The `.labkit-accept-main-guardrails` sentinel
controls quality-scan inclusion; it does not change Git diff discovery. When an
accepted private workspace has unpushed source, test, documentation, component
history, or version changes, run that workspace's private tests and the public
`buildtool changed` guardrail before commit or handoff, or record the exact
MATLAB/runtime blocker. The public guardrail must be invoked intentionally from
the public checkout because the private Git diff is invisible to the public
changed-file planner.

The changed-file planner routes by source ownership. For example, a single app
change maps to that app family plus its GUI folder when one exists; reusable
UI changes map to reusable UI coverage plus downstream GUI coverage; launcher,
deployment, profiling, documentation, and release files map to their direct
project or GUI contracts. A changed test file reruns exactly that file, while
runner and buildfile changes map to the focused `project/build` self-tests.
Unknown production or repository files still fall back conservatively. The
printed plan includes selected folders, files, test-name selectors, GUI mode,
and the reason for each step.

Every public App source change also runs `AppIsolatedPathContractTest`. That
test restores the default MATLAB path, adds only the LabKit root and one owning
App root, then loads the definition, checks facade compatibility, and writes
the App's synthetic debug sample. Static sibling-call checks remain separate;
together they prevent the all-App setup used by ordinary family tests from
hiding a package dependency.

## Validation Cadence

Prefer a staged validation cadence so small follow-up edits do not repeatedly
pay the cost of broad changed-file planning:

1. While actively editing one known component, run the smallest direct
   `runLabKitTests` selection that covers the behavior being changed. Use
   `Suites` for a folder scope under `tests/cases`; use `Tests` for a class or
   method-name selector, or `Files` for exact `.m` paths. `Suites` deliberately
   rejects `.m` file paths so a mistaken file selection cannot silently expand
   into a whole folder. For GUI
   wiring, use the affected app GUI suite with
   `IncludeGui=true`, `GuiMode="hidden"`, and `HtmlReport=false` during
   iteration.
2. Before the branch is ready for PR review, keep checkpoints small and stable
   and continue using focused tests. Do not run `changedFast`, `changed`, full
   headless, or full GUI gates merely because an intermediate commit is ready.
3. When preparing the completed branch for PR review, run `changedFast` once
   to inspect the diff-based plan, then treat `buildtool changed` as the final
   changed-file gate. Also use `changed` for direct-main integration or another
   explicitly final handoff unless a recently completed broader gate fully
   covers the current diff.
4. After push, inspect CI for the final pushed commit. If another user-requested
   follow-up supersedes an in-progress run, continue the follow-up locally and
   inspect CI for the newest pushed commit instead of waiting for the
   superseded run.

Do not rerun `changedFast`, `changed`, or CI after every small edit when the
same focused suite can validate the changed behavior more directly. Changes to
additional ownership areas, validation routing, docs, or AGENTS still use
focused checks while the branch is evolving; escalate to changed-file gates
when the branch is being prepared for review or final integration. After a
final `buildtool changed` run exposes a failure, repair with
the narrowest failed suite or test selector, then reserve another
`buildtool changed` run for the final stable diff instead of using it as the
iteration loop.

### Keep Iteration Tests Cheap

A runner result of “one matched test” does not imply a cheap test. One GUI
method may launch a real App, read and write files, commit presentation many
times, render plots, and wait for asynchronous UI work.

Use this cost ladder while fixing behavior:

1. pure helper or calculation test;
2. direct presenter, renderer, state-transition, or callback test;
3. one structural GUI method when handle wiring is the behavior;
4. one complete App GUI workflow after the smaller behaviors are stable;
5. changed-file and broad gates only when preparing for PR review or final
   integration.

When a GUI workflow taking roughly 20 seconds or more fails, diagnose its stack
and reproduce the failed helper, renderer, callback, or presentation value
directly. Do not repeatedly rerun the whole workflow after each small edit.
Accumulate the narrow fixes, then run that workflow once as the integration
confirmation. Before starting an unusually long focused test, state what it
actually exercises and its expected order of runtime so “one test” is not
mistaken for a quick check.

## CI Scope

CI is a clean-room check for omissions that a developer's configured machine
or targeted local test can hide. `ci.yml` installs R2025a with no optional
Toolboxes, then runs:

- `buildtool headless` on Linux, macOS, and Windows;
- `buildtool gui` with hidden figures on Linux, macOS, and Windows.

Both platform matrices use `fail-fast: false`, so one failure does not cancel
the evidence from the other operating systems. Each job keeps JUnit, HTML,
active-test, MATLAB log, debug, and applicable GUI artifacts. The MATLAB
execution timeout is shorter than the containing job timeout so diagnostics
still upload after a stalled test.

`Continuous Integration` runs this required suite for pull requests targeting
`main` and pushes to `main`. Feature-branch pushes do not duplicate the
pull-request run. Coverage has no pass threshold and would only repeat the
non-GUI tests, so `buildtool coverage` remains an explicit local report rather
than a second CI path.

The manual `Release` workflow is separate from ordinary CI. A developer first
completes interactive App testing, dispatches it from `main` with a `vX.Y.Z`
version and confirms that manual validation. The workflow requires an already
successful `Continuous Integration` main-push run for that exact commit; it
does not duplicate the six jobs. Only then does it create the tag and a draft
GitHub Release. Ordinary CI has read-only repository permissions and cannot
create tags.

Workflow YAML calls public buildfile tasks through
`matlab-actions/run-build`; it does not maintain test-class lists, owner shard
lists, CI-only build tasks, shard environment variables, or call the lower-level
runner directly. CI checkouts fetch the candidate and its parent so version and
changed-file contracts have a stable `HEAD^` baseline. GitHub Actions remains
single-process because the parent MATLAB action's license does not imply that
child MATLAB workers can start.

When adding a test, place it under the correct ownership tree and give it the
right stage tag: `Unit`, `Integration`, or `GUI`. GUI tests may add secondary
tags such as `Structural`, `Workflow`, or `Gesture`. Membership follows from
the public `headless` or `gui` task; ordinary test additions should not require
editing workflow YAML.

Hidden GUI automation still cannot prove native file dialogs, pointer feel,
visual quality, scientific validity, or a complete human workflow. That is why
manual App validation remains a required release input rather than an
inference from green CI.

## Test Layout

```text
tests/cases/unit/labkit_framework/
                               reusable +labkit framework behavior
tests/cases/unit/apps/         app-owned helper behavior
tests/cases/unit/project/      project-level helper behavior
tests/cases/gui/labkit_framework/
                               reusable +labkit GUI checks
tests/cases/gui/apps/          app GUI launch, layout, callback, and workflow checks
tests/cases/gui/project/       project entrypoint GUI checks
tests/cases/contract/apps/     long-lived app boundary and app workflow guardrails
tests/cases/contract/project/  project contracts grouped by topic
tests/shared/                  small test-facing assertions, fixture builders, GUI probes, and lookup helpers
tests/runner/                  runner setup, artifact paths, trace plumbing, and artifact writers
```

Project contract tests use a third directory level for the guarded contract,
for example `build`, `ci`, `docs`, `hygiene`, `packages`, `runtime`, or
`release`.

Test paths follow `tests/cases/<kind>/<owner>/<area>/...`. `kind` is
`unit`, `gui`, or `contract`. `owner` is `apps`, `labkit_framework`, or
`project`. The `labkit_framework` owner means reusable `+labkit` framework
code only; repository-level entrypoints such as the launcher use `project`.
Interaction styles such as gesture checks are expressed with `TestTags` and
test class names, not extra ownership paths.

`tests/shared/` intentionally keeps ordinary MATLAB helper functions as
one-function files because those helpers are called directly by tests. Prefer a
plain function file there over a larger registry object unless repeated call
patterns justify a grouped API. Changed-file validation resolves direct test
consumers of a shared helper and reruns those test classes instead of expanding
every shared GUI helper change to the full GUI suite.

Build tasks are the supported human and CI entry points. The lower-level runner
is an implementation detail used by the buildfile.

## Focused Iteration

When diagnosing one failure, rerun the smallest matching suite directly after
adding `tests` to the MATLAB path:

```matlab
addpath("tests")
runLabKitTests("Suites", "gui/apps/image_measurement/batch_crop", ...
    "IncludeGui", true, "GuiMode", "hidden", "HtmlReport", false)
```

To run one class or method, pass its name through `Tests`:

```matlab
runLabKitTests("Tests", "GuiLayoutBatchCropTest", ...
    "IncludeGui", true, "GuiMode", "hidden", "HtmlReport", false)
```

An unqualified method name is accepted when it is unique. To select one method
without ambiguity, use the official `ClassName/methodName` test name:

```matlab
runLabKitTests("Tests", ...
    "PlatformSkeletonTest/artifactPathsUseRunnerLayout", ...
    "HtmlReport", false)
```

For the lowest-learning-cost exact rerun, select the test file directly:

```matlab
runLabKitTests("Files", ...
    "tests/cases/unit/project/PlatformSkeletonTest.m", ...
    "HtmlReport", false)
```

Use `buildtool` for broad validation. The buildfile owns execution mode
decisions, including whether a large non-GUI run is worth splitting across
multiple MATLAB worker processes after a lightweight probe. GitHub Actions and
Windows runs remain serial; supported local broad runs use the repository's
deterministic shard policy. Probe or worker failures are reported instead of
being hidden behind an implicit serial retry. Users and CI should not maintain
separate shard commands.

## GUI Validation

Automated GUI tests check:

- app launch
- layout contracts
- callback wiring
- debug trace plumbing
- reusable tool lifecycle
- hidden synthetic app workflows

Hidden GUI tests use `matlab.unittest.TestCase` while still constructing real
figures and controls. `matlab.uitest.TestCase` is reserved for visible UI
automation because its display driver emits `ViewReady` callback errors for
hidden figures on CI runners.

App GUI layout tests should express user-facing and app-facing contracts:
expected command buttons, dropdown choices, tabs, table columns, axes, callback
wiring, and debug trace behavior. They should not assert raw MATLAB component
class counts, because those counts are framework implementation details.
The shared standard-workbench assertion waits for the startup lifecycle and
fails on deferred startup errors, so a constructed shell is not mistaken for
a successfully launched app.
Reusable LabKit GUI tests may assert low-level control shape only when that
shape is the framework behavior under test.
Avoid duplicating expensive figure launches for the same contract. If an app
already has dedicated GUI coverage, broad entry-point coverage should act as a
missing-coverage guardrail rather than launching it again. For future apps
without dedicated GUI coverage, one debug launch can cover startup, named
figure creation, path hygiene, and visible trace plumbing until app-specific
layout or workflow tests are added.

For scientific and visualization behavior, prefer deterministic value or state
assertions over visual snapshots whenever the result can be expressed as data:
export tables, image dimensions, masks, numeric summaries, axis labels,
selected files, callback events, and debug traces. Use minimal synthetic data
that makes the behavior obvious. Add image or screenshot comparisons only when
the rendered pixels are the actual contract, and keep those baselines focused
on the visual behavior under test rather than the entire app shell.

Repository-wide guardrails should avoid repeated full-tree IO. Cache tracked
file lists or file contents within the test process when several assertions
scan the same scope, and avoid adding a second test that repeats the same scan
with only a different diagnostic wording.

`buildtool gui` runs with hidden test windows by default while still creating
real MATLAB figures, controls, callbacks, and layout trees. The setting is
scoped to the MATLAB test process; visible or minimized GUI mode is only for
local diagnosis, and manual app work should not share that MATLAB session.

They do not prove:

- visual quality
- actual manual drawing quality
- interactive file-selection usability
- full workflow feel

Manual MATLAB review is still required for those user-experience questions.
Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Fixtures And Data Hygiene

Fixtures should be synthetic and minimal. Do not commit raw local lab files,
identifying file names, subject names, device serials, local absolute paths, or
timestamp-shaped sample identifiers.

Thermal parser tests should generate anonymous synthetic radiometric structures
instead of tracking real camera files. Preserve only the container shape,
record offsets, calibration fields, byte-order behavior, and pixel matrix data
needed for regression coverage.

DTA tests generate named synthetic `.DTA` files in a temporary directory through
`dtaFixturePath` and `dtaFixtureDir`. Tests may depend on those synthetic names
for discovery and short-name behavior, but the repository should not track raw
`.DTA` fixture files.

## Numerical Tolerance

Default direct numerical tolerance:

```matlab
abs(oldValue - newValue) < 1e-9
```

Use looser tolerances only for interpolation, plotting alignment, or format
conversion, and document why the looser tolerance is valid.

## Artifacts

The `artifacts/` tree is ignored and reserved for generated outputs, local
scratch evidence, and temporary design notes that support one improvement
round. Do not track files under `artifacts/`; lasting design decisions belong
in the relevant documentation, source comment, or test instead.

Test artifacts are written under:

```text
artifacts/test-results/<RunName>/
artifacts/coverage/<RunName>/
artifacts/code-check/
artifacts/debug/<RunName>/
artifacts/gui/<RunName>/
artifacts/logs/<RunName>/
```

Build tasks set `LABKIT_ARTIFACTS` while tests run, so apps launched in debug
mode write their trace files into the same artifact root:

```text
artifacts/debug/<RunName>/<AppName>/<SessionId>/
```

Coverage is report-only and not part of the default local check.

## App SDK Runtime Contract Coverage

The workflow-first app contract is covered by layered tests, not by a single
launch-only suite:

- `AppPackageStructureGuardrailTest` discovers every `apps/**/labkit_*_app.m`
  entrypoint, requires the canonical `definition.m` and
  `+workbench/buildLayout.m`, verifies references to optional
  action/project/session/presentation capabilities when present, and rejects
  retired metadata files, generic lifecycle/state packages, per-version
  migration files, package-root app runners, and broad app buckets such as
  `+actions`, `+state`, `+ui`, `+view`, `+ops`, `+io`, and `+export`.
- `UiRuntimeKernelTest` owns queued dispatch, canonical state, presentation
  commits, callback-capability injection, rollback, and `OnStart` behavior.
  `UiProjectDocumentStoreTest` owns project persistence, migrations, source
  relinking, and read-only legacy snapshot imports.
  `UiMatlabPlatformAdapterTest` owns the native component and interaction
  adapter boundary.
- `AppOwnedWorkflowBoundariesTest` and `AppLibraryCompatibilityTest` keep app
  workflow code under the owning app tree and prevent apps from depending on
  removed helper-dump or old UI surfaces.
- App GUI workflow tests should cover semantic controls, enabled states,
  workflow outcomes, debug traces, and exported results. Do not add broad
  launch-only coverage for every app when a real workflow or guardrail already
  covers the contract.
- Debug sample-pack tests cover clean-room debug artifacts. Profiler evidence
  is used for performance regressions and should not replace correctness
  assertions.

## Profiling Is Supporting Evidence

Performance profiling is a maintainer tool rather than a correctness test. Use
the complete [Performance Profiling](../tools/profiling.md) reference for targets,
options, report fields, and interpretation. A profile can identify startup or
callback cost, but it does not replace outcome assertions, numeric parity, GUI
workflow coverage, or manual scientific review.
