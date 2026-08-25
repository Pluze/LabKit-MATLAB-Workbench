# EIS

```labkit-page
id: app-eis
type: landing
audience: app-user
summary: EIS overlays impedance data from one or more Gamry ZCURVE tables, supports Nyquist and Bode-style axis combinations, and exports the values currently selected for plotting.
```

EIS overlays impedance data from one or more Gamry `ZCURVE` tables, supports Nyquist and Bode-style axis combinations, and exports the values currently selected for plotting.

Source summaries are derived from the currently parsed EIS recording, so file selection, plots, and exported values refer to the same loaded result.

## Requirements And Launch

```matlab
labkit_EIS_app
```

## Inputs

The Files list retains `.DTA` sources containing a readable EIS `ZCURVE`. Other Gamry experiment kinds and files without the required curve are omitted before plotting.

## Basic Workflow

1. Add the EIS DTA files.
2. Choose X and Y quantities.
3. Choose **mΩ**, **Ω**, **kΩ**, or **MΩ** for impedance axes. New projects default to **kΩ**.
4. Enable logarithmic X or Y scaling only for strictly positive plotted data.
5. Use **Fit X/Y limits** to re-estimate independent limits from the current data, or **Use equal X/Y scale** when equal data units are wanted.
6. Adjust marker, line, grid, and legend presentation.
7. Export the current plot data CSV.

## Axis Quantities

The available quantities are frequency, log10 frequency, time, point number, real impedance, imaginary impedance, negative imaginary impedance, impedance magnitude, phase, DC current, and DC voltage. Default axes are `Zreal` and `-Zimag`, displayed in kΩ for a new project.

Use `Zreal` versus `-Zimag` for the conventional Nyquist orientation. Use frequency versus magnitude or phase for Bode-style views. The log-axis checkbox changes MATLAB axes scaling; choosing `log10(Freq)` changes the data coordinate itself. Do not apply both transformations unless that is explicitly intended.

## Plot Parameters

| Parameter | Default |
| --- | ---: |
| Impedance unit | kΩ |
| Line width | 1.4 |
| Marker size | 6 |
| Show markers | on |
| Log X / Log Y | off / off |
| Legend / Grid | on / on |

The app never infers an equal aspect ratio from the selected quantities: a Nyquist plot starts with independently fitted limits. Use **Use equal X/Y scale** only when equal data units are useful for the current comparison. Use **Fit X/Y limits** to return to independent limits after equal scaling or a manual zoom. Equal scaling expands a fitted limit when necessary so X and Y data units have the same on-screen length; it is a one-time reset and does not constrain later wheel zooming. Adding or removing source curves, selecting X/Y quantities, changing impedance units, or changing linear/log scale refits the new coordinate domain. Marker size, line width, marker visibility, legend, and grid changes preserve the current viewport. The two view buttons explicitly replace that viewport.

## Output

**Export current plot CSV** writes the selected X/Y values for each valid file on a shared row index. Each file retains its own X and Y pair, so unequal curve lengths do not imply interpolation. Impedance columns use the selected display unit and include an ASCII unit suffix such as `kohm` in the column name.

## Use Without The GUI

```matlab
[item, status] = labkit.dta.loadFile("spectrum.DTA", "eis");
assert(status.ok, status.message);
units = eis.impedanceDisplay.catalog();
x = eis.analysisRun.valuesForAxis(item, "Zreal", units.choices(3));
y = eis.analysisRun.valuesForAxis(item, "-Zimag", units.choices(3));
plot(x, y, "o-");
axis equal
```

`valuesForAxis` is app-owned and not currently part of the published app API catalog. The DTA loader and `getZCurve` are supported reusable APIs.

## Errors And Limitations

- Log axes omit or reject nonpositive coordinates according to MATLAB axes behavior; inspect the data rather than treating missing points as zero.
- Overlaying files does not normalize electrode area or fixture geometry.
- Changing the impedance display unit rescales impedance axes and exported impedance columns; it does not alter the DTA values stored in base ohms.
- Axis labels describe parsed DTA columns; they do not validate the experiment configuration recorded by the instrument.

## Related Topics

- [Electrochemistry family](../README.md)
- [DTA Library](../../../../develop/libraries/dta/README.md)
- [API Reference](../../../../reference/README.md)
