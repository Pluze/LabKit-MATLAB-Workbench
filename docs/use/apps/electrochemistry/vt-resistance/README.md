# VT Resistance

```labkit-page
id: app-vt-resistance
type: landing
audience: app-user
summary: VT Resistance estimates cathodic and anodic steady resistance from a biphasic voltage transient and reports the mean of their absolute values.
```

VT Resistance estimates cathodic and anodic steady resistance from a biphasic voltage transient and reports the mean of their absolute values.

CSV export writes the current resistance result table with its declared column names and units; it does not maintain a separate export-only result model.

## Requirements And Launch

The app requires a chrono DTA curve with valid time, voltage, and current columns.

```matlab
labkit_VTResistance_app
```

## Inputs And Batch Behavior

The Files list accepts chrono `.DTA` transients and omits other Gamry experiment kinds. Changing a shared analysis setting updates the whole batch after the edit commits. No electrode-area normalization is performed because the reported quantity is electrical resistance in ohms.

## Basic Workflow

1. Add files and select a representative transient.
2. Choose pulse detection, steady-window policy, and voltage definition.
3. Inspect detected phase windows and current/voltage traces.
4. Review cathodic, anodic, and average resistance.
5. Export the batch result CSV.

## Calculation Semantics

After finite-sample filtering and pulse detection, the app calculates median current and voltage in the chosen cathodic and anodic steady windows. The cathodic baseline is the median pre-pulse voltage and the anodic baseline is the median post-pulse voltage, with explicit finite fallbacks.

Baseline-corrected mode uses:

```text
R_cath = (V_cath,steady - V_cath,baseline) / I_cath,steady
R_anod = (V_anod,steady - V_anod,baseline) / I_anod,steady
R_average = mean(abs(R_cath), abs(R_anod))
```

Raw mode replaces each voltage difference with its steady absolute voltage. Division by a missing, non-finite, or effectively zero current returns `NaN`; the app does not invent a finite resistance.

## Analysis Parameters

| Parameter | Default | Alternatives |
| --- | --- | --- |
| Pulse detection | Metadata first, then auto | Metadata only; Auto from Im only |
| Steady window | Full pulse median | Center 60% median |
| Resistance voltage | Baseline-corrected dV/I | Raw Vf/I |

The center-60% policy uses the interval from 20% to 80% of each detected phase to reduce onset and offset transients. Plot marker and shading choices affect display only.

## Output Schema

The CSV contains source identity, steady currents and voltages, baseline voltages and windows, raw and baseline-corrected resistance fields, selected resistance values, absolute cathodic/anodic resistance, average resistance, pulse-detection method, and status.

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
- The result is a transient-derived estimate and does not replace an impedance model or compensate wiring/contact resistance automatically.

## Related Topics

- [Electrochemistry family](../README.md)
- [CIC](../cic/README.md)
- [DTA Library](../../../../develop/libraries/dta/README.md)
- [API Reference](../../../../reference/README.md)
