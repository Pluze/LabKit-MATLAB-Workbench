# Electrochemistry Apps

```labkit-page
id: apps-electrochemistry
type: landing
audience: app-user
summary: Choose a workflow for analyzing, plotting, and exporting supported Gamry DTA experiments without modifying the source files.
```

The Electrochemistry family reads Gamry DTA files through `labkit.dta` and keeps experiment-specific analysis, plotting, defaults, and export schemas in the owning app. Source DTA files are never modified.

## Choose An App

| Measurement or task | App | Required DTA content | Main result |
| --- | --- | --- | --- |
| Compare voltage and current transients across files | [Chrono Overlay](chrono-overlay/README.md) | chrono curve with `T`, `Vf`, `Im` | aligned overlay and wide CSV |
| Charge-injection capacity and polarization voltage | [CIC](cic/README.md) | biphasic chrono transient | per-file CIC, charge, and voltage metrics |
| Charge-storage capacity by time and CV integration | [CSC](csc/README.md) | CV/CT cycles with `T`, `Vf`, `Im` | per-cycle CT/CV CSC comparison |
| Impedance inspection and export | [EIS](eis/README.md) | `ZCURVE` | configurable Nyquist/Bode-style overlay |
| Steady pulse resistance | [VT Resistance](vt-resistance/README.md) | biphasic chrono transient | cathodic, anodic, and mean resistance |

## Supported DTA Data

Each App checks for the measurements it needs, including their units, before running a calculation. A plotted label is not used to guess a missing physical quantity. See the individual App manual for its required experiment type and columns.

## Units And Traceability

Time is seconds, voltage is volts, current is amperes, impedance is ohms, charge is coulombs, electrode area is square centimetres, and normalized CIC or CSC is reported in the unit shown by the app. UI display conversions do not change stored base-unit calculations.

Export tables include the source identity and analysis settings needed to interpret the result.

## Use Without The GUI

Reusable parsing and curve access live in `labkit.dta`. App-specific numeric operations such as `cic.analysisRun.computeCIC`, `csc.analysisRun.computeCSC`, and `vt_resistance.analysisRun.computeResistance` are documented on the owning app page and in the generated API reference.

## Related Modules

- [DTA Library](../../develop/libraries/dta/README.md)
- [API Reference](../../reference/README.md)
- [All Apps](../README.md)
