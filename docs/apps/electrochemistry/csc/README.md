# Charge-Storage Capacity

The CSC app compares charge obtained from time-domain current integration with
charge obtained from cyclic-voltammetry integration for every readable CV/CT
cycle in one or more Gamry DTA files.

## Requirements And Launch

Each analyzed cycle must expose exact `T`, `Vf`, and `Im` columns and a
positive scan rate.

```matlab
labkit_CSC_app
```

## Inputs And Selection

The Files list accepts CV/CT `.DTA` sources and omits other Gamry experiment
kinds. The selected file determines the current
curve list, readout, and plots. Selecting another file resets the curve
selection and default plot quantities to that file; it does not silently keep
a cycle from the previous source.

The default curve selection is **All cycles**. Individual cycle selection
updates the comparison readout for that cycle.

## Basic Workflow

1. Add CV/CT files and select the active source.
2. Inspect all cycles for incomplete or anomalous edge cycles.
3. Choose Full, Cathodic, or Anodic comparison mode.
4. Enter electrode area when area-normalized CSC is required.
5. Optionally ignore the first and last cycle.
6. Configure the two plot panes and review CT/CV agreement.
7. Export all-cycle results and, when needed, column-oriented CV data.

## Plot Behavior

All-cycle plots use a distinct color for each cycle; cathodic and anodic
current branches use related dark/light variants. Time is shifted so each
cycle begins at zero. Selecting new X/Y quantities refits the axes. Toggling
trim overlays preserves the user's current view because it changes an overlay,
not the underlying coordinate selection.

**Ignore first/last cycle** applies consistently to the all-cycle plot, result
table, CSC export, and CV-data export. It is intended for known incomplete edge
cycles and must not be used to hide arbitrary outliers.

## Calculation Semantics

Time-domain charge integrates current against time. CV-domain charge integrates
current against potential and divides by positive scan rate. Each line segment
is split at a current zero crossing so cathodic and anodic contributions are
assigned without smearing a sign change across one trapezoid.

```text
Q_CT,cath = integral |I(t)| dt over cathodic current
Q_CT,anod = integral I(t) dt over anodic current
Q_CV      = integral I(V) dV / scanRate, split by current sign
CSC       = 1000 * Q_C / area_cm2
```

Full mode sums positive cathodic and anodic charge magnitudes. Relative
difference is `100 * abs(Q_CT - Q_CV) / max(abs(Q_CT), abs(Q_CV))`, with zero
reported when both charges are zero. `dtErr` reports the maximum discrepancy
between measured time increments and `abs(dV)/scanRate` over valid segments.

Without a valid positive area, charge comparison remains available but CSC
fields in mC/cm^2 are `NaN`.

## Outputs

**Export all cycles CSV** writes one row per included file cycle with source,
cycle, mode, scan rate, area, CT and CV cathodic/anodic/full charges, selected
charge and CSC values, absolute/relative difference, time-step consistency,
and status fields.

**Export CV data CSV** writes potential plus paired current and scan-rate
columns for replotting and independent calculation. When all exported cycles
share the same potential vector, they occupy one file. When vectors differ,
the app writes one CSV per source item using the selected filename as a stem.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("cv.DTA", "cvct");
assert(status.ok, status.message);
curve = item.curves(1);

options = struct("scanRate", 0.05, ...
    "area_cm2", 0.05, "mode", "Full");
result = csc.analysisRun.computeCSC(curve, options);
assert(result.ok, result.message);
```

## Function Reference

The generated pages for
[`computeCSC`](../../../reference/api/csc/analysisRun/computeCSC.html) and
[`chargeDensity`](../../../reference/api/csc/analysisRun/chargeDensity.html)
state the exact numeric inputs, units, sign conventions, outputs, invalid-area
behavior, executable examples, and related APIs used outside the GUI.

## Errors And Limitations

- Scan rate must be finite and positive.
- Required column names are exact; a visually similar arbitrary table is not
  accepted as a CV/CT cycle.
- Area normalization is omitted rather than guessed when area is invalid.
- Agreement between CT and CV integration is a consistency measurement, not
  proof that the electrochemical experiment is otherwise valid.

## Related Topics

- [Electrochemistry family](../README.md)
- [DTA Library](../../../libraries/dta/README.md)
- [API Reference](../../../reference/README.md)
