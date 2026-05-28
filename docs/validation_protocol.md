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

The default test runner is for pure functions only.

Do not run interactive GUI apps in MATLAB `-batch` mode.

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

When CIC extraction begins, verify:

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

Do not start CIC extraction without either golden references or a clearly documented legacy comparison script.

---

## 9. VT Resistance Validation

When VT resistance extraction begins, verify:

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
```

---

## 10. CV/CSC Validation

When CV/CSC extraction begins, verify:

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

---

## 11. EIS Validation

When EIS overlay/export extraction begins, verify:

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

---

## 12. GUI Validation

GUI validation is not part of the default batch test runner.

Manual GUI checks should confirm:

- original command names still launch
- file open dialog works
- folder open dialog works
- duplicate skipping behavior remains
- plot controls still work
- export buttons still produce expected files
- result tables still populate
- log panels still show meaningful messages

If a future noninteractive GUI smoke test is added, keep it separate from the default pure-function test runner.

---

## 13. Handoff Requirements After Validation

After a refactor phase, report:

- tests run
- passed/failed status
- MATLAB availability
- files changed
- behavior intentionally preserved
- any unverified behavior
- any reference outputs added or changed
