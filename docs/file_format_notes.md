# File Format Notes

This document records Gamry DTA parsing assumptions used by the refactor.

Parser behavior should remain legacy-compatible unless a behavior change is explicitly requested and validated.

---

## 1. General DTA Parsing Assumptions

Gamry DTA files are treated as tab-delimited text files.

Current parser steps generally follow this pattern:

```text
read file text
remove carriage returns
split into lines
split lines by tabs
scan metadata lines
scan numeric TABLE or CURVE sections
preserve headers and units where available
parse numeric rows into MATLAB arrays
```

Shared helpers used by parser code include:

```text
gamrywb.util.splitTabs
gamrywb.util.nextNonEmpty
gamrywb.util.isDataLike
gamrywb.data.getColumn
```

---

## 2. Chrono Parser

Current parser:

```text
+gamrywb/+io/parseChronoDTA.m
```

Purpose:

- Parse chronopotentiometry-style and chronoamperometry-style Gamry DTA files used by voltage transient, CIC, resistance, and overlay workflows.

Metadata currently parsed:

```text
AREA
SAMPLETIME
ISTEPn
VSTEPn
TSTEPn
```

Output style:

```matlab
[meta, tables, logmsg] = gamrywb.io.parseChronoDTA(filepath)
```

`meta.steps` stores step entries with fields:

```matlab
idx
I
V
T
```

Chrono parser behavior to preserve:

- `AREA` is stored as `meta.area_cm2` when numeric.
- `SAMPLETIME` is stored as `meta.sampleTime_s` when numeric.
- `ISTEPn/TSTEPn` and `VSTEPn/TSTEPn` sequences are preserved in step order.
- Numeric table sections are kept with headers, units, data, and numeric masks.
- Log messages include parsed table dimensions.

Downstream behavior to preserve:

- `getMainCurve` should prefer `CURVE`/`CURVE1`-style tables when available.
- T/Vf/Im/Pt interpretation should remain compatible with validated app behavior.
- Invalid T/Vf/Im row removal and stable unique-time handling remain downstream behavior for item creation or GUI loading.

---

## 3. EIS Parser

Current parser:

```text
+gamrywb/+io/parseEISDTA.m
```

Purpose:

- Parse Gamry EIS DTA files containing `ZCURVE` data.

Metadata currently parsed:

```text
TAG
TITLE
AREA
```

Output style:

```matlab
[meta, tables, logmsg] = gamrywb.io.parseEISDTA(filepath)
```

EIS parser behavior to preserve:

- Numeric tables are parsed with headers, units, data, and numeric masks.
- `ZCURVE` detection is handled by `gamrywb.data.getZCurve`.
- If table name matching fails, fallback behavior may identify a table by headers such as Freq/Zreal/Zimag.

Axis values that must remain supported:

```text
Freq (Hz)
log10(Freq)
Time (s)
Point #
Zreal (ohm)
Zimag (ohm)
-Zimag (ohm)
Zmod (ohm)
Zphz (deg)
Idc (A)
Vdc (V)
```

EIS item construction remains in the reusable DTA/data library. EIS overlay axis selection, plotting, and plot-export helpers are app-side workflow code local to the EIS app:

```text
+gamrywb/+data/makeEISItem.m
apps/gamrywb_EIS_app.m
```

---

## 4. CV/CT Parser

Current parser:

```text
+gamrywb/+io/parseCVCTDTA.m
```

Purpose:

- Parse Gamry CV / CT DTA files for charge integration and CSC workflows.

Output style:

```matlab
[scanRate, curves, logmsg] = gamrywb.io.parseCVCTDTA(filepath)
```

CV/CT parser behavior to preserve:

- `SCANRATE` is extracted from the file when available.
- `SCANRATE` is converted from mV/s to V/s by dividing by 1000.
- `CURVE` sections are discovered and parsed in order.
- Headers, units, data, and numeric masks are preserved for each curve.
- Numeric rows are parsed conservatively to preserve legacy behavior.

CV/CSC scientific rules are not parser behavior. The current app-side analysis entry point is `gamrywb_apps.csc.computeCSC`, with CT and CV charge helpers under `apps/+gamrywb_apps/+csc`.

---

## 5. Table Parsing Notes

Current parser implementations are intentionally conservative.

The chrono, EIS, and CV/CT parsers still share similar table-reading logic. This duplication is acceptable during behavior-preserving extraction because the first priority is legacy compatibility.

Do not perform deep parser unification until downstream tests show equivalent behavior across chrono, EIS, and CV/CT workflows. Add fixtures before broadening support to new Gamry experiment types.

---

## 6. Known Assumptions and Limitations

Current assumptions:

- DTA files are readable as text.
- Tab-separated fields are expected.
- Numeric rows are detected by attempting numeric conversion of row values.
- Metadata lines usually have at least three tab-separated tokens.
- Current supported workflows are based on the package-backed app entry points and demo fixtures.

Current limitations:

- Parser behavior is not yet generalized for every possible Gamry experiment type.
- More obscure DTA structures may require fixture-driven parser updates.
- Parser changes should be accompanied by test fixtures and behavior notes.

---

## 7. Demo Fixtures

Named fixtures live under `demo/`.

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

Tests may require specific named fixtures but should not fail only because additional DTA files are added to `demo/`.
