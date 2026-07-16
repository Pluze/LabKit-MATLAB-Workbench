# CSC

CSC compares charge-storage capacity calculated by time integration and by
cyclic-voltammetry integration across one or more CV/CT DTA files.

## Launch

```matlab
labkit_CSC_app
```

## Inputs

Load Gamry CV/CT DTA files. Each file may contain multiple curves/cycles. The
active file controls the curve selector, plots, and comparison readout.

## Workflow

1. Add CV/CT files and select the active source.
2. Review all cycles or select one cycle.
3. Set scan rate, electrode area, comparison mode, and optional edge-cycle
   exclusions.
4. Inspect time/current and voltage/current plots.
5. Export all-cycle CSC results or column-oriented CV data.

## Scientific Semantics

Time-domain charge integrates current against time. CV charge integrates
current against potential and divides by positive scan rate. Cathodic, anodic,
and full-cycle modes select corresponding signed/absolute components before
normalization by electrode area.

Ignoring the first or last cycle affects plots, result tables, and both export
paths consistently. Time plots align each cycle to its own initial time.

## Outputs

- one row per exported file cycle with CT/CV cathodic, anodic, and full charge
  and CSC fields;
- column-oriented CV data for replotting and independent calculation;
- one CSV per item when voltage vectors differ across files.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("cv.DTA", "cvct");
assert(status.ok, status.message);
curve = item.curves(1);
opts = struct("scanRate", 0.05, "area_cm2", 0.05, "mode", "Full");
result = csc.analysisRun.computeCSC(curve, opts);
assert(result.ok, result.message);
```

Use the API page for the exact mode strings provided by
`csc.userInterface.analysisChoices` and the full result schema.

## See Also

- `csc.analysisRun.computeCSC`
- `csc.analysisRun.chargeDensity`
- [DTA Library](../../../libraries/dta/README.md)
