# EIS

EIS displays and exports impedance data from Gamry EIS ZCURVE recordings.

## Launch

```matlab
labkit_EIS_app
```

## Inputs

Load one or more EIS DTA files. `labkit.dta.getZCurve` provides frequency,
real/imaginary impedance, magnitude, and phase fields when present.

## Workflow

1. Add EIS files.
2. Select the active file or overlay the batch.
3. Choose axis quantities and linear/log presentation.
4. Zoom or pan for inspection; redraws preserve the chosen viewport unless an
   explicit fit is requested.
5. Export the plotted data to CSV.

## Plot Semantics

Nyquist views conventionally plot real impedance against negative imaginary
impedance. Bode views use frequency with magnitude or phase. Axis choices are
display decisions; exported numeric values retain their decoded quantities and
units.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("impedance.DTA", "eis");
assert(status.ok, status.message);
[curve, curveStatus] = labkit.dta.getZCurve(item);
assert(curveStatus.ok, curveStatus.message);
```

## Troubleshooting

- A missing ZCURVE table is reported as a load/status error.
- Log axes require positive values; use a compatible quantity or linear scale
  when the decoded vector contains zero or negative samples.

## See Also

- [DTA Library](../../../libraries/dta/README.md)
- [Electrochemistry family](../README.md)
