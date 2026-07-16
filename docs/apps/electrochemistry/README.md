# Electrochemistry Apps

The electrochemistry family reads Gamry DTA recordings through `labkit.dta`
and keeps scientific calculations in app-owned, GUI-free functions.

## Choose An App

| Measurement | App |
| --- | --- |
| Overlay chrono voltage/current traces | [Chrono Overlay](chrono-overlay/README.md) |
| Charge-injection capacity and voltage transient limits | [CIC](cic/README.md) |
| Charge-storage capacity from CV and time integration | [CSC](csc/README.md) |
| Impedance curves and tabular export | [EIS](eis/README.md) |
| Steady resistance from pulse transients | [VT Resistance](vt-resistance/README.md) |

## Shared Data Model

`labkit.dta.loadFile` and related functions decode a DTA file into an item
struct with typed curves and status information. Apps own batch selection,
analysis options, tables, plots, and exports. CIC and VT decode only the active
file during interactive review and defer the rest of a large batch until
needed for export.

## Scientific Traceability

Exports retain the settings that affect normalization or sampling, including
electrode area, delay, scan rate, cycle choice, and source identity where
applicable. Invalid sampling ranges fail explicitly instead of extrapolating.

## Programmatic Entry Points

Use `labkit.dta.*` to inspect recordings without a GUI. Cataloged app APIs such
as `cic.analysisRun.computeCIC`, `csc.analysisRun.computeCSC`, and
`vt_resistance.analysisRun.computeResistance` reproduce the app calculations
from decoded data and option structs.

## Related Libraries

- [DTA Library](../../libraries/dta/README.md)
- [Contracts](../../libraries/contracts/README.md)
