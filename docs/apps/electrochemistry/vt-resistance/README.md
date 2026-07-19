# VT Resistance

VT Resistance estimates cathodic and anodic steady resistance from a biphasic
voltage transient and reports the mean of their absolute values.

## Requirements And Launch

The app uses the LabKit App framework and DTA library and requires a chrono
DTA curve with valid time, voltage, and current columns.

```matlab
labkit_VTResistance_app
```

## Inputs And Batch Behavior

Add one or more chrono `.DTA` files. The transient session decodes and analyzes
the registered batch so shared setting changes update every result together.
No electrode-area normalization is performed because the reported quantity is
electrical resistance in ohms. The App runtime reconciles the ordered source
list with durable source records, preserving retained identities and allocating
collision-free identities for later additions.

## Basic Workflow

1. Add files and select a representative transient.
2. Choose pulse detection, steady-window policy, and voltage definition.
3. Inspect detected phase windows and current/voltage traces.
4. Review cathodic, anodic, and average resistance.
5. Export the batch result CSV.

## Analysis Parameters

| Parameter | Default | Alternatives |
| --- | --- | --- |
| Pulse detection | Metadata first, then auto | Metadata only; Auto from Im only |
| Steady window | Full pulse median | Center 60% median |
| Resistance voltage | Baseline-corrected dV/I | Raw Vf/I |

The center-60% policy uses the interval from 20% to 80% of each detected phase
to reduce onset and offset transients. Plot marker and shading choices affect
display only.

## Calculation Semantics

After finite-sample filtering and pulse detection, the app calculates median
current and voltage in the chosen cathodic and anodic steady windows. The
cathodic baseline is the median pre-pulse voltage and the anodic baseline is
the median post-pulse voltage, with explicit finite fallbacks.

Baseline-corrected mode uses:

```text
R_cath = (V_cath,steady - V_cath,baseline) / I_cath,steady
R_anod = (V_anod,steady - V_anod,baseline) / I_anod,steady
R_average = mean(abs(R_cath), abs(R_anod))
```

Raw mode replaces each voltage difference with its steady absolute voltage.
Division by a missing, non-finite, or effectively zero current returns `NaN`;
the app does not invent a finite resistance.

## Output Schema

The CSV contains source identity, steady currents and voltages, baseline
voltages and windows, raw and baseline-corrected resistance fields, selected
resistance values, absolute cathodic/anodic resistance, average resistance,
pulse-detection method, and status. A result manifest records the common batch
parameters and output role.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("pulse.DTA", "chrono");
assert(status.ok, status.message);

options = struct( ...
    "pulseMode", "Metadata first, then auto", ...
    "windowMode", "Full pulse median", ...
    "voltageMode", "Baseline-corrected dV/I");
result = vt_resistance.analysisRun.computeResistance(item, options);
assert(result.ok, result.message);
```

## Errors And Limitations

- At least five finite `T`, `Vf`, and `Im` samples are required.
- Each selected steady window must contain at least two samples.
- Resistance is invalid when steady current is zero or non-finite.
- The result is a transient-derived estimate and does not replace an impedance
  model or compensate wiring/contact resistance automatically.

## Related Topics

- [Electrochemistry family](../README.md)
- [CIC](../cic/README.md)
- [DTA Library](../../../libraries/dta/README.md)
- [API Reference](../../../reference/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata and the immutable App SDK
contract. `projectSpec.m` owns the complete version-1 domain schema, defaults,
analysis-parameter validation, and required source collection.
`+workbench/buildLayout.m` binds fields and buttons directly to concrete
capability callbacks, while `+workbench/present.m` produces a complete
`labkit.app.view.Snapshot`. The App requires `labkit.app >=1 <2` and
`labkit.dta >=2 <3`. Lifecycle, callback dispatch, source identity,
resolved-path access, project documents, result manifests, and native layout
remain framework-owned.
