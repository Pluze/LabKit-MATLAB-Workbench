# Testing

[Development index](README.md) | [Architecture](architecture.md)

Use this page to choose the smallest supported validation entry point. The
public build-task set is intentionally small; changed-file tasks inspect the
current git diff and print why each selected scope is being run.

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

Every official run writes `test-progress.jsonl` and `active-test.json` under
its `artifacts/logs/<run-name>/` folder. The first file records suite, test,
and long-test heartbeat events; the second records the last active test and
elapsed time. CI gives the MATLAB execution step a shorter timeout than the
containing job so the always-run summary and artifact upload steps can still
publish these diagnostics when a test stalls before JUnit is complete.

## Build Tasks

Use MATLAB build tasks for the stable official entry points:

```bash
buildtool changed
buildtool changedFast
buildtool baseMatlab
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
| `baseMatlab` | Explicit compatibility gate: static toolbox-call scan, MATLAB product-ownership analysis, and representative workflows with toolbox helpers shadowed. |
| `docs` | Rebuild the tracked `site/` tree from Markdown, structured catalogs, and MATLAB help contracts. |
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
| Tight local iteration on one known component | Focused `runLabKitTests("Suites", ...)` |
| Coherent local checkpoint while files are still changing | `buildtool changedFast` |
| Before commit, PR, or handoff | `buildtool changed` |
| Verify the repository on a machine that has toolboxes installed | `buildtool baseMatlab` |
| Rebuild documentation after editing sources or public help contracts | `buildtool docs` |
| Verify generated documentation is current | `buildtool docsCheck` |
| Full broad non-GUI validation | `buildtool headless` |
| Full automated GUI validation | `buildtool gui` |
| Coverage report | `buildtool coverage` |

`changedFast` and `changed` require a git checkout. In exported source trees,
packaged copies, or environments without git state, use `headless` or an
explicit `runLabKitTests` suite selection instead.

Project style and code-quality guardrails normally scan only public repository
files. A private app workspace can opt in by placing an empty
`.labkit-accept-main-guardrails` file at the private workspace root. Accepted
roots under `private_apps/apps/` or `LABKIT_PRIVATE_APP_ROOTS` are included in
source-text quality scans and Code Analyzer reports without adding private
source to the public repository. For temporary local checks,
`LABKIT_GUARD_PRIVATE_APPS=1` includes configured private roots even without
the sentinel file.

Toolbox compatibility guardrails protect the base-MATLAB user path. They
reject undeclared non-base calls under `apps/` and `+labkit/`, verify MATLAB's
dependency analysis resolves every product, and run representative workflows
with known toolbox helpers shadowed on the MATLAB path. A temporary MathWorks
product path is accepted only through an exact entry in
`tests/runner/labkitToolboxDebt.m` that names its source, symbol, product,
owner, no-Toolbox fallback test, idempotency test, Toolbox parity test, and
repository-owned replacement. Numeric or scientific replacements must also
prove identical inputs reproduce the same app-consumed values; stateful
operations must prove that safe repetition does not compound state or side
effects. Compare the outputs consumed by the app, including
downstream decisions or exports, within a documented tolerance. The same ID
must remain active in `.agents/migration_guide.md`. This records debt without
hiding it: dynamic invocation does not satisfy the contract, broad product
allowlists are rejected, and the base-MATLAB path must provide comparable
user-visible behavior until the Toolbox branch is deleted.

Private workspaces under `private_apps/` are separate Git repositories, so the
public `changed` and `changedFast` tasks do not discover their diffs. Validate a
private change with that workspace's own test entry point, such as
`addpath('private_apps/tests'); run_private_tests`, which can reuse the public
runner and shared guardrails.
Do not substitute the full public `headless` task only because the public
checkout has no changed paths. The `.labkit-accept-main-guardrails` sentinel
controls quality-scan inclusion; it does not change Git diff discovery. When an
accepted private workspace has unpushed source, test, documentation, changelog,
or version changes, run that workspace's private tests and the public
`buildtool changed` guardrail before commit or handoff, or record the exact
MATLAB/runtime blocker. The public guardrail must be invoked intentionally from
the public checkout because the private Git diff is invisible to the public
changed-file planner.

The changed-file planner routes by source ownership. For example, a single app
change maps to that app family plus its GUI folder when one exists; reusable
UI changes map to reusable UI coverage plus downstream GUI coverage; launcher,
deployment, profiling, documentation, and release files map to their direct
project or GUI contracts. Unknown files and runner infrastructure still fall
back conservatively. The printed plan includes the selected suites, test-name
selectors, GUI mode, and reason for each step.

## Validation Cadence

Prefer a staged validation cadence so small follow-up edits do not repeatedly
pay the cost of broad changed-file planning:

1. While actively editing one known component, run the smallest direct
   `runLabKitTests("Suites", ...)` selection that covers the behavior being
   changed. For GUI wiring, use the affected app GUI suite with
   `IncludeGui=true`, `GuiMode="hidden"`, and `HtmlReport=false` during
   iteration.
2. After a coherent checkpoint, run `buildtool changedFast` once to verify the
   diff-based plan before broader cleanup or review.
3. Treat `buildtool changed` as the final changed-file gate for a logical
   commit or handoff. Run it once when the diff is stable before commit, PR,
   release, or direct-main handoff unless a recently completed broader gate
   fully covers the current diff.
4. After push, inspect CI for the final pushed commit. If another user-requested
   follow-up supersedes an in-progress run, continue the follow-up locally and
   inspect CI for the newest pushed commit instead of waiting for the
   superseded run.

Do not rerun `changedFast`, `changed`, or CI after every small edit when the
same focused suite can validate the changed behavior more directly. Escalate
back to a changed-file build task when the fix touches additional ownership
areas, changes validation routing, updates docs/AGENTS, or is ready for final
handoff. After a final `buildtool changed` run exposes a failure, repair with
the narrowest failed suite or test selector, then reserve another
`buildtool changed` run for the final stable diff instead of using it as the
iteration loop.

## CI Scope

Main-branch push and pull-request CI runs the public `headless` build task.
The buildfile probes the selected test count and may run deterministic
zero-based internal shards when the broad non-GUI suite is large enough.
Assumption-filtered tests remain visible as skipped or incomplete but do not
fail their shard. Actual test failures still fail the owning shard and retain
the progress, JUnit, HTML, and worker-log evidence used for diagnosis.
Feature-branch pushes do not run the same MATLAB workflow until a pull request
targets `main`, which avoids duplicate branch-push and PR runs for the same
commit. Release candidate tag pushes matching `vX.Y.Z` run the full release
gate before publishing: `headless`, `coverage`, and `gui` must pass, followed
by the `Release Test Gate` summary job. Workflow YAML calls public buildfile
tasks through `matlab-actions/run-build`; it must not
maintain test-class lists, owner shard lists, CI-only build tasks, shard
environment variables, or call the lower-level runner directly. The buildfile
task still publishes JUnit summaries and logs.
MATLAB CI checkouts fetch the current commit plus its parent so version and
changed-file guardrails have a stable `HEAD^` baseline on push and pull-request
runs.

When adding a test, place it under the correct ownership tree and give it the
right stage tag: `Unit`, `Integration`, or `GUI`. GUI tests may add secondary
tags such as `Structural`, `Workflow`, or `Gesture` to describe the contract
shape. CI membership should follow from the public `headless` task and the
runner's default non-GUI selection; ordinary test additions should not require
editing `.github/workflows/matlab-tests.yml`.

Manual, scheduled, and release-candidate workflows keep the broader report jobs
available: coverage runs separately, and GUI validation remains opt-in for
ordinary PR and main-push CI because automated GUI checks use hidden synthetic
workflows rather than full manual interaction.

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

Use `buildtool` for broad validation. The buildfile owns execution mode
decisions, including whether a large non-GUI run is worth splitting across
multiple MATLAB worker processes after a lightweight probe. In environments
where child MATLAB processes cannot acquire their own license, the same build
task stays serial. Users and CI should not maintain separate shard commands.

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
round. Do not track files under `artifacts/`; durable design decisions belong
in the relevant human doc, source comment, test, or scoped agent rule instead.

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

## Runtime V2 Contract Coverage

The workflow-first app contract is covered by layered tests, not by a single
launch-only suite:

- `AppPackageStructureGuardrailTest` discovers every `apps/**/labkit_*_app.m`
  entrypoint, requires the canonical `definition.m`,
  `definitionActions.m`, project/session lifecycle owners,
  `+userInterface/buildWorkbenchLayout.m`, and the presenter, and rejects retired
  package-root app runners and broad app buckets such as `+actions`, `+state`,
  `+ui`, `+view`, `+ops`, `+io`, and `+export`.
- `GuiLayoutUiRuntimeV2Test` owns queued dispatch, canonical state,
  presentation commits, service injection, rollback, and `Start` behavior.
  `GuiLayoutUiRuntimeV2ProjectTest` owns project persistence, migrations,
  source relinking, and read-only legacy snapshot imports.
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

## Profiling GUI Startup

For source-checkout performance work, the profiling tools live under
`tools/profiling/` and write ignored artifacts under `artifacts/profile/`.

Batch-friendly run:

```bash
matlab -batch "addpath(fullfile('tools','profiling')); profileLabKitTarget('labkit_launcher', [], 'OpenReport', false, 'WaitForGuiClose', false, 'CloseFiguresAfterRun', true, 'PrintSummary', true)"
```

Interactive run:

```matlab
addpath(fullfile("tools", "profiling"))
profileLabKitTarget("labkit_launcher")
```

The profiler writes:

- `profile_*.html`: interactive flame graph, function table, `profile-json`,
  `agent-summary-json`, and a searchable `AGENT_SUMMARY_BEGIN` block.
- `profile_*.json`: machine-readable metadata, summary text/tables, and all
  captured function rows.

No profiler rows are dropped. Read `top_project_self_time` first for editable
LabKit code, then use `top_captured_total_time` for captured workflow context
such as deliberate clicks, downstream app launches, network calls, GUI close
cost, or MATLAB callbacks. Default summary rankings exclude `profiler_tool`
rows, but the JSON `functions` array still keeps them for audit. Agent-side
filtering should use each row's `source_tag` and `tags` fields, for example
`project`, `matlab_internal`, `external`, or `profiler_tool`.

Measure one user-perceived cost at a time. Startup targets should open the
launcher or app, call `drawnow`, pause briefly, and let
`CloseFiguresAfterRun` clean up after profiling; profile explicit `close(fig)`
latency as its own target. Profile debug launches separately from normal
launches because visible trace mirroring can dominate app-owned startup cost.
For large-file workflows, use synthetic multi-file targets to compare path
registration with actual file reads before changing algorithms. Single GUI
profile runs can be noisy, so compare repeated or representative runs and keep
the HTML/JSON artifact paths in the handoff.
