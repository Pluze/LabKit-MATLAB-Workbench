# Data Model Notes

This document defines the intended struct-based data models for the package-backed refactor.

The current rule is: **use MATLAB structs first; do not introduce MATLAB classes until the struct model stabilizes.**

---

## 1. Naming Rules

Use explicit field names with units whenever possible.

Preferred examples:

```matlab
t_s
Vf_V
Im_A
area_cm2
charge_C
charge_mC_cm2
charge_uC_cm2
resistance_ohm
freq_Hz
Zreal_ohm
Zimag_ohm
```

Avoid ambiguous fields such as:

```matlab
time
voltage
current
area
charge
```

Legacy GUI structs may still use legacy names such as `t`, `Vf`, and `Im` until their migration phase.

---

## 2. Result Struct Pattern

Analysis functions should return a result struct rather than loose numeric arrays.

Preferred pattern:

```matlab
result = struct();
result.ok = true;
result.message = "";
result.options = opts;
result.values = struct();
result.debug = struct();
```

If an analysis cannot be completed:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

Package functions should not call `uialert`. GUI code decides how to display errors.

---

## 3. ChronoItem

Used for chronopotentiometry / voltage-transient files.

Target structure:

```matlab
item = struct();
item.type = "chrono";
item.filepath = filepath;
item.name = filename;
item.meta = meta;
item.tables = tables;
item.curve = curve;
item.t_s = t(:);
item.Vf_V = Vf(:);
item.Im_A = Im(:);
item.pt = pt(:);
item.n = numel(t);
item.pulse = pulse;
item.alignTime_s = NaN;
item.tAligned_s = [];
item.message = "";
item.logmsg = {};
item.analysis = struct();
```

Legacy compatibility note:

Current legacy GUI code may still use:

```matlab
item.t
item.Vf
item.Im
item.tAligned
item.alignTime
```

These fields should be preserved until the corresponding GUI migration explicitly changes them.

Current implementation note:

`gamrywb.data.makeChronoItem` now creates a chrono item with both legacy-compatible fields such as `t`, `Vf`, `Im`, `alignTime`, and `tAligned`, and unit-explicit fields such as `t_s`, `Vf_V`, `Im_A`, `alignTime_s`, and `tAligned_s`.

---

## 4. EISItem

Used for EIS `ZCURVE` data.

Target structure:

```matlab
item = struct();
item.type = "eis";
item.filepath = filepath;
item.name = filename;
item.meta = meta;
item.tables = tables;
item.zcurve = zcurve;
item.freq_Hz = freq(:);
item.time_s = time(:);
item.point = point(:);
item.Zreal_ohm = zreal(:);
item.Zimag_ohm = zimag(:);
item.Zmod_ohm = zmod(:);
item.Zphz_deg = zphz(:);
item.Idc_A = idc(:);
item.Vdc_V = vdc(:);
item.message = "";
item.logmsg = {};
item.analysis = struct();
```

Current package-backed EIS item construction lives in:

```text
+gamrywb/+data/makeEISItem.m
```

It currently returns legacy field names such as `Freq`, `Zreal`, `Zimag`, and `negZimag` so the legacy GUI can migrate without changing behavior. Normalized unit-suffixed aliases can be added later after GUI callers have migrated.

Axis-value generation for EIS is centralized in:

```text
+gamrywb/+analysis/valuesForEISAxis.m
```

---

## 5. VT Resistance Results

`gamrywb.analysis.computeVTResistance` returns a legacy-compatible result struct. Result/export helpers currently preserve the legacy GUI's field names and table columns rather than introducing a new normalized result model.

Current package-backed VT result helpers:

```text
+gamrywb/+io/buildVTResistanceResultsTable.m
+gamrywb/+io/writeVTResistanceResultsCSV.m
+gamrywb/+ui/buildVTResistanceBatchTableData.m
```

The CSV result table preserves the legacy column order:

```text
File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status
```

The GUI batch table remains a 9-column cell array matching the legacy `uitable` display.

---

## 6. CVCTItem

Used for CV / CT charge integration and CSC analysis.

Target structure:

```matlab
item = struct();
item.type = "cvct";
item.filepath = filepath;
item.name = filename;
item.meta = meta;
item.tables = tables;
item.curves = curves;
item.scanRate_V_s = scanRate;
item.currentCurve = 1;
item.message = "";
item.logmsg = {};
item.analysis = struct();
```

Parser note:

`gamrywb.io.parseCVCTDTA` currently returns scan rate, curves, and log messages. A full `makeCVItem` wrapper is planned for a later phase.

Analysis note:

`gamrywb.analysis.computeCSC` currently accepts a parsed curve struct plus an option struct containing `scanRate`, `mode`, and `area_cm2`. It returns legacy-compatible charge, CSC, relative-difference, and trim-vector fields. A full CVCT item wrapper can later normalize this call shape without changing the analysis rules.

Plot note:

`gamrywb.data.getCurveXY` and `gamrywb.plot.plotCVCT` currently operate on the same parsed curve struct. They preserve the legacy GUI's exact-case column matching and NaN row filtering.

---

## 7. Pulse Struct

Pulse detection currently returns a struct with both legacy-compatible flat fields and future normalized nested fields.

Legacy-compatible fields:

```matlab
pulse.ok
pulse.method
pulse.message
pulse.cath_start
pulse.cath_end
pulse.anod_start
pulse.anod_end
pulse.Ic_nominal
pulse.Ia_nominal
pulse.pre_start
pulse.pre_end
pulse.gap_start
pulse.gap_end
pulse.post_start
pulse.post_end
```

Normalized fields:

```matlab
pulse.cath.start_s
pulse.cath.end_s
pulse.cath.current_A
pulse.anod.start_s
pulse.anod.end_s
pulse.anod.current_A
pulse.gap.start_s
pulse.gap.end_s
pulse.gap.center_s
```

Migration rule:

Do not remove legacy flat fields until all legacy GUI call sites and analysis modules have migrated to normalized fields.

---

## 8. Session Struct

A shared session model has started in `gamrywb.data.makeSession`.

Current structure:

```matlab
session = struct();
session.type = 'gamrywb_session';
session.version = 1;
session.kind = 'generic';
session.createdAt = datestr(now);
session.modifiedAt = datestr(now);
session.items = struct([]);
session.results = struct([]);
session.options = struct();
session.notes = '';
session.logmsg = {};
```

Session helpers currently include:

```text
+gamrywb/+data/makeSession.m
+gamrywb/+data/addFilesToSession.m
+gamrywb/+data/removeFilesFromSession.m
+gamrywb/+io/saveSession.m
+gamrywb/+io/loadSession.m
+gamrywb/+analysis/summarizeBatchResults.m
```

Session files should include:

- raw parsed data
- selected analysis mode
- options
- results
- notes
- file provenance

Do not use opaque object dumps for long-term scientific data exchange.

---

## 9. Option Structs

Analysis functions should use option structs.

Example:

```matlab
opts = struct();
opts.area_cm2 = 2.01;
opts.delay_s = 10e-6;
opts.pulseMode = "metadata_first";
```

Avoid many positional arguments:

```matlab
% Avoid:
computeCIC(t, Vf, Im, area, delay, cathLimit, anodLimit, mode)
```

---

## 10. Data Model Stability Rule

Before converting any struct model into a MATLAB class, the project should have:

- stable field names
- tests for parser outputs
- tests for analysis outputs
- at least one real workflow using the struct model
- documented migration needs

Until then, structs are preferred.
