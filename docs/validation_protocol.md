# Validation Protocol

This document defines how behavior-preserving refactors should be checked.

The core validation rule is:

```text
old legacy behavior == new package-backed behavior
```

within appropriate numerical tolerance.

---

## 1. Test Runner

Default local test command:

```bash
scripts/run_matlab_tests.sh
```

Optional noninteractive GUI command:

```bash
scripts/run_matlab_tests.sh --gui
```

The default test runner is for pure functions only.

Do not run interactive GUI workflows in MATLAB `-batch` mode.

---

## 2. What Default Tests Should Cover

Default tests should cover:

- utility helpers
- parser functions
- data accessors
- pulse detection
- future analysis functions
- export table builders

Default tests should not cover:

- `uifigure` interaction
- `uigetfile` interaction
- `uialert` behavior
- manual plot interaction
- interactive GUI callbacks that require user input

---

## 3. Numerical Tolerance

Default tolerance for direct numerical equivalence:

```matlab
abs(oldValue - newValue) < 1e-9
```

Use looser tolerance only when justified, for example:

- interpolation onto a merged time axis
- plotting-only data alignment
- format conversion that preserves scientific meaning

Any looser tolerance should be documented in the test or migration notes.

---

## 4. Demo Fixtures

Named demo fixtures live under `demo/`.

Current fixture roles:

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

Tests should assert required named fixtures exist.

Tests may assert minimum fixture counts, but should not fail merely because extra DTA files are added to `demo/`.

---

## 5. Golden Reference Strategy

For scientific analysis extraction, use golden references when possible.

Planned reference files:

```text
tests/reference/cic_expected.mat
tests/reference/vt_resistance_expected.mat
tests/reference/csc_expected.mat
tests/reference/eis_expected.mat
tests/reference/chrono_overlay_expected.mat
```

A golden reference should store:

- input fixture name
- analysis options
- key output values
- expected table column names
- tolerance
- creation date
- legacy implementation used to generate it

Do not overwrite reference outputs silently. If a reference changes, document why.

---

## 6. Parser Validation

### Chrono parser

Verify:

```text
T/Vf/Im arrays exist
Pt column behavior is preserved
NaN rows are handled consistently downstream
unique-time behavior is preserved downstream
AREA metadata is parsed
SAMPLETIME metadata is parsed
ISTEP/VSTEP/TSTEP metadata is parsed
main curve is detected
```

### EIS parser

Verify:

```text
ZCURVE extraction
Freq
Zreal
Zimag
-Zimag derived behavior
Zmod
Zphz
Idc
Vdc
axis-value generation once extracted
```

### CV/CT parser

Verify:

```text
SCANRATE extraction
mV/s to V/s conversion
CURVE discovery
headers
units
numeric table parsing
selected curve behavior once item models are added
```

---

## 7. Pulse Detection Validation

Verify:

```text
metadata-first mode
metadata-only mode
current-only mode
fallback behavior
ISTEP/TSTEP timing
VSTEP/TSTEP timing
cathodic start/end
anodic start/end
gap start/end
gap center
legacy flat fields
normalized nested fields
```

Current known scope:

- The shared detector is intended to preserve legacy single cathodic-first biphasic behavior.
- Multi-cycle and anodic-first protocols are future extensions, not current refactor requirements.

---

## 8. CIC Validation

CIC extraction has started. Verify:

```text
Emc
Ema
cathodic charge
anodic charge
total charge
CIC normalization
mC/cm^2 and uC/cm^2 conversions
water-window safety status
best safe file among loaded
batch result table values
CSV export values
```

Current default tests include CIC checks for:

```text
analysis values for measured and nominal charge modes
metadata area and area override behavior
water-window safe/unsafe status
CSV result table variable names for mC/cm^2 and uC/cm^2
legacy 8-column batch table data and dynamic unit labels
legacy CSV header spelling/order
legacy CSV failed-row empty-field formatting
legacy CSV quoted text behavior
```

Do not start CIC extraction without either golden references or a clearly documented legacy comparison script.

---

## 9. VT Resistance Validation

VT resistance extraction has started. Verify:

```text
phase current median
steady voltage median
baseline estimate
baseline-corrected resistance
raw voltage resistance mode
cathodic resistance
anodic resistance
average resistance
batch result table values
CSV export headers
CSV export values
legacy failed-row formatting
```

Current default tests include VT resistance checks for:

```text
analysis values for full and center-60% windows
baseline-corrected and raw resistance modes
legacy failure messages
CSV result table variable names
legacy 9-column batch table data
legacy CSV header spelling/order
legacy CSV NaN failed-row formatting
legacy CSV quoted text escaping
```

---

## 10. CV/CSC Validation

CV/CSC extraction has started. Verify:

```text
negative-current integration
positive-current integration
full charge
recorded-time CT charge
scan-rate-derived CV charge
CSC normalization
relative difference
max |dt - |dV|/v|
plot trim behavior
```

Important rule:

```text
Do not compute CV charge as trapz(V, I) directly.
```

The legacy rule is:

```text
dt = abs(dV) / scanRate
Qcv = integral I * dt
```

Current default tests include a CV fixture reference check for:

```text
Full, cathodic, and anodic modes
CT charge
CV charge
CSC normalization
relative difference
max |dt - |dV|/v|
exact current zero-crossing sign split
legacy failure messages
selected X/Y exact-case behavior
selected X/Y NaN filtering
plot title, labels, line width, and invalid-selection handling
```

---

## 11. EIS Validation

EIS overlay/export extraction has started. Verify:

```text
Nyquist plot behavior
Bode-style plot behavior
axis labels
log X checkbox behavior
log Y checkbox behavior
marker behavior
line width behavior
marker size behavior
legend behavior
grid behavior
CSV column names
CSV numeric values
```

Current default tests include EIS checks for:

```text
makeEISItem fixture fields
all legacy axis-value labels
current-plot export table variable names
finite-value filtering
log-X/log-Y positive-value filtering
plot labels and titles
log axis scale settings
Nyquist equal-axis behavior
```

---

## 12. GUI Validation

GUI validation is not part of the default batch test runner.

The optional `--gui` tests verify that the five root compatibility GUI entry points can create and close their main `uifigure` windows. They also enforce the current legacy GUI compatibility contract, including exact initialized component counts, required buttons, checkboxes, dropdown items, tab titles, axes, result tables, text areas, list boxes, window-size floors, and callback bindings for buttons/dropdowns. Safe callbacks such as refresh, reset, clear, dropdown changes, and checkbox changes are invoked on an empty session.

The optional GUI tests do not validate file dialogs, callbacks that require user input, visual layout quality, exported files, manual plot interaction, or workflows that require loaded user data.

Manual GUI checks should confirm:

- original command names still launch
- file open dialog works
- folder open dialog works
- duplicate skipping behavior remains
- plot controls still work
- export buttons still produce expected files
- result tables still populate
- log panels still show meaningful messages

Keep noninteractive GUI tests separate from the default pure-function test runner.

---

## 13. Session Validation

Phase 9 session extraction has started. Verify:

```text
session struct type/version/kind
empty item/result defaults
loader-driven file add behavior
duplicate filepath skipping
loader failure reporting
loader callback ordering
remove by filepath or item name
MAT save/load round trip
batch summary name/filepath/ok/message columns
```

---

## 14. Handoff Requirements After Validation

After a refactor phase, report:

- tests run
- passed/failed status
- MATLAB availability
- files changed
- behavior intentionally preserved
- any unverified behavior
- any reference outputs added or changed
