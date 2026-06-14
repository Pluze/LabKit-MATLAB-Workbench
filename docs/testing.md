# Testing

Use this document to choose automated checks for behavior-preserving changes.

Core rule:

```text
validated behavior stays stable
```

Do not claim behavior is preserved unless tests or fixtures support that claim.

## Test Commands

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

- `buildtool test` is the full non-GUI entry point.
- `buildtool checkStyle` runs official project/style guardrails.
- `buildtool testLabkit` and `buildtool testApps` run discovered non-GUI tests
  below the reusable `labkit` and app-owned test trees.
- `buildtool testLabkitGui` and `buildtool testAppsGui` run discovered GUI
  tests below the same ownership trees.
- `buildtool coverage` generates official JUnit, HTML test result, Cobertura,
  and HTML coverage artifacts. Coverage is report-only and runs in manual or
  scheduled CI, not as a default PR quality gate.
- `buildtool listTasks` prints the build task catalog from `buildfile.m`.
- Official runner artifacts are namespaced by build task run name under
  `artifacts/test-results/<RunName>/`, `artifacts/coverage/<RunName>/`,
  `artifacts/gui/<RunName>/`, and `artifacts/logs/<RunName>/` so combined task
  invocations do not overwrite each other. GitHub Actions writes MATLAB logs
  to the matching run-name log directory, such as
  `artifacts/logs/testUnit/matlab.log`.
- `buildtool testGuiGesture` runs focused noninteractive gesture coverage for
  runtime, anchor editor, and scale-bar interaction lifecycle checks.
- `buildtool checkProject` verifies optional local `LabKit.prj` path and
  startup metadata when a local project file exists. A fresh clone without
  `LabKit.prj` should still pass because MATLAB Project metadata is local IDE
  state.
- `buildtool packageDryRun` writes a package-boundary inventory under
  `artifacts/package/` without exporting a toolbox.

Default non-GUI build task:

```bash
buildtool test
```

If MATLAB is not on `PATH`, use the thin MATLAB locator:

```bash
scripts/matlab_batch.sh "buildtool test"
```

`scripts/matlab_batch.sh` only locates MATLAB, changes to the repository root,
and runs the supplied MATLAB `-batch` command. It does not parse test task names
or maintain a separate test interface. Set `MATLAB_CMD` when MATLAB is not on
`PATH`. Run `buildtool listTasks` to inspect the current task catalog.

Targeted debugging uses the same runner selectors used by the build tasks:

```matlab
runLabKitTests("Suites", "apps/dic", "IncludeGui", false)
runLabKitTests("Suites", "labkit/dta", "IncludeGui", false)
runLabKitTests("Tests", "AppHookHelpersTest")
runLabKitTests("Tags", "Gesture", "IncludeGui", true)
```

To inspect test selection without executing tests or writing artifacts, add
list-only mode:

```matlab
runLabKitTests("Suites", "labkit/dta", "ListOnly", true)
```

Use direct `runLabKitTests(...)` calls for local diagnosis and source-aligned
iteration. Build tasks remain the stable official entry points for CI, PR
validation, and broad local validation commands.

## Validation Levels

| Level | Where | Purpose |
| --- | --- | --- |
| Default non-GUI build task | CI and local shell | Project guardrails, `labkit` facade behavior, non-GUI reusable UI checks, and pure app analysis/export helpers. |
| Focused GUI build tasks | Local MATLAB with graphics support | Noninteractive launch, layout, and callback wiring checks. |
| Manual GUI validation | User-run app windows | Interactive file selection, drawing, visual inspection, and full workflow feel. |

CI runs repository-hygiene, quality, unit, and integration jobs on pushes and
pull requests for every branch through `.github/workflows/matlab-tests.yml`.
Manual and scheduled CI runs also execute coverage, GUI structural, and
non-blocking GUI gesture jobs. Coverage is intentionally outside the default PR
gate to keep PR feedback focused and avoid duplicate test execution. Do not
describe CI as full interactive GUI workflow validation.

