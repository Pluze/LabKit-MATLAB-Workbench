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

Axis-value generation for EIS should be centralized later in:

```text
+gamrywb/+analysis/valuesForEISAxis.m
```

---

## 5. CVCTItem

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

Current parser note:

`gamrywb.io.parseCVCTDTA` currently returns scan rate, curves, and log messages. A full `makeCVItem` wrapper is planned for a later phase.

---

## 6. Pulse Struct

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

## 7. Session Struct

A shared session model is planned for a later phase.

Target structure:

```matlab
session = struct();
session.type = "gamrywb_session";
session.createdAt = datetime("now");
session.modifiedAt = datetime("now");
session.items = struct([]);
session.results = struct([]);
session.options = struct();
session.notes = "";
```

Session files should eventually include:

- raw parsed data
- selected analysis mode
- options
- results
- notes
- file provenance

Do not use opaque object dumps for long-term scientific data exchange.

---

## 8. Option Structs

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

## 9. Data Model Stability Rule

Before converting any struct model into a MATLAB class, the project should have:

- stable field names
- tests for parser outputs
- tests for analysis outputs
- at least one real workflow using the struct model
- documented migration needs

Until then, structs are preferred.
