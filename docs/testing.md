# Testing

Use this page to choose the smallest check that proves the change you made.

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
buildtool headless
buildtool gui
buildtool coverage
buildtool listTasks
```

| Task | Use it for |
| --- | --- |
| `changed` | Fast local validation selected from changed and untracked files. |
| `headless` | Full non-GUI validation. |
| `gui` | Noninteractive GUI launch, layout, callback, and gesture checks. |

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

Common choices:

| Change area | Build task |
| --- | --- |
| Changed source, tests, or docs before commit | `buildtool changed` |
| Full broad non-GUI validation | `buildtool headless` |
| Any GUI launch, layout, callback, or gesture change | `buildtool gui` |
| Architecture, docs, package surface, hygiene | `buildtool headless` |

## Test Layout

```text
tests/cases/unit/              pure library and app-owned helper behavior
tests/cases/contract/          long-lived project, package, docs, and hygiene contracts
tests/cases/gui/apps/          app GUI launch, layout, and callback checks
tests/cases/gui/labkit/        launcher, governance, scaffold, and reusable UI GUI checks
tests/cases/gui/gesture/       focused runtime interaction lifecycle checks
tests/shared/                  small test-facing assertions, fixture builders, GUI probes, and lookup helpers
tests/runner/                  runner setup, artifact paths, trace plumbing, and artifact writers
```

`tests/shared/` intentionally keeps ordinary MATLAB helper functions as
one-function files because those helpers are called directly by tests. Prefer a
plain function file there over a larger registry object unless repeated call
patterns justify a grouped API.

The runner discovers tests by directory and then filters by suite, tag, and
test name. It does not use a generated registry. Build tasks are the supported
human and CI entry points; the lower-level runner exists so the buildfile can
compose those tasks without duplicating discovery logic.

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
