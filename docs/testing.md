# Testing

Use this document to choose automated checks for behavior-preserving changes.

Core rule:

```text
validated behavior stays stable
```

Do not claim behavior is preserved unless tests or fixtures support that claim.

## Test Commands

Default non-GUI suite:

```bash
scripts/run_matlab_tests.sh
```

On Windows PowerShell:

```powershell
.\scripts\run_matlab_tests.ps1
```

If local execution policy blocks direct `.ps1` execution, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_matlab_tests.ps1
```

Both wrappers call `tests/run_all_tests.m` and accept the same `--suite`, `--test`, and `--gui` options. Set `MATLAB_CMD` when MATLAB is not on `PATH`, and set `MATLAB_TEST_LOG` to override the default `matlab_test.log` location.

## Validation Levels

| Level | Where | Purpose |
| --- | --- | --- |
| Default non-GUI suite | CI and local shell | Project guardrails, `labkit` facade behavior, non-GUI reusable UI checks, and pure app analysis/export helpers. |
| Focused GUI suite runs | Local MATLAB with graphics support | Noninteractive launch, layout, and callback wiring checks for selected app families. |
| Manual GUI validation | User-run app windows | Interactive file selection, drawing, visual inspection, and full workflow feel. |

CI runs the default non-GUI suite through `.github/workflows/matlab-tests.yml`. It should not be described as full GUI workflow validation.

## Focused Suites

```bash
scripts/run_matlab_tests.sh --suite project
scripts/run_matlab_tests.sh --suite labkit/dta
scripts/run_matlab_tests.sh --suite labkit/dta --suite apps/electrochem
scripts/run_matlab_tests.sh --suite labkit/biosignal
scripts/run_matlab_tests.sh --suite labkit/biosignal --suite apps/wearable --gui
scripts/run_matlab_tests.sh --suite labkit/ui --gui
scripts/run_matlab_tests.sh --suite labkit/ui --suite apps --gui
scripts/run_matlab_tests.sh --suite apps/electrochem
scripts/run_matlab_tests.sh --suite apps/dic --gui
scripts/run_matlab_tests.sh --suite apps/image_measurement --gui
scripts/run_matlab_tests.sh --suite apps/wearable --gui
scripts/run_matlab_tests.sh --suite gui
scripts/run_matlab_tests.sh --test test_gui_layout_ui_anchor_curve_editor
scripts/run_matlab_tests.sh --test test_package_public_surface
```

Use the same option names from Windows PowerShell:

```powershell
.\scripts\run_matlab_tests.ps1 --suite labkit/dta
.\scripts\run_matlab_tests.ps1 --suite apps/electrochem
.\scripts\run_matlab_tests.ps1 --test test_gui_layout_ui_anchor_curve_editor
```

Suite targets mirror source ownership:

| Suite | Use it for |
| --- | --- |
| `project` | Startup, architecture, package surface, and sample-data hygiene guardrails. |
| `labkit/dta` | DTA parser, facade, session, pulse, and item-schema checks. |
| `labkit/biosignal` | Biosignal import, channel extraction, processing, ECG peaks, segments, SNR, and group comparison. |
| `labkit/ui` | Reusable UI helpers; add `--gui` for layout and callback wiring checks. |
| `apps/electrochem` | Electrochem app-owned calculations, exports, and layout contracts. |
| `apps/dic` | DIC app layout contracts; usually run with `--gui`. |
| `apps/image_measurement` | Image-measurement calculations, exports, and layout contracts. |
| `apps/wearable` | Wearable app layout contracts; usually run with `--gui`. |
| `apps/smoke` | Cross-app launch smoke checks. |
| `gui` | All noninteractive GUI checks across every target. |

For reusable library changes, add downstream app suites when the app-facing contract could be affected. For example, pair `labkit/dta` with `apps/electrochem`, `labkit/biosignal` with `apps/wearable`, and `labkit/ui` with `apps` plus `--gui` when layout or callback behavior changed.

## Suite Layout

Tests live under:

```text
tests/suites/project
tests/suites/labkit/dta
tests/suites/labkit/biosignal
tests/suites/labkit/ui
tests/suites/apps/electrochem
tests/suites/apps/dic
tests/suites/apps/image_measurement
tests/suites/apps/wearable
tests/suites/apps/smoke
```

The stable entry point is `tests/run_all_tests.m`. It discovers `test_*.m` files directly from `tests/suites/<target>/`, so adding a focused test normally only requires placing it in the appropriate target folder.

Shared setup, structural GUI assertions, and focused support routines live under `tests/helpers/`. Keep helpers limited to setup and assertions; app-specific formulas, result schemas, export formats, and expected scientific values should remain in focused suite tests.

Architecture guardrails are split by concern under `tests/suites/project/`: public package surface, reusable package dependency boundaries, app entrypoint boundaries, and app-owned workflow boundaries. These guardrails may require workflow code to remain under the owning app tree, but they should not require GUI-free helpers to stay in the public app entry-point file. App-private helpers are checked by boundary rules rather than exact file-list assertions.

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
