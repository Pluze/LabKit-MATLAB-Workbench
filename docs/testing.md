# Testing

Use this document to choose automated checks for behavior-preserving changes.

Core rule:

```text
validated behavior stays stable
```

Do not claim behavior is preserved unless tests or fixtures support that claim.

## Test Commands

Default pure-function suite:

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

Both wrappers are thin launchers around `tests/run_all_tests.m`. They accept the same `--suite`, `--test`, and `--gui` options. Set `MATLAB_CMD` when MATLAB is not on `PATH`, and set `MATLAB_TEST_LOG` to override the default `matlab_test.log` location.

The same non-GUI suite runs in GitHub Actions on pushes and pull requests to `main` through `.github/workflows/matlab-tests.yml`. The README badge points to this workflow. The CI workflow uses MathWorks MATLAB Actions and calls `run_all_tests(false)`, so it covers project guardrails, `labkit` library tests, and non-GUI app checks without opening GUI windows.

Validation levels:

| Level | Where | Purpose |
| --- | --- | --- |
| Default non-GUI suite | CI and local shell | Project boundaries, `labkit` facade behavior, reusable UI helper checks that do not need graphics interaction, and pure app analysis/export helpers. |
| Focused GUI suite runs | Local MATLAB with graphics support | Noninteractive app launch, layout, and callback wiring checks for selected app families. |
| Manual GUI validation | User-run app windows | Interactive file selection, drawing, visual inspection, and full workflow feel. |

CI should not be described as full GUI workflow validation. It verifies the non-GUI behavior that can run reliably on GitHub-hosted MATLAB Actions.

For public repositories, MathWorks MATLAB Actions can license MATLAB automatically. For private repositories, configure a GitHub secret named `MLM_LICENSE_TOKEN` with a MATLAB batch licensing token.

