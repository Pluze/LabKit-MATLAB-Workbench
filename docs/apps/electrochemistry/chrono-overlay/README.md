# Chrono Overlay

Chrono Overlay compares voltage and current traces from one or more Gamry
chrono DTA recordings.

## Launch

```matlab
labkit_ChronoOverlay_app
```

## Inputs

Select one or more chrono DTA files from a single folder, or add a folder of
supported files. Files are decoded through `labkit.dta` and remain unchanged.

## Workflow

1. Add DTA files.
2. Select the active file for detailed inspection.
3. Choose voltage/current display and overlay settings.
4. Compare traces and pulse timing.
5. Export plot data or CSV output.

The file panel selection controls the current preview. Shared display settings
apply to the batch overlay without repeatedly asking for confirmation.

## Outputs

- overlay plots;
- CSV tables suitable for independent plotting;
- project state containing selected sources and display choices.

## Use Without The GUI

```matlab
[items, statuses] = labkit.dta.loadFiles(paths, "chrono");
curve = labkit.dta.getMainCurve(items(1).tables);
t = labkit.dta.getColumn(curve, "T");
voltage = labkit.dta.getColumn(curve, "Vf");
current = labkit.dta.getColumn(curve, "Im");
plot(t, voltage);
```

## See Also

- [DTA Library](../../../libraries/dta/README.md)
- [CIC](../cic/README.md)
- [VT Resistance](../vt-resistance/README.md)
