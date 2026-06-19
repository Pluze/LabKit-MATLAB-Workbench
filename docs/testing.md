# Testing

Use this page to choose the smallest check that proves the change you made.

## Default Check

Run the default non-GUI build task for broad local validation:

```bash
buildtool test
```

If MATLAB is not on `PATH`:

```bash
scripts/matlab_batch.sh "buildtool test"
```

`scripts/matlab_batch.sh` only finds MATLAB, changes to the repository root,
and runs the supplied MATLAB `-batch` command. Its MATLAB log is written to
`artifacts/logs/matlab_batch/matlab.log`.

## Build Tasks

Use MATLAB build tasks for the stable official entry points:

```bash
buildtool checkStyle
buildtool test
buildtool testUnit
buildtool testIntegration
buildtool testProject
buildtool testLabkit
buildtool testLabkitGui
buildtool testApps
buildtool testAppsGui
buildtool testGuiStructural
buildtool testGuiGesture
buildtool coverage
buildtool listTasks
buildtool checkProject
buildtool packageDryRun
```

| Task | Use it for |
| --- | --- |
| `test` | Full non-GUI validation. |
| `testProject` | Architecture, docs, package boundaries, hygiene, and build-task contracts. |
| `testUnit` | Unit-tagged tests across the discovered test tree. |
| `testIntegration` | Retained task name for non-GUI contract-style tests. |
| `testLabkit` | Reusable `+labkit` non-GUI behavior. |
| `testApps` | App-owned non-GUI helpers and exports. |
| `testLabkitGui` | Reusable UI launch/layout/tool diagnostics. |
| `testAppsGui` | App-owned GUI launch, layout, and callback checks. |
| `testGuiStructural` | All noninteractive structural GUI checks. |
| `testGuiGesture` | Runtime, anchor editor, and scale-bar gesture lifecycle checks. |
| `checkStyle` | Project/style guardrails. |
| `coverage` | Manual or scheduled coverage reports. |
| `listTasks` | Current build task catalog. |
| `checkProject` | Optional local `LabKit.prj` metadata. |
| `packageDryRun` | Package-boundary inventory without exporting a toolbox. |

## Focused Selectors

For local iteration, call the runner directly:

```matlab
runLabKitTests("Suites", "apps/dic", "IncludeGui", false)
runLabKitTests("Suites", "labkit/dta", "IncludeGui", false)
runLabKitTests("Tests", "ProjectGovernanceAppTest")
runLabKitTests("Suites", "gui/apps", "IncludeGui", true)
runLabKitTests("Suites", "gui/apps/electrochem/cic", "IncludeGui", true)
runLabKitTests("Suites", "gui/labkit/launcher", "IncludeGui", true)
runLabKitTests("AffectedAppsOnly", true)
```

List matching tests without running them:

```matlab
runLabKitTests("Suites", "labkit/dta", "ListOnly", true)
```

Common selectors:

| Change area | Focused selector |
| --- | --- |
| Architecture, docs, package surface, hygiene | `buildtool testProject` |
| DTA parser, session, pulse, item schemas | `runLabKitTests("Suites", "labkit/dta")` |
| Biosignal import, filtering, ECG, segments | `runLabKitTests("Suites", "labkit/biosignal")` |
| RHS parser, header indexing, and lazy window reads | `runLabKitTests("Suites", "labkit/rhs")` |
| Reusable UI helpers without GUI launch | `runLabKitTests("Suites", "labkit/ui", "IncludeGui", false)` |
| Reusable UI layout, callbacks, diagnostics, tools | `runLabKitTests("Suites", "labkit/ui", "IncludeGui", true)` |
| Electrochem app calculations and exports | `runLabKitTests("Suites", "apps/electrochem", "IncludeGui", false)` |
| DIC app helpers | `runLabKitTests("Suites", "apps/dic", "IncludeGui", false)` |
| Image-measurement helpers | `runLabKitTests("Suites", "apps/image_measurement", "IncludeGui", false)` |
| Wearable app helpers | `runLabKitTests("Suites", "apps/wearable", "IncludeGui", false)` |
| Neurophysiology RHS app helpers | `runLabKitTests("Suites", "apps/neurophysiology", "IncludeGui", false)` |
| Project governance and scaffold-source helpers | `runLabKitTests("Suites", "apps/project", "IncludeGui", false)` |
| App GUI launch and layout | `runLabKitTests("Suites", "gui/apps", "IncludeGui", true)` |
| Launcher GUI | `runLabKitTests("Suites", "gui/labkit/launcher", "IncludeGui", true)` |
| Project governance GUI | `runLabKitTests("Suites", "gui/labkit/project", "IncludeGui", true)` |
| Generated scaffold GUI | `runLabKitTests("Suites", "gui/labkit/scaffold", "IncludeGui", true)` |
| One app GUI | `runLabKitTests("Suites", "gui/apps/<family>/<app_slug>", "IncludeGui", true)` |
| Changed app GUI layout | `runLabKitTests("AffectedAppsOnly", true)` |

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
test name. It does not use a generated registry.

App GUI tests live at:

```text
tests/cases/gui/apps/<family>/<app_slug>/
```

Use that folder as the local selector when a change affects one app. The
`AffectedAppsOnly` selector inspects changed files under `apps/` and
`tests/cases/gui/apps/` relative to `HEAD`, maps them to matching
per-app GUI test folders, and runs only those GUI tests. Shared UI,
launcher, runner, or broad documentation changes should still use the explicit
suite or build task that matches the shared surface.

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
artifacts/logs/matlab_batch/
```

`runLabKitTests` sets `LABKIT_ARTIFACTS` while tests run, so apps launched in
debug mode write their trace files into the same artifact root:

```text
artifacts/debug/<RunName>/<AppName>/
```

Coverage is report-only and not part of the default local check.
