# Testing

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

## Build Tasks

Use MATLAB build tasks for the stable official entry points:

```bash
buildtool changed
buildtool changedFast
buildtool headless
buildtool gui
buildtool coverage
buildtool listTasks
```

| Task | Use it for |
| --- | --- |
| `changedFast` | Tight local iteration from the current diff; substitutes representative GUI coverage for expensive broad GUI scopes. |
| `changed` | Conservative pre-handoff validation from the current diff. |
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
| Full broad non-GUI validation | `buildtool headless` |
| Full automated GUI validation | `buildtool gui` |
| Coverage report | `buildtool coverage` |

`changedFast` and `changed` require a git checkout. In exported source trees,
packaged copies, or environments without git state, use `headless` or an
explicit `runLabKitTests` suite selection instead.

The changed-file planner routes by source ownership. For example, a single app
change maps to that app family plus its GUI folder when one exists; reusable
UI changes map to reusable UI coverage plus downstream GUI coverage; docs,
AGENTS, tools, and runner support files map to project guardrails unless their
own tests require broader coverage. The printed plan includes the selected
suites, test-name selectors, GUI mode, and reason for each step.

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
3. Before commit, PR, or direct-main handoff, run `buildtool changed` unless a
   recently completed broader gate fully covers the current diff.
4. After push, inspect CI for the final pushed commit. If another user-requested
   follow-up supersedes an in-progress run, continue the follow-up locally and
   inspect CI for the newest pushed commit instead of waiting for the
   superseded run.

Do not rerun `changedFast`, `changed`, or CI after every small edit when the
same focused suite can validate the changed behavior more directly. Escalate
back to a changed-file build task when the fix touches additional ownership
areas, changes validation routing, updates docs/AGENTS, or is ready for final
handoff.

## CI Scope

Main-branch push and pull-request CI runs the public `headless` build task.
The buildfile probes the selected test count and may run deterministic
zero-based internal shards when the broad non-GUI suite is large enough.
Feature-branch pushes do not run the same MATLAB workflow until a pull request
targets `main`, which avoids duplicate branch-push and PR runs for the same
commit. Release tag pushes do not rerun the same SHA, which avoids duplicate
CI after a commit has already run on `main` or in a PR. Workflow YAML calls
public buildfile tasks through `matlab-actions/run-build`; it must not
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

Manual and scheduled workflows keep the broader report jobs available:
coverage runs separately, and GUI validation remains opt-in because automated
GUI checks use hidden synthetic workflows rather than full manual interaction.

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
patterns justify a grouped API.

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

App GUI layout tests should express user-facing and app-facing contracts:
expected command buttons, dropdown choices, tabs, table columns, axes, callback
wiring, and debug trace behavior. They should not assert raw MATLAB component
class counts, because those counts are framework implementation details.
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

## App Runtime Migration Coverage

The workflow-first app migration is covered by layered tests, not by a single
launch-only suite:

- `AppPackageStructureGuardrailTest` discovers every `apps/**/labkit_*_app.m`
  entrypoint, requires the canonical `definition.m`,
  `definitionActions.m`, `+appLifecycle/createInitialState.m`,
  `+userInterface/buildWorkbenchLayout.m`, and
  `+userInterface/updateWorkbenchFromState.m` files, and rejects retired
  package-root app runners and broad app buckets such as `+actions`, `+state`,
  `+ui`, `+view`, `+ops`, `+io`, and `+export`.
- `GuiLayoutUiAppRuntimeTest` owns the framework runtime contract: startup and
  hydration actions update state, render prepared state, record phase timings,
  expose service dispatch, and report action failures through debug context.
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
