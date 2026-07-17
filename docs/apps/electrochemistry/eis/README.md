# EIS

EIS overlays impedance data from one or more Gamry `ZCURVE` tables, supports
Nyquist and Bode-style axis combinations, and exports the values currently
selected for plotting.

## Requirements And Launch

The app uses the LabKit UI framework and DTA library.

```matlab
labkit_EIS_app
```

## Inputs

Add one or more `.DTA` files containing a readable EIS `ZCURVE`. Files that do
not contain the required curve are reported and omitted from the plot. The
source list is preserved in project state through portable references. Runtime
V2 reconciles those records with the successfully decoded file list, preserves
the identity of files that remain loaded, and assigns unique identities to new
files; EIS does not maintain its own source-ID counter.

## Basic Workflow

1. Add the EIS DTA files.
2. Choose X and Y quantities.
3. Enable logarithmic X or Y scaling only for strictly positive plotted data.
4. Adjust marker, line, grid, and legend presentation.
5. Export the current plot data CSV.

## Axis Quantities

The available quantities are frequency, log10 frequency, time, point number,
real impedance, imaginary impedance, negative imaginary impedance, impedance
magnitude, phase, DC current, and DC voltage. Default axes are
`Zreal (ohm)` and `-Zimag (ohm)`.

Use `Zreal` versus `-Zimag` for the conventional Nyquist orientation. Use
frequency versus magnitude or phase for Bode-style views. The log-axis
checkbox changes MATLAB axes scaling; choosing `log10(Freq)` changes the data
coordinate itself. Do not apply both transformations unless that is explicitly
intended.

## Plot Parameters

| Parameter | Default |
| --- | ---: |
| Line width | 1.4 |
| Marker size | 6 |
| Show markers | on |
| Log X / Log Y | off / off |
| Legend / Grid | on / on |

Axis and styling changes preserve the current source set. The plot refits when
the selected data quantities change; ordinary interaction zoom is otherwise
owned by the App Framework.

## Output

**Export current plot CSV** writes the selected X/Y values for each valid file
on a shared row index. Each file retains its own X and Y pair, so unequal curve
lengths do not imply interpolation. A result manifest records the selected
axes, plot parameters, source references, and output role.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("spectrum.DTA", "eis");
assert(status.ok, status.message);
curve = labkit.dta.getZCurve(item);
x = eis.analysisRun.valuesForAxis(curve, "Zreal (ohm)");
y = eis.analysisRun.valuesForAxis(curve, "-Zimag (ohm)");
plot(x, y, "o-");
axis equal
```

`valuesForAxis` is app-owned and not currently part of the published app API
catalog. The DTA loader and `getZCurve` are supported reusable APIs.

## Errors And Limitations

- Log axes omit or reject nonpositive coordinates according to MATLAB axes
  behavior; inspect the data rather than treating missing points as zero.
- Overlaying files does not normalize electrode area or fixture geometry.
- Axis labels describe parsed DTA columns; they do not validate the experiment
  configuration recorded by the instrument.

## Related Topics

- [Electrochemistry family](../README.md)
- [DTA Library](../../../libraries/dta/README.md)
- [API Reference](../../../libraries/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata, requirements, layout, and
optional runtime capabilities. `projectSpec.m` owns the complete version-1
domain schema, defaults, and plot-parameter validation; Runtime validates
canonical buckets and source records first. `createSession.m` rebuilds decoded
ZCURVE items and selected paths because they are transient runtime data. Empty
workflow and view buckets are supplied by Runtime V2 rather than repeated in
the App factory. The App requires `labkit.ui >=7 <8` and
`labkit.dta >=2 <3`; busy-state, viewport-preserving rendering, resolved-path
access, and portable-reference serialization remain framework-owned.
