# Testing

Use this document to choose automated checks for behavior-preserving changes.

Core rule:

```text
validated behavior stays stable
```

Do not claim behavior is preserved unless tests or fixtures support that claim.

## Test Commands

Use the MATLAB build tasks for the common official test entry points:

```bash
buildtool checkStyle
buildtool test
buildtool testUnit
buildtool testIntegration
buildtool testProject
buildtool testLabkitDta
buildtool testLabkitBiosignal
buildtool testLabkitUi
buildtool testLabkitUiGui
buildtool testAppsElectrochem
buildtool testAppsElectrochemGui
buildtool testAppsDicGui
buildtool testAppsImageMeasurement
buildtool testAppsImageMeasurementGui
buildtool testAppsWearableGui
buildtool testAppsGui
buildtool testAppsSmokeGui
buildtool testGuiStructural
buildtool testGuiGesture
buildtool coverage
buildtool checkProject
buildtool packageDryRun
```

- `buildtool test` is the full non-GUI entry point.
- `buildtool checkStyle` runs official project/style guardrails.
- `buildtool coverage` generates official JUnit, HTML test result, Cobertura,
  and HTML coverage artifacts. Coverage is report-only and runs in manual or
  scheduled CI, not as a default PR quality gate.
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

On Windows PowerShell:

```powershell
.\scripts\run_matlab_tests.ps1 test
```

If local execution policy blocks direct `.ps1` execution, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1 test
```

Both wrappers accept build task names only and call `buildtool`. Selector flags
such as `--suite`, `--test`, and `--gui` are not supported. Set `MATLAB_CMD`
when MATLAB is not on `PATH`, set `MATLAB_FLAGS` for MATLAB startup flags, and
set `MATLAB_TEST_LOG` to override the default `matlab_test.log` location.

Advanced targeted debugging can call the internal runner directly:

```matlab
runLabKitTests("Tests", "AppHookHelpersTest", "FailIfNoTests", true)
```

To inspect test selection without executing tests or writing artifacts, use
the internal list-only mode:

```matlab
runLabKitTests("Suites", "labkit/dta", "ListOnly", true)
```

Use direct `runLabKitTests(...)` calls only for local diagnosis. Build tasks
remain the official entry points for CI, PR validation, and local validation
commands.

## Validation Levels

| Level | Where | Purpose |
| --- | --- | --- |
| Default non-GUI build task | CI and local shell | Project guardrails, `labkit` facade behavior, non-GUI reusable UI checks, and pure app analysis/export helpers. |
| Focused GUI build tasks | Local MATLAB with graphics support | Noninteractive launch, layout, and callback wiring checks for selected app families. |
| Manual GUI validation | User-run app windows | Interactive file selection, drawing, visual inspection, and full workflow feel. |

CI runs shell-wrapper, quality, unit, and integration jobs on pushes and pull
requests for every branch through `.github/workflows/matlab-tests.yml`. Manual and
scheduled CI runs also execute coverage, GUI structural, and non-blocking GUI
gesture jobs. Coverage is intentionally outside the default PR gate to keep PR
feedback focused and avoid duplicate test execution. Do not describe CI as full
interactive GUI workflow validation.

The shell-wrapper job owns repository-level checks that are cheaper and safer
outside MATLAB, including the rule that `LabKit.prj` and `resources/project/`
must stay untracked local IDE metadata. MATLAB build tasks should not shell out
to git for this repository-state check. CI jobs also use explicit job timeouts
so a MATLAB process hang fails quickly instead of consuming the GitHub Actions
six-hour default.

## Focused Build Tasks

```bash
buildtool testProject
buildtool testLabkitDta
buildtool testLabkitDta testAppsElectrochem
buildtool testLabkitBiosignal
buildtool testLabkitBiosignal testAppsWearableGui
buildtool testLabkitUiGui
buildtool testLabkitUiGui testAppsGui
buildtool testAppsElectrochem
buildtool testAppsDicGui
buildtool testAppsImageMeasurementGui
buildtool testAppsWearableGui
buildtool testAppsGui
buildtool testAppsSmokeGui
buildtool testGuiStructural
buildtool testGuiGesture
```

Use task names from Windows PowerShell:

```powershell
.\scripts\run_matlab_tests.ps1 testLabkitDta
.\scripts\run_matlab_tests.ps1 testAppsElectrochem
.\scripts\run_matlab_tests.ps1 testGuiStructural
```

Focused build tasks mirror source ownership:

| Task | Use it for |
| --- | --- |
| `testProject` | Startup, architecture, package surface, repository hygiene, and sample-data hygiene guardrails. |
| `testLabkitDta` | DTA parser, facade, session, pulse, and item-schema checks. |
| `testLabkitBiosignal` | Biosignal import, channel extraction, processing, ECG peaks, segments, SNR, and group comparison. |
| `testLabkitUi` | Reusable UI helpers that do not require app windows. |
| `testLabkitUiGui` | Reusable UI layout, callback wiring, diagnostics, and tool GUI checks. |
| `testAppsElectrochem` | Electrochem app-owned calculations and exports. |
| `testAppsElectrochemGui` | Electrochem app layout contracts. |
| `testAppsDicGui` | DIC app layout contracts. |
| `testAppsImageMeasurement` | Image-measurement calculations and exports. |
| `testAppsImageMeasurementGui` | Image-measurement layout contracts. |
| `testAppsWearableGui` | Wearable app layout contracts. |
| `testAppsGui` | All app-family noninteractive GUI checks. |
| `testAppsSmokeGui` | Cross-app launch smoke checks. |
| `testGuiStructural` | All structural GUI checks. |
| `testGuiGesture` | Runtime, anchor-editor, and scale-bar gesture checks. |

For reusable library changes, add downstream app tasks when the app-facing
contract could be affected. For example, pair `testLabkitDta` with
`testAppsElectrochem`, `testLabkitBiosignal` with `testAppsWearableGui`, and
`testLabkitUiGui` with `testAppsGui` when layout or callback behavior changed.

UI framework changes should cover the affected layer rather than only the changed file:

| UI layer | Automated coverage |
| --- | --- |
| Public surface | `testProject` checks the layered `labkit.ui.app/view/tool/diag` API and private implementation packages. |
| Shell/layout | `testLabkitUiGui` and affected app-family GUI tasks. |
| Runtime/tools | `testLabkitUiGui` runtime, anchor-editor, and scale-bar tool tests. |
| Diagnostics | `testLabkitUiGui` debug instrumentation tests plus `testAppsSmokeGui` debug launch trace checks. |
| App migration | Affected app-family GUI task plus `testProject` entrypoint/boundary guardrails. |
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
