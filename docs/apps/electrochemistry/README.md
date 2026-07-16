# Electrochemistry Apps

The Electrochemistry family reads Gamry DTA files through `labkit.dta` and
keeps experiment-specific analysis, plotting, defaults, and export schemas in
the owning app. Source DTA files are never modified.

## Choose An App

| Measurement or task | App | Required DTA content | Main result |
| --- | --- | --- | --- |
| Compare voltage and current transients across files | [Chrono Overlay](chrono-overlay/README.md) | chrono curve with `T`, `Vf`, `Im` | aligned overlay and wide CSV |
| Charge-injection capacity and polarization voltage | [CIC](cic/README.md) | biphasic chrono transient | per-file CIC, charge, and voltage metrics |
| Charge-storage capacity by time and CV integration | [CSC](csc/README.md) | CV/CT cycles with `T`, `Vf`, `Im` | per-cycle CT/CV CSC comparison |
| Impedance inspection and export | [EIS](eis/README.md) | `ZCURVE` | configurable Nyquist/Bode-style overlay |
| Steady pulse resistance | [VT Resistance](vt-resistance/README.md) | biphasic chrono transient | cathodic, anodic, and mean resistance |

## Shared File Behavior

File controls accept one or more `.DTA` files from one folder in a single
selection. A canceled chooser leaves the current project unchanged. CIC, CSC,
and VT Resistance use the selected row as the active preview while retaining
the loaded source list for batch export. Invalid items are reported per file;
one failed item does not silently replace another result.

The DTA library returns structured items, curve tables, headers, units,
metadata, parser messages, and status. Apps use exact required columns for
scientific calculations and do not infer missing physical quantities from a
plot label.

## Units And Traceability

Time is seconds, voltage is volts, current is amperes, impedance is ohms,
charge is coulombs, electrode area is square centimetres, and normalized CIC
or CSC is reported in the unit shown by the app. UI display conversions do not
change stored base-unit calculations.

Export tables include the source identity and analysis settings needed to
interpret the result. Runtime-generated `.labkit.json` files are provenance
manifests describing inputs, parameters, and output roles; they are not a
second numerical result and can be kept with the corresponding CSV.

## Use Without The GUI

Reusable parsing and curve access live in `labkit.dta`. App-specific numeric
operations such as `cic.analysisRun.computeCIC`,
`csc.analysisRun.computeCSC`, and
`vt_resistance.analysisRun.computeResistance` are documented on the owning app
page and in the generated API reference.

## Related Modules

- [DTA Library](../../libraries/dta/README.md)
- [API Reference](../../libraries/README.md)
- [All Apps](../README.md)