Each MATLAB CI job writes a GitHub Step Summary with JUnit totals, artifact
locations, the slowest test cases, and failed-test details when available.
Failure summaries also include a compact MATLAB log tail so common failures can
be inspected from the Actions page. MATLAB HTML reports remain uploaded as
artifacts; GitHub Actions does not render artifact HTML inline, so interactive
HTML browsing still requires downloading the artifact or adding a separate
publishing target.

The repository-hygiene job owns repository-level checks that are cheaper and
safer outside MATLAB, including the rule that `LabKit.prj` and
`resources/project/` must stay untracked local IDE metadata. MATLAB build tasks
should not shell out to git for this repository-state check. CI jobs also use
explicit job timeouts so a MATLAB process hang fails quickly instead of
consuming the GitHub Actions six-hour default.

## Targeted Selection

The runner discovers tests by directory and filters by suite, tag, and test
name. Use broad build tasks for official validation and runner selectors for
focused iteration:

| Change area | Focused selector |
| --- | --- |
| Startup, architecture, package surface, hygiene | `buildtool testProject` |
| DTA parser, facade, session, pulse, item schemas | `runLabKitTests("Suites", "labkit/dta")` |
| Biosignal import, processing, ECG, segments | `runLabKitTests("Suites", "labkit/biosignal")` |
| Reusable non-GUI UI helpers | `runLabKitTests("Suites", "labkit/ui", "IncludeGui", false)` |
| Reusable UI layout, callbacks, diagnostics, tools | `runLabKitTests("Suites", "labkit/ui", "IncludeGui", true)` |
| Electrochem app calculations and exports | `runLabKitTests("Suites", "apps/electrochem", "IncludeGui", false)` |
| DIC app state, IO/export, view, image-processing helpers | `runLabKitTests("Suites", "apps/dic", "IncludeGui", false)` |
| Image-measurement calculations and exports | `runLabKitTests("Suites", "apps/image_measurement", "IncludeGui", false)` |
| Wearable app import, plotting request, measurement helpers | `runLabKitTests("Suites", "apps/wearable", "IncludeGui", false)` |
| Template app helper behavior | `runLabKitTests("Suites", "apps/templates", "IncludeGui", false)` |
| App-family GUI layout contracts | `runLabKitTests("Suites", "apps/<family>", "IncludeGui", true)` |
| Cross-app launch smoke checks | `runLabKitTests("Suites", "apps/smoke", "IncludeGui", true)` |
| All structural GUI checks | `buildtool testGuiStructural` |
| Runtime, anchor-editor, and scale-bar gesture checks | `buildtool testGuiGesture` |

For reusable library changes, add downstream app selectors when the app-facing
contract could be affected. For example, pair
`runLabKitTests("Suites", "labkit/dta")` with
`runLabKitTests("Suites", "apps/electrochem", "IncludeGui", false)`,
`runLabKitTests("Suites", "labkit/biosignal")` with
`runLabKitTests("Suites", "apps/wearable", "IncludeGui", false)`, and
`runLabKitTests("Suites", "labkit/ui", "IncludeGui", true)` with
`buildtool testAppsGui` when layout or callback behavior changed.

UI framework changes should cover the affected layer rather than only the changed file:

| UI layer | Automated coverage |
| --- | --- |
| Public surface | `testProject` checks the layered `labkit.ui.app/spec/view/tool/diag` API and private implementation packages. |
| Shell/layout | `testLabkitGui` and affected app-family GUI selectors. |
| Runtime/tools | `testLabkitGui` runtime, anchor-editor, and scale-bar tool tests. |
| Diagnostics | `testLabkitGui` debug instrumentation tests plus `runLabKitTests("Suites", "apps/smoke", "IncludeGui", true)`. |
| App migration | Affected app-family GUI selector plus `testProject` entrypoint/boundary guardrails. |
| Gesture tools | `buildtool testGuiGesture` for runtime, anchor-editor, and scale-bar lifecycle checks. |

## MATLAB Code Analyzer Suppression Policy

- Suppression directives such as `%#ok<...>` are prohibited in this repository.
- Suppression comments may not be used to bypass `checkcode` findings (for example
  `NASGU`, `AGROW`, `ISMAT`, and related diagnostics).
- Resolve `checkcode` findings with behavior-preserving code changes (logic,
  ownership assumptions, initialization, or API usage), not with suppression.
