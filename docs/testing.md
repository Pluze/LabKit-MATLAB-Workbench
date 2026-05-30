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

Focused iteration commands:

```bash
scripts/run_matlab_tests.sh --suite core
scripts/run_matlab_tests.sh --suite gui
scripts/run_matlab_tests.sh --test test_gui_layout_controls
```

Use `--suite` for one or more suite keys: `core`, `dta`, `apps`, or `gui`. Use `--test` for one or more specific test functions. Selecting the `gui` suite or a `test_gui_*` function automatically uses GUI-capable MATLAB flags.

The default suite is grouped in `tests/run_all_tests.m` and organized on disk under `tests/suites/`:

```text
core    startup/root-entry boundaries, architecture guardrails, templates
dta     parsers through the DTA facade, DTA discovery/detection/loading/session helpers, pulse detection, and item schemas
apps    app-local analysis values, plotting helpers, export table builders, and CSV writers
gui     optional noninteractive launch/layout/callback checks
```

Shared setup and assertions live under `tests/helpers/`. Keep helpers limited to setup and assertions; app-specific formulas, result schemas, export formats, and expected scientific values should remain in focused suite tests.

GUI workflows are checked manually outside this protocol. Use `scripts/run_matlab_tests.sh --gui` only when noninteractive launch/layout/callback coverage is relevant.

Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Numerical Tolerance

Default direct numerical tolerance:

```matlab
abs(oldValue - newValue) < 1e-9
```

Use looser tolerances only when justified by interpolation, plotting-only alignment, or format conversion. Document any looser tolerance in the test.

Use `tests/helpers/assertClose.m` for repeated exact or tolerance-based numeric checks instead of redefining local assertion helpers in each test file.
Use `tests/helpers/demoFixtureDir.m`, `tests/helpers/demoFixturePath.m`, and focused fixture builders such as `tests/helpers/makeChronoFixtureItem.m` when multiple tests need the same demo fixture setup. Keep those helpers limited to test setup; do not move app-specific analysis, export schemas, or expected values into shared test helpers.

## Fixture Expectations

Named demo fixtures live under `demo/`:

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

Tests may require these named fixtures. They should not fail only because extra DTA files are added to `demo/`.

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
- public app files and templates do not call `labkit.io.*`, `labkit.data.*`, `labkit.analysis.*`, or `labkit.util.*` directly
- public app files use `labkit.dta.*` for DTA discovery, loading, session creation, removal, selection, pulse detection, and parsed table/curve access
- public `+labkit/+data` and `+labkit/+io` packages are not reintroduced; parser, session IO, item construction, and table/curve access stay behind the DTA facade
- app-local files keep the recommended single-file layout: entry/test hook, GUI construction, nested callbacks, app-local analysis, export/table helpers, plotting helpers, and small utilities
- pulse detection remains behind `labkit.dta.detectPulses` with implementation helpers kept private, and experiment-specific CIC, VT, CSC, EIS, result-table, or CSV-writing workflow code does not return to a public reusable analysis package
- reusable `+labkit/+dta` stays GUI-free and app-free: no MATLAB UI constructors, file dialogs, alerts, app entry points, or `apps/` helper calls
- reusable `+labkit/+ui` stays parser/data/analysis-free: apps pass prepared values and labels into GUI helpers rather than letting GUI helpers call DTA, parser, data, or analysis APIs
- helper code stays internal: parser-only helpers remain package-private, app-specific helpers remain app-local, and no public `+labkit/+util` app-facing surface is reintroduced
- keep these architecture guardrails in `tests/suites/core/test_architecture_boundaries.m` rather than duplicating them in numerical analysis tests

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
