# Data Model Notes

This document records the current struct schemas used by the package-backed MATLAB helpers. Structs remain the project default; do not convert them to classes without explicit approval and tests.

## Naming

Use unit-explicit fields where possible:

```text
t_s, Vf_V, Im_A, area_cm2, charge_C, resistance_ohm,
freq_Hz, Zreal_ohm, Zimag_ohm, Zphz_deg
```

Compatibility bridge fields such as `t`, `Vf`, `Im`, `Freq`, and `Zreal` remain available where app code and tests still use them.

## Result Pattern

Analysis functions return result structs with status:

```matlab
result.ok = true;
result.message = "OK";
```

On failure:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

Package functions should not call GUI alert functions.

## Chrono Items

Created by `gamrywb.dta.loadFile(filepath, "chrono")`.

Current fields include:

```text
type, filepath, name, meta, tables, curve,
t_s, Vf_V, Im_A, pt, n, pulse,
alignTime_s, tAligned_s, message, logmsg, analysis
```

Compatibility bridge fields include:

```text
t, Vf, Im, alignTime, tAligned
```

Keep bridge fields until app, export, and test call sites no longer need them.

Chrono overlay pulse-gap alignment, overlay plotting, and overlay export table construction live as local functions in `apps/gamrywb_ChronoOverlay_app.m` because they are app workflow decisions rather than reusable DTA item schema.

## EIS Items

Created by `gamrywb.dta.loadFile(filepath, "eis")`.

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

EIS overlay axis-value generation, plotting, and plot-export table construction are local functions in `apps/gamrywb_EIS_app.m` because they are app workflow decisions rather than reusable DTA item schema.

## DTA Facade Status

`gamrywb.dta.findFiles`, `gamrywb.dta.loadFile`, `gamrywb.dta.loadFiles`, and `gamrywb.dta.loadFolder` are GUI-free helpers. They return paths, status structs, or report structs instead of GUI alerts for normal file mismatch and load failures.

`findFiles` returns a cell array of recursively discovered `.DTA`/`.dta` file paths:

```matlab
filepaths = gamrywb.dta.findFiles(folder)
```

`folder` must be a character vector or scalar string naming an existing folder. Non-path or missing-folder inputs are programmer errors and raise `gamrywb:dta:InvalidFolder`.

Status fields:

```text
ok, message, kind, expectedKind, filepath
```

`kind` is one of:

```text
chrono, eis, cvct, unknown
```

Batch `items` are returned as a cell array because `"auto"` loading can mix different DTA item schemas.
Empty batch inputs are no-ops that return no items and an empty report with zero counts.
`loadFile`, `loadFiles`, and `loadFolder` share the same `expectedKind` normalization: trim whitespace, ignore case, and treat blank strings as `"auto"`.
Invalid `expectedKind` values are programmer errors and raise `gamrywb:dta:InvalidKind` before batch or folder loading starts, even when the input file list or discovered folder contents are empty.

`loadFiles` report fields:

```text
loaded, failed, statuses, nRequested, nLoaded, nFailed
```

`loadFolder` adds folder-discovery provenance to the same report shape:

```text
folder, filepaths, nDiscovered
```

Folders with no `.DTA` files return no items, empty `filepaths`, `nDiscovered == 0`, and the same zero-count batch report fields.

DTA app session helpers wrap the lower-level session model for common app workflows:

```matlab
session = gamrywb.dta.makeSession(kind)
[session, report] = gamrywb.dta.addFilesToSession(session, filepaths, expectedKind, callbacks)
[items, idx] = gamrywb.dta.selectSessionItems(session, selectedNames)
[session, report] = gamrywb.dta.removeSelectedItemsFromSession(session, selectedNames, callbacks)
```

`addFilesToSession` report fields:

```text
added, skipped, failed, nAdded, nSkipped, nFailed
```

Chrono pulse detection is app-facing through:

```matlab
[pulse, message] = gamrywb.dta.detectPulses(t, Im, meta, mode)
```

Apps should prefer this DTA facade instead of any lower-level pulse detector implementation.
The pulse detector implementation is private to the DTA facade.

## CV/CT Data

`gamrywb.dta.loadFile(filepath, "cvct")` wraps the private CV/CT parser into a lightweight CV/CT item with:

```text
type, filepath, name, scanRate, scanRate_V_per_s, curves, logmsg, analysis
```

The CSC app's local analysis accepts a parsed curve and options containing:

```text
scanRate, mode, area_cm2
```

CSC CT/CV charge integration is a local detail of `apps/gamrywb_CSC_app.m`; it is not a separate reusable library API.

`gamrywb.dta.getCurveXY` operates on the parsed curve struct and preserves exact-case column matching and NaN filtering. Apps can pass those prepared X/Y vectors and labels to the reusable GUI helper `gamrywb.ui.plotXY`.

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

Do not remove flat fields until app, export, and analysis call sites no longer need them.

## Analysis Results

Current analysis result structs intentionally preserve compatibility fields used by GUI display and CSV/export helpers.

VT result/export workflow:

```text
apps/gamrywb_VTResistance_app.m local computeResistance
apps/gamrywb_VTResistance_app.m local buildResultsTable
apps/gamrywb_VTResistance_app.m local writeResultsCSV
apps/gamrywb_VTResistance_app.m local buildBatchTableData
```

VT steady-window selection and baseline estimation are local details of `apps/gamrywb_VTResistance_app.m`; they are not separate reusable APIs.

VT CSV column order:

```text
File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status
```

CIC result/export helpers:

```text
apps/gamrywb_CIC_app.m local computeCIC
apps/gamrywb_CIC_app.m local buildResultsTable
apps/gamrywb_CIC_app.m local writeResultsCSV
apps/gamrywb_CIC_app.m local buildBatchTableData
```

CIC CSV column order uses one of:

```text
File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_mCcm2,CICa_mCcm2,CICt_mCcm2,Safe,Detection
File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_uCcm2,CICa_uCcm2,CICt_uCcm2,Safe,Detection
```

The current CV/CSC app has no CSV export workflow, so it does not keep a standalone result-table/export helper.

## Session Struct

Created by `gamrywb.dta.makeSession`.

Current fields:

```text
type, version, kind, createdAt, modifiedAt,
items, results, options, notes, logmsg
```

Helpers:

```text
gamrywb.dta.makeSession
gamrywb.dta.addFilesToSession
gamrywb.dta.removeSelectedItemsFromSession
gamrywb.dta.selectSessionItems
gamrywb.dta.saveSession
gamrywb.dta.loadSession
```

`gamrywb.dta.addFilesToSession` supports `onAdded`, `onSkipped`, and `onFailed` callbacks so apps can preserve log timing while sharing DTA add/duplicate/failure logic. Empty file lists are no-ops that return empty reports without firing callbacks. Session item construction and session orchestration helpers are private to the DTA facade, not public `gamrywb.dta.*` app APIs. Public `gamrywb.dta.*` is limited to parsed table/curve access helpers.

Session files should keep parsed data, selected analysis mode, options, results, notes, and file provenance explicit. Avoid opaque object dumps for scientific exchange.
