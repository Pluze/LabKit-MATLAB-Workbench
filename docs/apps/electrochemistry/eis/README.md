# EIS

EIS overlays impedance data from one or more Gamry `ZCURVE` tables, supports
Nyquist and Bode-style axis combinations, and exports the values currently
selected for plotting.

## Requirements And Launch

```matlab
labkit_EIS_app
```

## Inputs

Add one or more `.DTA` files containing a readable EIS `ZCURVE`. Files that do
not contain the required curve are reported and omitted from the plot. The
successfully decoded source list and its order are preserved in project state
through portable references.

## Basic Workflow

1. Add the EIS DTA files.
2. Choose X and Y quantities.
3. Enable logarithmic X or Y scaling only for strictly positive plotted data.
4. Use **Fit X/Y limits** to re-estimate independent limits from the current
   data, or **Use equal X/Y scale** when equal data units are wanted.
5. Adjust marker, line, grid, and legend presentation.
6. Export the current plot data CSV.

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

The app never infers an equal aspect ratio from the selected quantities: a
Nyquist plot starts with independently fitted limits. Use **Use equal X/Y
scale** only when equal data units are useful for the current comparison. Use
**Fit X/Y limits** to return to independent limits after equal scaling or a
manual zoom. Equal scaling expands a fitted limit when necessary so X and Y
data units have the same on-screen length; it is a one-time reset and does not
constrain later wheel zooming. Axis and styling changes preserve the current
source set and the current viewport; the two view buttons explicitly replace
that viewport.

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
- [API Reference](../../../reference/README.md)
