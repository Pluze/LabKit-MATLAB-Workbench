# CIC

CIC measures pulse charge-injection capacity and voltage-transient limits from
Gamry chrono DTA recordings.

## Launch

```matlab
labkit_CIC_app
```

## Inputs And Performance

Add one or more chrono DTA files. The app inventories the batch immediately but
decodes only the selected file for interactive preview. Remaining files are
decoded when selected or when a complete export requires them, so large batches
do not block initial file selection.

## Workflow

1. Add files and select one recording.
2. Review detected cathodic/anodic pulse windows.
3. Set electrode area, post-pulse delay, water-window limits, pulse mode, and
   measured-current policy.
4. Inspect charge and polarization values for the active file.
5. Export the whole batch with the same analysis options.

## Scientific Semantics

The app integrates current over detected cathodic and anodic pulse windows.
Charge density is reported in mC/cm2 using the selected positive electrode
area. The default polarization sample delay is 10 microseconds after each pulse
end. A requested delay outside the recorded time range fails; the app does not
extrapolate voltage.

Cathodic, anodic, and total charge use measured current when that option is
enabled. Water-window status compares maximum cathodic/anodic polarization to
the configured voltage limits.

## Outputs

The batch CSV includes charge, CIC density, voltage-transient values, status,
`Area_cm2`, and `Delay_us` so normalization and sampling remain auditable.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("sample.DTA", "chrono");
assert(status.ok, status.message);
opts = struct("delay_s", 10e-6, "area_cm2", 0.05, ...
    "cathLimit", -0.6, "anodLimit", 0.8, ...
    "usedMeasuredCurrent", true);
result = cic.analysisRun.computeCIC(item, opts);
assert(result.ok, result.message);
```

## Errors And Troubleshooting

- Missing T, Vf, or Im columns prevent analysis.
- Too few valid samples or undetected pulse windows return `ok=false` with a
  message rather than a fabricated result.
- Verify area units are cm2 before comparing density values.

## See Also

- `cic.analysisRun.computeCIC`
- `labkit.dta.detectPulses`
- [VT Resistance](vt-resistance.md)
