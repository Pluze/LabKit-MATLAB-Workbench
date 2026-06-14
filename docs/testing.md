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
and runs the supplied MATLAB `-batch` command.

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
| `testAppsGui` | App-owned GUI layout plus app launch smoke checks. |
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
runLabKitTests("Suites", "apps/smoke", "IncludeGui", true)
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
| Reusable UI helpers without GUI launch | `runLabKitTests("Suites", "labkit/ui", "IncludeGui", false)` |
| Reusable UI layout, callbacks, diagnostics, tools | `runLabKitTests("Suites", "labkit/ui", "IncludeGui", true)` |
| Electrochem app calculations and exports | `runLabKitTests("Suites", "apps/electrochem", "IncludeGui", false)` |
| DIC app helpers | `runLabKitTests("Suites", "apps/dic", "IncludeGui", false)` |
| Image-measurement helpers | `runLabKitTests("Suites", "apps/image_measurement", "IncludeGui", false)` |
| Wearable app helpers | `runLabKitTests("Suites", "apps/wearable", "IncludeGui", false)` |
| Project governance and scaffold-source helpers | `runLabKitTests("Suites", "apps/project", "IncludeGui", false)` |
| App launch smoke | `runLabKitTests("Suites", "apps/smoke", "IncludeGui", true)` |

## Test Layout

```text
tests/unit/        pure library and app-owned helper behavior
tests/contract/    long-lived project, package, docs, and hygiene contracts
tests/smoke/       app discovery, launch, debug, and trace checks
tests/gui/         noninteractive GUI layout and gesture checks
tests/fixtures/    synthetic fixtures
tests/helpers/     assertions and focused helper functions
tests/support/     runner setup, artifact paths, discovery, and GUI support
```

The runner discovers tests by directory and then filters by suite, tag, and
test name. It does not use a generated registry.

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

Named DTA fixtures currently live under `tests/fixtures/dta/`:

```text
chrono_chronopot_current_pulse_0p2ms.DTA
chrono_chronopot_current_pulse_1ms.DTA
chrono_chronopot_current_pt_0p65ms.DTA
chrono_chronoamp_voltage_pulse_0p2ms.DTA
chrono_chronoamp_voltage_pulse_1ms.DTA
cv_cyclic_voltammetry_pt_reference.DTA
cv_cyclic_voltammetry_pt_replicate.DTA
eis_potentiostatic_zcurve.DTA
```

Tests may depend on these names, but should not fail only because additional
DTA fixtures are added.

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
artifacts/gui/<RunName>/
artifacts/logs/<RunName>/
```

Coverage is report-only and not part of the default local check.