- The prohibition applies to both production and test `.m` files.
- If an issue is intentionally deferred, route it through a dedicated task or
  backlog item instead of adding suppression.

## Suite Layout

Tests live under:

```text
tests/unit/
tests/integration/
tests/gui/
```

Official `matlab.unittest` tests live under `tests/unit` and
`tests/integration`. Noninteractive GUI structural and gesture tests live under
`tests/gui` and use `matlab.uitest.TestCase` when they launch app windows or
interact with controls.

Shared setup, structural GUI assertions, and focused support routines live under `tests/helpers/`. Keep helpers limited to setup and assertions; app-specific formulas, result schemas, export formats, and expected scientific values should remain in focused suite tests.

Architecture guardrails are split by concern under `tests/integration/project/`: public package surface, reusable package dependency boundaries, app entrypoint boundaries, and app-owned workflow boundaries. These guardrails may require workflow code to remain under the owning app tree, but they should not require GUI-free helpers to stay in the public app entry-point file. App-owned packages are checked by boundary rules rather than exact file-list assertions.

Project debt guardrails also prevent app UI runners from keeping local helper
copies that shadow same-named functions already extracted into the app-owned
`+ops`, `+view`, `+export`, `+io`, or `+state` packages. Tests should prove the
package helper behavior directly, and GUI paths should call those helpers
instead of private runner duplicates.

Compatibility bridge behavior should be isolated in named compatibility tests.
For example, DTA legacy bridge fields such as `t`, `Vf`, `Im`, `Freq`, and
`Zreal` are covered by `DtaCompatibilityBridgeTest`; ordinary DTA and app
tests should use canonical unit-explicit fields and direct app-owned package
functions.

Unit app tests should not read app source text to prove behavior. Source-string
scans belong in project guardrails; app behavior tests should call package
functions directly or use GUI structural tests when the behavior is layout or
callback wiring.

When a suite file becomes broad enough that unrelated changes must read hundreds of lines, add a narrower `test_*.m` file in the same suite instead of appending more coverage to the broad file.

## GUI Validation

Automated GUI checks are structural assertion tests. They launch app windows, inspect component contracts, verify callback wiring, and check reusable layout/helper handles.

They do not validate:

- visual pixel quality
- actual drag/draw gestures
- interactive file selection
- full workflow feel

Interactive GUI workflows are validated manually in MATLAB app windows. Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Numerical Tolerance

Default direct numerical tolerance:

```matlab
abs(oldValue - newValue) < 1e-9
```

Use looser tolerances only when justified by interpolation, plotting-only alignment, or format conversion. Document any looser tolerance in the test.

Use `tests/helpers/assertClose.m` for repeated exact or tolerance-based numeric checks. Use `tests/helpers/dtaFixtureDir.m`, `tests/helpers/dtaFixturePath.m`, and focused fixture builders such as `tests/helpers/makeChronoFixtureItem.m` when multiple tests need the same DTA fixture setup.

## Fixture Expectations

Named DTA fixtures live under `tests/fixtures/dta/`:

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

Tests may require these named fixtures. They should not fail only because additional DTA files are added to `tests/fixtures/dta/`.

Parser regressions should use synthetic fixtures that preserve structure without carrying identifying sample metadata. Tracked source, tests, scripts, and docs should not contain local absolute paths, current-user home paths, or timestamp-shaped sample file tokens.

## Coverage Areas

Parser coverage includes chrono T/Vf/Im/Pt interpretation, chrono step metadata, EIS ZCURVE extraction, CV/CT scan-rate conversion, curve discovery, numeric parsing, expected-kind status, missing-file status, and batch/folder loading reports.

Pulse coverage includes metadata-first, metadata-only, current-only modes, cathodic/anodic/gap timing, compatibility flat fields, and normalized nested fields.

App analysis coverage includes VT resistance, CIC, CSC, EIS axis/export behavior, chrono overlay alignment/export, CSV headers, column order, failed-row formatting, and quoted text behavior.

Boundary coverage checks that public app files stay on the supported facades, reusable packages remain GUI/app-free where required, app-specific workflow code does not return to public reusable packages, and sample-data hygiene is preserved.
