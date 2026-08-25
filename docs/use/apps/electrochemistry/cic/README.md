# Charge-Injection Capacity

```labkit-page
id: app-cic
type: landing
audience: app-user
summary: Measure biphasic-pulse charge density and voltage-transient polarization metrics from supported Gamry DTA recordings.
```

The CIC app measures charge delivered by a biphasic current pulse, normalizes charge by electrode area, and reports voltage-transient polarization metrics at a controlled delay after each pulse phase.

Each selected DTA source is loaded into the current analysis state, and charge-density text is formatted from that same result so display and export cannot diverge through a second cached representation.

## Requirements And Launch

The app requires a chrono DTA curve with valid `T`, `Vf`, and `Im` columns.

```matlab
labkit_CIC_app
```

## Inputs And Batch Behavior

The Files list accepts chrono `.DTA` transients and omits other Gamry experiment kinds. Selecting a row updates the preview. Export applies the current analysis settings to every accepted file in the displayed order.

Electrode area comes from a positive UI override when supplied, otherwise from the parsed DTA metadata. Without a valid positive area, charge in coulombs can still be calculated but area-normalized CIC fields are `NaN`.

## Basic Workflow

1. Add chrono DTA files and select a representative file.
2. Choose a water-window preset or set custom cathodic/anodic limits.
3. Choose pulse detection, post-pulse delay, electrode area, phase mode, and output unit.
4. Inspect detected phases, sampling markers, and voltage/current plots.
5. Review the current-file summary.
6. Export the batch result CSV.

## Calculation Semantics

The app removes samples where time, voltage, or current is not finite and requires at least five valid points. `labkit.dta.detectPulses` identifies the cathodic phase, interpulse gap, anodic phase, and surrounding baseline windows.

Measured-current mode integrates each detected current phase over time. The phase charges `Qc_C` and `Qa_C` are positive magnitudes; total charge is their sum. With area `A` in cm^2:

```text
CIC_mC_cm2 = 1000 * Q_C / A_cm2
```

Maximum cathodic and anodic polarization potentials are interpolated at `phase end + delay`. The app does not extrapolate: if either requested time is outside the recorded range, that file fails with an explicit delay message. Baseline candidates are selected from pre-pulse, interpulse, and post-pulse windows. The exported result identifies the baseline used.

Water-window status compares the calculated polarization potentials with the selected cathodic and anodic limits. The limits are an app policy and do not change the integrated charge.

## Analysis Parameters

| Parameter | Default | Legal choices or unit |
| --- | ---: | --- |
| Preset | Pt (-0.6 to 0.8 V) | Pt, PEDOT:PSS, or Custom |
| Cathodic / anodic limits | -0.6 / 0.8 | volts |
| Delay | 10 | microseconds after each phase end |
| Pulse detection | Metadata first, then auto | metadata fallback, metadata only, or current-only auto |
| CIC phase | Total biphasic | Cathodic phase, Anodic phase, Total biphasic |
| CIC unit | mC/cm^2 | mC/cm^2 or uC/cm^2 |
| Use measured current | on | integrate measured `Im`; otherwise use detected pulse estimates |

Plot markers, limit lines, shading, axes, and grid choices affect presentation only. Analysis controls apply to the entire exported batch after each committed edit.

## Output Schema

The batch CSV contains source identity, area, delay, pulse-detection method, phase timing, measured/estimated current information, charge fields, area-normalized CIC fields, polarization and baseline values, water-window status, and a per-file result message. `Area_cm2` and `Delay_us` are exported so normalization and sample timing remain auditable.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("pulse.DTA", "chrono");
assert(status.ok, status.message);

options = struct( ...
    "delay_s", 10e-6, ...
    "cathLimit", -0.6, ...
    "anodLimit", 0.8, ...
    "area_cm2", 0.05, ...
    "pulseMode", "Metadata first, then auto", ...
    "usedMeasuredCurrent", true);
result = cic.analysisRun.computeCIC(item, options);
assert(result.ok, result.message);
```

## Errors And Limitations

- Missing `T`, `Vf`, or `Im`, fewer than five valid samples, or failed pulse detection returns `ok=false` with a message.
- A delay outside the recorded time range fails instead of extrapolating.
- Area-normalized values require a positive area; invalid area is not replaced by an arbitrary default.
- CIC results depend on pulse detection, baseline selection, sampling rate, electrode area, and whether measured or estimated current is used.

## Related Topics

- [Electrochemistry family](../README.md)
- [DTA pulse detection](../../../../develop/libraries/dta/README.md)
- [VT Resistance](../vt-resistance/README.md)
- [API Reference](../../../../reference/README.md)
