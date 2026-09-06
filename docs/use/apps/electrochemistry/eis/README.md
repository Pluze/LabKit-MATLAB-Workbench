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
2. Inspect the default **Nyquist + Bode** page: Nyquist above, magnitude and phase below. Open **Custom plot** for independently chosen X and Y quantities.
3. Choose **mΩ**, **Ω**, **kΩ**, or **MΩ** for impedance axes. New projects default to **kΩ**.
4. Enable logarithmic X or Y scaling only for strictly positive plotted data.
5. Use **Fit X/Y limits** to re-estimate independent limits from the current data, or **Use equal X/Y scale** when equal data units are wanted.
6. Adjust marker, line, grid, and legend presentation.
7. Use **Export custom plot CSV** to export the chosen custom X/Y data.

## Simultaneous Nyquist And Bode Views

The overview shows `Zreal` versus `-Zimag` with equal data units, magnitude versus frequency with logarithmic X/Y axes, and phase versus frequency with logarithmic X and linear Y. All views retain each file's original sample order and frequency grid. Units, marker/line styling, grid, and legend are shared with the custom plot. Custom X/Y choices, log controls, and the two manual fit buttons apply only to **Custom plot**.

Nonfinite values and nonpositive log coordinates break the corresponding plotted line; the App does not join across these missing points. Each Bode view validates its own coordinates, so an invalid magnitude does not hide an otherwise valid phase. No resampling, same-frequency pairing, equivalent-circuit fit, or area normalization is implied by the overlay. Source or unit changes fit a new overview; style changes preserve zoom.

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

The custom plot never infers an equal aspect ratio from the selected quantities: its initial Nyquist choice starts with independently fitted limits. Use **Use equal X/Y scale** only when equal data units are useful for the current comparison. Use **Fit X/Y limits** to return to independent limits after equal scaling or a manual zoom. Equal scaling expands a fitted limit when necessary so X and Y data units have the same on-screen length; it is a one-time reset and does not constrain later wheel zooming. Adding or removing source curves, selecting X/Y quantities, changing impedance units, or changing linear/log scale refits the new coordinate domain. Marker size, line width, marker visibility, legend, and grid changes preserve the current viewport. The two view buttons explicitly replace that viewport.

## Output

**Export custom plot CSV** writes the selected X/Y values for each valid file on a shared row index. Each file retains its own X and Y pair, so unequal curve lengths do not imply interpolation. Impedance columns use the selected display unit and include an ASCII unit suffix such as `kohm` in the column name. Column names are sanitized and shortened to MATLAB's supported length; collisions receive numeric suffixes in source order so every curve retains its own columns.

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

- Nonpositive log coordinates and nonfinite values appear as plot gaps. The custom CSV omits an X/Y pair when either coordinate is nonfinite or nonpositive on its selected logarithmic axis. It then pads shorter curves with `NaN`; row indices do not preserve the original sample positions or align samples between files.
- Overlaying files does not normalize electrode area or fixture geometry.
- Changing the impedance display unit rescales impedance axes and exported impedance columns; it does not alter the DTA values stored in base ohms.
- Axis labels describe parsed DTA columns; they do not validate the experiment configuration recorded by the instrument.

## Related Topics

- [Electrochemistry family](../README.md)
- [DTA Library](../../../../develop/libraries/dta/README.md)
- [API Reference](../../../../reference/README.md)
