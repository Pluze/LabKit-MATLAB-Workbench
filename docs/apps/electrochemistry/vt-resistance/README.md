# VT Resistance

VT Resistance estimates cathodic and anodic steady resistance from a biphasic
voltage transient and reports the mean of their absolute values.

## Requirements And Launch

The app uses the LabKit UI framework and DTA library and requires a chrono DTA curve with
valid time, voltage, and current columns.

```matlab
labkit_VTResistance_app
```

## Inputs And Batch Behavior

Add one or more chrono `.DTA` files. The selected file is decoded and analyzed
for preview; exporting applies the current settings to the full source list.
No electrode-area normalization is performed because the reported quantity is
electrical resistance in ohms. Runtime V2 reconciles the ordered lazy path list
with durable source records, preserving retained identities and allocating
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
- [API Reference](../../../libraries/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata, requirements, layout, and
optional runtime capabilities. `projectSpec.m` owns the complete version-1
domain schema, defaults, analysis-parameter validation, and the required source
collection; Runtime validates canonical buckets and each source record first.
`createSession.m` deliberately decodes only the first source for preview; the
remaining batch stays lazy until selection or export. The App requires
`labkit.ui >=7 <8` and
`labkit.dta >=2 <3`; Runtime supplies omitted empty session buckets and owns
workflow-log initialization. Busy-state, source identity, resolved-path
access, and portable-reference serialization remain framework-owned.
