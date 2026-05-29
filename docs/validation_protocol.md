# Validation Protocol

Use this document to choose checks for behavior-preserving changes.

Core rule:

```text
previous validated behavior == current package-backed behavior
```

Do not claim behavior is preserved unless tests, fixtures, or manual checks support that claim.

## Test Commands

Default pure-function suite:

```bash
scripts/run_matlab_tests.sh
```

Optional noninteractive GUI compatibility suite:

```bash
scripts/run_matlab_tests.sh --gui
```

The default suite is listed in `tests/run_all_tests.m` under `defaultTests()` and covers parsers, utilities, data accessors, DTA facade discovery/detection/loading, pulse detection, analysis functions, plotting helpers, export table builders, session helpers, UI-table helpers, and app-entry resolution.

The GUI suite is listed in `tests/run_all_tests.m` under `guiTests()` and checks launch/layout/callback compatibility without file dialogs, exports, destructive workflows, or manual input.

Do not run interactive GUI workflows in MATLAB `-batch` mode.

## Numerical Tolerance

Default direct numerical tolerance:

```matlab
abs(oldValue - newValue) < 1e-9
```

Use looser tolerances only when justified by interpolation, plotting-only alignment, or format conversion. Document any looser tolerance in the test.

Use `tests/assertClose.m` for repeated exact or tolerance-based numeric checks instead of redefining local assertion helpers in each test file.
Use `tests/demoFixtureDir.m`, `tests/demoFixturePath.m`, and focused fixture builders such as `tests/makeChronoFixtureItem.m` when multiple tests need the same demo fixture setup. Keep those helpers limited to test setup; do not move app-specific analysis, export schemas, or expected values into shared test helpers.

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

## What To Validate

Parser changes:

- chrono T/Vf/Im/Pt interpretation, AREA, SAMPLETIME, ISTEP/VSTEP/TSTEP metadata
- EIS ZCURVE extraction and all supported axis values
- CV/CT SCANRATE conversion, CURVE discovery, headers, units, and numeric parsing
- DTA facade recursive discovery, type detection, expected-kind mismatch status, missing-file status, and GUI-free batch/folder loading reports

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
- reusable `+gamrywb/+io` does not regain app-specific export-table or CSV writer helpers
- keep these architecture guardrails in `tests/test_phase10_apps.m` rather than duplicating them in numerical analysis tests

Session/export changes:

- session type/version/kind
- add/remove duplicate and failure behavior
- save/load round trips
- CSV headers, column order, failed-row formatting, and quoted text behavior

GUI or entrypoint changes:

- app entry points launch the expected GUI
- initialized controls, dropdown items, result-table columns, axes titles/labels, callbacks, and window size still satisfy the GUI contract

Manual GUI checks are still needed for file dialogs, export buttons, loaded-data workflows, plot interactions, and user alerts.

## Golden References

Stored golden MAT references are not complete yet. If added, they should record:

- fixture name
- options
- key output values
- expected table column names
- tolerance
- creation date
- source revision used to generate the reference

Do not overwrite reference outputs silently.

## Handoff After Validation

Report:

- test command run and pass/fail result
- MATLAB availability
- files changed
- behavior intentionally preserved
- unverified manual behavior
- reference outputs added or changed
