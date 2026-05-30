# DTA Library

`labkit.dta.*` is the current electrochemistry data/file implementation. It provides GUI-free Gamry DTA discovery, loading, sessions, pulse detection, parser access, and parsed table/curve helpers.

## Public DTA API

Common loading calls:

```matlab
filepaths = labkit.dta.findFiles(folder);
[item, status] = labkit.dta.loadFile(filepath, "chrono");
[items, report] = labkit.dta.loadFiles(filepaths, "auto");
[items, report] = labkit.dta.loadFolder(folder, "auto");
kind = labkit.dta.detectType(filepath);
```

Supported expected kinds:

```text
"auto"
"chrono"
"eis"
"cvct"
```

Expected kinds are trimmed, case-insensitive, and blank strings default to `"auto"`. Invalid expected kinds raise `labkit:dta:InvalidKind` before loading starts.

Use the smallest loading API that matches the workflow:

```text
One explicit file:        labkit.dta.loadFile
Known list of files:      labkit.dta.loadFiles
Script/prototype folder:  labkit.dta.loadFolder
GUI session app:          labkit.dta.addFilesToSession
```

Session helpers:

```matlab
session = labkit.dta.makeSession('new_experiment');
[session, report] = labkit.dta.addFilesToSession(session, files, "chrono", callbacks);
[selectedItems, idx] = labkit.dta.selectSessionItems(session, selectedNames);
[session, report] = labkit.dta.removeSelectedItemsFromSession(session, selectedNames, callbacks);
labkit.dta.saveSession(session, filepath);
session = labkit.dta.loadSession(filepath);
```

Parsed table and curve helpers:

```matlab
[curve, ok, msg] = labkit.dta.getMainCurve(item.tables);
[zcurve, ok, msg] = labkit.dta.getZCurve(item.tables);
values = labkit.dta.getColumn(curve, 'Vf');
[x, y, xName, yName] = labkit.dta.getCurveXY(curve, 'T', 'Im');
```

Pulse detection:

```matlab
[pulse, message] = labkit.dta.detectPulses(t, Im, meta, "Metadata first, then auto");
```

Lower-level recursive discovery, parser functions, item construction, session mutation, and pulse internals are private DTA implementation details.

## Parser Assumptions

Gamry DTA files are treated as tab-delimited text files. Current parser steps generally:

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

Private parser helpers include:

```text
+labkit/+dta/private/parseChronoDTA.m
+labkit/+dta/private/parseEISDTA.m
+labkit/+dta/private/parseCVCTDTA.m
+labkit/+dta/private/splitTabs.m
+labkit/+dta/private/nextNonEmpty.m
+labkit/+dta/private/isDataLike.m
```

Parser behavior should remain compatible with validated fixtures unless a behavior change is explicitly requested and validated.

## Chrono Items

Created by `labkit.dta.loadFile(filepath, "chrono")`.

Current fields include:

```text
type, filepath, name, meta, tables, curve,
controlMode, t_s, Vf_V, Im_A, pt, n, pulse,
alignTime_s, tAligned_s, message, logmsg, analysis
```

`controlMode` is inferred from chrono step metadata:

```text
current   ISTEP/TSTEP metadata
voltage   VSTEP/TSTEP metadata
unknown   no controlled step family detected
```

Chrono metadata currently parsed:

```text
AREA
SAMPLETIME
ISTEPn
VSTEPn
TSTEPn
```

Compatibility bridge fields include:

```text
t, Vf, Im, alignTime, tAligned
```

## EIS Items

Created by `labkit.dta.loadFile(filepath, "eis")`.

Current fields include:

```text
type, filepath, name, meta, tables, zcurve,
freq_Hz, time_s, point,
Zreal_ohm, Zimag_ohm, negZimag_ohm,
Zmod_ohm, Zphz_deg, Idc_A, Vdc_V,
message, logmsg, analysis
```

Compatibility bridge fields include:

```text
Freq, Time, Pt, Zreal, Zimag, negZimag, Zmod, Zphz, Idc, Vdc
```

Supported EIS axis values:

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

## CV/CT Items

Created by `labkit.dta.loadFile(filepath, "cvct")`.

Current fields include:

```text
type, filepath, name, scanRate, scanRate_V_per_s, curves, logmsg, analysis
```

CV/CT parser behavior to preserve:

- `SCANRATE` is extracted when available.
- `SCANRATE` is converted from mV/s to V/s by dividing by 1000.
- `CURVE` sections are discovered and parsed in order.
- Headers, units, data, and numeric masks are preserved for each curve.
- Numeric rows are parsed conservatively.

## Pulse Struct

Pulse detection returns both compatibility flat fields and normalized nested fields.

Compatibility flat fields:

```text
ok, method, message,
cath_start, cath_end, anod_start, anod_end,
Ic_nominal, Ia_nominal,
pre_start, pre_end, gap_start, gap_end, post_start, post_end
```

Normalized fields:

```text
cath.start_s, cath.end_s, cath.current_A,
anod.start_s, anod.end_s, anod.current_A,
gap.start_s, gap.end_s, gap.center_s
```

## Session Struct

Created by `labkit.dta.makeSession`.

Current fields:

```text
type, version, kind, createdAt, modifiedAt,
items, results, options, notes, logmsg
```

`labkit.dta.addFilesToSession` supports `onAdded`, `onSkipped`, and `onFailed` callbacks so apps can preserve log timing while sharing DTA add/duplicate/failure logic. Empty file lists are no-ops that return empty reports without firing callbacks.

## Test Fixtures

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

Tests may require specific named fixtures but should not fail only because additional DTA files are added to `tests/fixtures/dta/`.
