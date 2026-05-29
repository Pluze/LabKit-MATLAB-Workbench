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

Created by `gamrywb.data.makeChronoItem`.

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

## EIS Items

Created by `gamrywb.data.makeEISItem`.

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

Axis-value generation lives in `gamrywb.analysis.valuesForEISAxis`.

## DTA Facade Status

`gamrywb.dta.loadFile` and `gamrywb.dta.loadFiles` return status/report structs instead of GUI alerts for normal file mismatch and load failures.

Status fields:

```text
ok, message, kind, expectedKind, filepath
```

`kind` is one of:

```text
chrono, eis, cvct, unknown
```

Batch `items` are returned as a cell array because `"auto"` loading can mix different DTA item schemas.

## CV/CT Data

`gamrywb.io.parseCVCTDTA` returns:

```matlab
[scanRate, curves, logmsg] = gamrywb.io.parseCVCTDTA(filepath)
```

`gamrywb.dta.loadFile(filepath, "cvct")` wraps this parser into a lightweight CV/CT item with:

```text
type, filepath, name, scanRate, scanRate_V_per_s, curves, logmsg, analysis
```

`gamrywb_apps.csc.computeCSC` accepts a parsed curve and options containing:

```text
scanRate, mode, area_cm2
```

`gamrywb.data.getCurveXY` and `gamrywb.plot.plotCVCT` operate on the parsed curve struct and preserve exact-case column matching and NaN filtering.

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

VT result/export helpers:

```text
gamrywb_apps.vt.computeResistance
gamrywb_apps.vt.buildResultsTable
gamrywb_apps.vt.writeResultsCSV
gamrywb_apps.vt.buildBatchTableData
```

VT CSV column order:

```text
File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status
```

CIC result/export helpers:

```text
gamrywb.analysis.computeCIC
gamrywb.io.buildCICResultsTable
gamrywb.io.writeCICResultsCSV
gamrywb.ui.buildCICBatchTableData
```

CIC CSV column order uses one of:

```text
File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_mCcm2,CICa_mCcm2,CICt_mCcm2,Safe,Detection
File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_uCcm2,CICa_uCcm2,CICt_uCcm2,Safe,Detection
```

CSC result table construction lives in `gamrywb_apps.csc.buildResultsTable`. The current CV/CSC app has no CSV export workflow.

## Session Struct

Created by `gamrywb.data.makeSession`.

Current fields:

```text
type, version, kind, createdAt, modifiedAt,
items, results, options, notes, logmsg
```

Helpers:

```text
gamrywb.data.makeSession
gamrywb.data.addFilesToSession
gamrywb.data.removeFilesFromSession
gamrywb.io.saveSession
gamrywb.io.loadSession
gamrywb.analysis.summarizeBatchResults
```

`addFilesToSession` supports `onAdded`, `onSkipped`, and `onFailed` callbacks so apps can preserve log timing while sharing add/duplicate/failure logic.

Session files should keep parsed data, selected analysis mode, options, results, notes, and file provenance explicit. Avoid opaque object dumps for scientific exchange.
