# Testing

Use this page to choose the smallest supported build task that proves the
change you made.

## Default Check

Run the default non-GUI build task for broad local validation:

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
| `changed` | Fast local validation selected from changed and untracked files. |
| `changedFast` | Faster changed-file validation for local iteration; uses representative GUI smoke coverage when broad app GUI coverage would otherwise run. |
| `headless` | Full non-GUI validation. |
| `gui` | Noninteractive GUI launch, layout, callback, workflow, and gesture checks. GUI windows are hidden by default. |

Report and discovery tasks:

| Task | Use it for |
| --- | --- |
| `coverage` | Manual or scheduled coverage reports. |
| `listTasks` | Print the current build task catalog. |

## Choosing A Task

Use build tasks directly for local iteration. The `changed` task is the
default focused choice before committing: it inspects changed and untracked
files and runs a conservative serial validation plan inside one MATLAB
process. It requires git and a git checkout. Use `headless` in exported
source trees, packaged copies, or environments without git state.
Use `changedFast` during tight edit cycles when a shared UI or broad app-GUI
change would otherwise run the full downstream app GUI suite. It keeps
reusable UI coverage and representative downstream app smoke checks, but it is
not a substitute for the conservative `changed` task before handoff.
Fast validation plans may combine suite routing with test-name selectors for
expensive GUI smoke coverage. Keep those selectors small and contract-oriented:
choose tests that cover startup, declarative shell behavior, debug trace
plumbing, and one or two representative downstream app layouts.

Common choices:

| Change area | Build task |
| --- | --- |
| Changed source, tests, or docs before commit | `buildtool changed` |
| Local iteration after a broad UI or GUI-adjacent edit | `buildtool changedFast` |
| Full broad non-GUI validation | `buildtool headless` |
| Any GUI launch, layout, callback, or gesture change | `buildtool gui` |
| Architecture, docs, package surface, hygiene | `buildtool headless` |

## CI Scope

Main-branch push and pull-request CI runs repository hygiene plus parallel
non-GUI MATLAB shards for unit and integration coverage. Feature-branch pushes
do not run the same MATLAB shard workflow until a pull request targets `main`,
which avoids duplicate branch-push and PR runs for the same commit. Release tag
pushes do not rerun the same SHA, which avoids duplicate CI after a commit has
already run on `main` or in a PR. The shards split unit tests by ownership area
and split integration guardrails into app-boundary and project/package groups. Workflow
YAML calls buildfile CI shard tasks through `matlab-actions/run-build`; it must
not maintain test-class lists or call the lower-level runner directly. The
buildfile tasks use suite and tag filters, skip HTML reports for speed, and
still publish JUnit summaries and logs.
MATLAB CI checkouts fetch the current commit plus its parent so version and
changed-file guardrails have a stable `HEAD^` baseline on push and pull-request
runs.

When adding a test, place it under the correct ownership tree and give it the
right stage tag: `Unit`, `Integration`, or `GUI`. GUI tests may add secondary
tags such as `Structural`, `Workflow`, or `Gesture` to describe the contract
shape. CI shard membership should follow from `tests/cases` layout plus
`TestTags`; ordinary test additions should not require editing
`.github/workflows/matlab-tests.yml`.

Manual and scheduled workflows keep the broader report jobs available:
coverage runs separately, and GUI validation remains opt-in because automated
GUI checks use hidden synthetic workflows rather than full manual interaction.

## Test Layout

```text
tests/cases/unit/              pure library and app-owned helper behavior
tests/cases/contract/apps/     long-lived app boundary and app workflow guardrails
tests/cases/contract/project/  project contracts grouped by topic
tests/cases/gui/apps/          app GUI launch, layout, callback, and workflow checks
tests/cases/gui/labkit/        launcher and reusable UI GUI checks
tests/cases/gui/gesture/       focused runtime interaction lifecycle checks
tests/shared/                  small test-facing assertions, fixture builders, GUI probes, and lookup helpers
tests/runner/                  runner setup, artifact paths, trace plumbing, and artifact writers
```

Project contract tests use a third directory level for the guarded contract,
for example `build`, `ci`, `docs`, `hygiene`, `packages`, `runtime`, or
`release`.

`tests/shared/` intentionally keeps ordinary MATLAB helper functions as
one-function files because those helpers are called directly by tests. Prefer a
plain function file there over a larger registry object unless repeated call
patterns justify a grouped API.

Build tasks are the supported human and CI entry points. The lower-level runner
is an implementation detail used by the buildfile.

App GUI tests live at:

```text
tests/cases/gui/apps/<family>/<app_slug>/
```

When a change affects one app, `buildtool changed` maps the touched app
folder to the matching GUI test folder when one exists. Shared UI, launcher,
runner, or broad documentation changes map to broader build-task selections.

## GUI Validation

Automated GUI tests check:

- app launch
- layout contracts
- callback wiring
- debug trace plumbing
- reusable tool lifecycle

App GUI layout tests should express user-facing and app-facing contracts:
expected command buttons, dropdown choices, tabs, table columns, axes, callback
wiring, and debug trace behavior. They should not assert raw MATLAB component
class counts, because those counts are framework implementation details.
Reusable LabKit GUI tests may assert low-level control shape only when that
shape is the framework behavior under test.
Avoid duplicating expensive figure launches for the same contract. If an app
already has a dedicated layout test, entry-point smoke coverage should not
launch it again. For apps without a dedicated layout test, one debug launch can
cover startup, named figure creation, path hygiene, and visible trace plumbing.

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
artifacts/debug/<RunName>/<AppName>/
```

Coverage is report-only and not part of the default local check.