Focused iteration commands:

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
scripts/run_matlab_tests.sh --test test_gui_layout_ui_helpers
```

Use the same option names from Windows PowerShell:

```powershell
.\scripts\run_matlab_tests.ps1 --suite labkit/dta
.\scripts\run_matlab_tests.ps1 --suite apps/electrochem
.\scripts\run_matlab_tests.ps1 --test test_gui_layout_ui_helpers
```

Use `--suite` for the source boundary touched by the change:

- `project`: startup and architecture guardrails
- `labkit/dta`: `labkit.dta` parser/session/facade checks
- `labkit/biosignal`: `labkit.biosignal` loading, processing, SNR, and group-comparison checks
- `labkit/ui`: reusable `labkit.ui` helper checks; add `--gui` for UI helper layout checks
- `apps/electrochem`: electrochem app-owned calculations, exports, and layout contracts
- `apps/dic`: DIC app layout contracts; usually run with `--gui`
- `apps/image_measurement`: image-measurement app-owned calculations, exports, and layout contracts
- `apps/wearable`: wearable app layout contracts; usually run with `--gui`
- `gui`: all noninteractive GUI checks across every target

For reusable library changes, explicitly add downstream app suites when the app-facing contract could be affected. For example, pair `labkit/dta` with `apps/electrochem`, `labkit/biosignal` with `apps/wearable`, and `labkit/ui` with `apps` plus `--gui` when layout or callback behavior changed. The runner intentionally does not infer dependencies; explicit suite lists keep the selected validation scope visible in the command and commit record.

Use `--suite` for one or more test targets. The primary targets mirror source ownership: `project`, `labkit/dta`, `labkit/biosignal`, `labkit/ui`, `apps/electrochem`, `apps/dic`, `apps/image_measurement`, `apps/wearable`, and `apps/smoke`. Parent targets such as `labkit` and `apps` include their child suites. Use `--test` for one or more specific test functions. Selecting the `gui` suite or a `test_gui_*` function automatically uses GUI-capable MATLAB flags.

The stable entry point is `tests/run_all_tests.m`. It discovers test files directly from `tests/suites/<target>/test_*.m`, so adding a focused test normally only requires placing it in the appropriate target folder. There is no separate runner framework directory; runner logic stays local to the stable entry point until it grows enough to justify extraction.

The suite layout is:

```text
project                    startup/root-entry boundaries and architecture guardrails
labkit/dta                 DTA parser/facade/session/pulse/item-schema checks
labkit/biosignal           biosignal loading, channel extraction, processing, segments, SNR, and group comparison
labkit/ui                  reusable UI helpers and noninteractive UI layout contracts
apps/electrochem           electrochem app-owned calculations, exports, and layout contracts
apps/dic                   DIC app layout contracts
apps/image_measurement     image-measurement app-owned calculations, exports, and layout contracts
apps/wearable              wearable app layout contracts
apps/smoke                 cross-app launch smoke checks
```

Shared setup, structural GUI assertions, and focused support routines live under `tests/helpers/`. Keep helpers limited to setup and assertions; app-specific formulas, result schemas, export formats, and expected scientific values should remain in focused suite tests. The custom runner reports per-test and per-suite durations so slow checks can be identified without running a profiler.

GUI workflows are checked manually outside this protocol. The automated GUI checks are structural assertion tests: they launch app windows, inspect component contracts, verify callback wiring, and check reusable layout/helper handles. They do not validate visual pixel quality, actual drag/draw gestures, or full user workflow feel. Use `--suite <target> --gui`, `scripts/run_matlab_tests.sh --gui`, or `.\scripts\run_matlab_tests.ps1 --gui` locally only when noninteractive launch/layout/callback coverage is relevant; GUI/uifigure checks are intentionally not part of the default GitHub-hosted CI job.

Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Numerical Tolerance

Default direct numerical tolerance:

```matlab
abs(oldValue - newValue) < 1e-9
```

Use looser tolerances only when justified by interpolation, plotting-only alignment, or format conversion. Document any looser tolerance in the test.

Use `tests/helpers/assertClose.m` for repeated exact or tolerance-based numeric checks instead of redefining local assertion helpers in each test file.
Use `tests/helpers/dtaFixtureDir.m`, `tests/helpers/dtaFixturePath.m`, and focused fixture builders such as `tests/helpers/makeChronoFixtureItem.m` when multiple tests need the same DTA fixture setup. Keep those helpers limited to test setup; do not move app-specific analysis, export schemas, or expected values into shared test helpers.

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

Tests may require these named fixtures. They should not fail only because extra DTA files are added to `tests/fixtures/dta/`.

## Coverage Areas

Parser changes:

- chrono T/Vf/Im/Pt interpretation, AREA, SAMPLETIME, ISTEP/VSTEP/TSTEP metadata
- EIS ZCURVE extraction and all supported axis values
- CV/CT SCANRATE conversion, CURVE discovery, headers, units, and numeric parsing
- DTA facade recursive discovery, type detection, expected-kind normalization, expected-kind mismatch status, missing-file status, and GUI-free batch/folder loading reports
- app-facing DTA session helpers for adding, skipping duplicate, selecting, and removing loaded items
- app-facing DTA pulse detection facade so apps do not call internal analysis APIs directly

Pulse changes:

- metadata-first, metadata-only, and current-only modes
- ISTEP/TSTEP and VSTEP/TSTEP timing
- cathodic/anodic/gap start and end fields
- compatibility flat fields and normalized nested fields

Analysis changes:

- VT resistance median windows, baseline estimate, baseline-corrected mode, raw mode, result/export tables
- CIC Emc/Ema, injected charge, area handling, mC/uC conversions, water-window safety, result/export tables
- CV/CSC sign-split integration, zero-crossing handling, CT recorded-time charge, CV scan-rate-derived charge, and displayed result fields
- EIS axis values, log filtering, Nyquist equal-axis behavior, current-plot export table

App-boundary changes:

- public app files do not depend on transitional app-specific helper packages
- app-specific helper packages and private launcher directories are not reintroduced for workflow code that belongs to one app
- public app files do not call `labkit.io.*`, `labkit.data.*`, `labkit.analysis.*`, or `labkit.util.*` directly
- public app files use `labkit.dta.*` for DTA discovery, loading, session creation, removal, selection, pulse detection, and parsed table/curve access
- wearable/biosignal app files use `labkit.biosignal.*` for recording loading, channel extraction, waveform processing, events, segments, measurements, and group comparisons
- public `+labkit/+data` and `+labkit/+io` packages are not reintroduced; parser, session IO, item construction, and table/curve access stay behind the DTA facade
- app-local files keep the recommended single-file layout: entry/test hook, GUI construction, nested callbacks, app-local analysis, export/table helpers, plotting helpers, and small utilities
- pulse detection remains behind `labkit.dta.detectPulses` with implementation helpers kept private, and experiment-specific CIC, VT, CSC, EIS, result-table, or CSV-writing workflow code does not return to a public reusable analysis package
- reusable `+labkit/+dta` stays GUI-free and app-free: no MATLAB UI constructors, file dialogs, alerts, app entry points, or `apps/` helper calls
- reusable `+labkit/+ui` stays parser/data/analysis-free: apps pass prepared values and labels into GUI helpers rather than letting GUI helpers call DTA, parser, data, or analysis APIs
- helper code stays internal: parser-only helpers remain package-private, app-specific helpers remain app-local, and no public `+labkit/+util` app-facing surface is reintroduced
- keep these architecture guardrails in `tests/suites/project/test_architecture_boundaries.m` rather than duplicating them in numerical analysis tests

Session/export changes:

- session type/version/kind
- add/remove duplicate and failure behavior
- save/load round trips
- CSV headers, column order, failed-row formatting, and quoted text behavior

GUI or entrypoint changes:

- app entry points still launch, use `labkit.ui.createWorkbench`, and initialize expected controls/callbacks; interactive GUI workflows are checked manually

## Handoff After Validation

Report:

- test command run and pass/fail result
- MATLAB availability
- files changed
- behavior intentionally preserved

## Commit Messages

Use the same concise Conventional Commits style described in `AGENTS.md`:

```text
feat: add or change user-facing capability
fix: correct a bug or broken workflow
docs: update documentation only
test: add or update tests only
ci: update GitHub Actions or automation
refactor: restructure code without intended behavior change
chore: maintenance that does not fit the above
```

Keep commits small and logical. Do not mix unrelated functional, documentation, formatting, and test changes in one commit. When source, tests, and docs are changed together to support one behavior, keep the summary focused on that behavior. Because this repository uses git history instead of a changelog, include a compact body for nontrivial commits with the intent, public API or boundary impact, and validation command.
