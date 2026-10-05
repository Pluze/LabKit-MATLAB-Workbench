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
2. Inspect the default **Nyquist + Bode** page: Nyquist above, magnitude and phase below. Use **Fit all X/Y limits** to restore their ranges after zooming. Open **Custom plot** for independently chosen X and Y quantities.
3. Choose **mΩ**, **Ω**, **kΩ**, or **MΩ** for impedance axes. New projects default to **kΩ**.
4. Enable logarithmic X or Y scaling only for strictly positive plotted data.
5. Use **Fit X/Y limits** to re-estimate independent limits from the current data, or **Use equal X/Y scale** when equal data units are wanted.
6. Adjust marker, line, grid, and legend presentation.
7. Use **Export custom plot CSV** to export the chosen custom X/Y data.

## Simultaneous Nyquist And Bode Views

The overview shows `Zreal` versus `-Zimag` with equal data units, magnitude versus frequency with logarithmic X and linear Y, and phase versus frequency with logarithmic X and linear Y. With grouping disabled, all views retain each file's original sample order and frequency grid. Units, marker/line styling, grid, and legend are shared with the custom plot. **Fit all X/Y limits** refits all three overview plots together and restores equal data units on Nyquist. Custom X/Y choices, log controls, and the two manual fit buttons apply only to **Custom plot**.

Nonfinite values and nonpositive log coordinates break the corresponding plotted line; the App does not join across these missing points. Each Bode view validates its own coordinates, so an invalid magnitude does not hide an otherwise valid phase. Raw overlays do not resample or pair frequencies. Neither mode performs equivalent-circuit fitting or area normalization. Source or unit changes fit a new overview; style changes preserve zoom.

## Manual Groups For Repeated Scans

Open the **Groups** page to manage repeated scans. **Enable group mean ± SD** starts off. When enabled, the App asks whether to **Auto-group files** or **Group manually**; **Cancel** leaves grouping disabled. The Files list remains on the left while the group manager shows controls, group scan counts, and every imported file's assignment on the right.

Automatic recognition removes only the final `-digits` suffix from the filename stem: `Sample-A-1.DTA`, `Sample-A-2.DTA`, and `Sample-A-3.DTA` become **Sample-A**. Prefixes must match exactly, including case. Earlier hyphens remain part of the sample name, and files without a final numeric suffix remain unassigned. A single matching scan may form a group with no SD. Automatic names are suggestions: check that the files actually represent the same sample and conditions. Incompatible frequency groups are skipped with a message and remain available for manual review.

For manual setup, enter **New group name** and click **Add group**. Choose the **Target group**, select one or several files in the left Files list, and click **Assign selected files**. Files move into that group, so each scan has at most one membership. **Unassign selected files** releases scans without deleting them. **Delete group** removes the target group and releases all its members, while keeping every imported file. Empty groups stay available until explicitly deleted. For three sample types with three scans each, create three groups and assign each three-file selection, or accept automatic recognition and review the three counts.

**Auto-group unassigned** recognizes newly imported or unassigned files without moving any existing members. Re-enabling grouping offers the same choice and preserves manual assignments. Turning grouping off restores raw file overlays; groups remain available for the current session. Removing an imported file also removes its membership. In group mode both plot pages show assigned, nonempty groups only; unassigned files are counted in the panel and excluded from statistics.

Each scan must contain the same set of unique, finite, positive frequencies. Row order may differ: the App pairs by exact recorded frequency and retains the first member's order. A differing frequency set blocks the assignment with an explanation, leaving existing groups intact. No tolerance matching, interpolation, extrapolation, or averaging by row index is performed. This avoids silently combining different frequencies; differing scan protocols need a separately justified alignment procedure.

At each frequency the chosen X/Y quantities are taken from each scan in the selected units. Only scans with both coordinates finite contribute to that pair. Each contributing scan has equal weight. Ordinary quantities use the arithmetic mean and sample standard deviation, `sqrt(sum((value - mean).^2)/(N - 1))`. Magnitude is the mean of the recorded per-scan magnitudes, not the magnitude of mean complex impedance. Phase uses a circular mean from the mean sine and cosine; its SD uses shortest angular deviations about that mean. Opposing phase directions with no numerically defined resultant appear as gaps. These are descriptive repeat-scan statistics, not independent-specimen inference or confidence intervals.

Nyquist and custom plots show horizontal and vertical ±1 SD bars; the Bode frequency SD is zero because frequencies are paired exactly. A single contributing scan has a mean but no SD bar (`NaN` SD in export); zero contributing scans produce a gap. The valid count may differ across frequencies and quantities. Nonpositive means on logarithmic axes are hidden; a lower SD arm reaching zero or below is omitted, without changing the exported SD. Group membership or mode changes refit the plots; styling preserves zoom.

## Axis Quantities

The available quantities are frequency, log10 frequency, time, point number, real impedance, imaginary impedance, negative imaginary impedance, impedance magnitude, phase, DC current, and DC voltage. Default axes are `Zreal` and `-Zimag`, displayed in kΩ for a new project.

Use `Zreal` versus `-Zimag` for the conventional Nyquist orientation. Use frequency versus magnitude or phase for Bode-style views. The log-axis checkbox changes MATLAB axes scaling; choosing `log10(Freq)` changes the data coordinate itself. Do not apply both transformations unless that is explicitly intended.

## Plot Parameters

| Parameter | Default |
| --- | ---: |
| Group mode | off |
| Impedance unit | kΩ |
| Line width | 1.4 |
| Marker size | 6 |
| Show markers | on |
| Log X / Log Y | off / off |
| Legend / Grid | on / on |

The custom plot never infers an equal aspect ratio from the selected quantities: its initial Nyquist choice starts with independently fitted limits. Use **Use equal X/Y scale** only when equal data units are useful for the current comparison. Use **Fit X/Y limits** to return to independent limits after equal scaling or a manual zoom. Equal scaling expands a fitted limit when necessary so X and Y data units have the same on-screen length; it is a one-time reset and does not constrain later wheel zooming. Adding or removing source curves, selecting X/Y quantities, changing impedance units, or changing linear/log scale refits the new coordinate domain. Marker size, line width, marker visibility, legend, and grid changes preserve the current viewport. The two view buttons explicitly replace that viewport.

## Output

With grouping disabled, **Export custom plot CSV** writes the selected X/Y values for each selected valid file on a shared row index. Each file retains its own X and Y pair, so unequal curve lengths do not imply interpolation. Impedance columns use the selected display unit and include an ASCII unit suffix such as `kohm` in the column name. Column names are sanitized and shortened to MATLAB's supported length; collisions receive numeric suffixes in source order so every curve retains its own columns.

With grouping enabled, the same export action writes all assigned groups, independent of the current file selection. Each row contains `Group`, `Frequency_Hz`, paired valid count `N`, `XQuantity`, `XMean`, `XSD`, `YQuantity`, `YMean`, `YSD`, and `Visible`. Quantity labels specify the selected axes and impedance units. Invalid and log-hidden rows remain in the CSV with their counts and `Visible=false`, so absence from a plot does not conceal missing data. SD is always sample SD and remains in the corresponding coordinate's units.

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

- Nonpositive log coordinates and nonfinite values appear as plot gaps. With grouping disabled, the custom CSV omits an X/Y pair when either coordinate is nonfinite or nonpositive on its selected logarithmic axis. It then pads shorter curves with `NaN`; row indices do not preserve the original sample positions or align samples between files.
- Overlaying files does not normalize electrode area or fixture geometry.
- Changing the impedance display unit rescales impedance axes and exported impedance columns; it does not alter the DTA values stored in base ohms.
- Axis labels describe parsed DTA columns; they do not validate the experiment configuration recorded by the instrument.

## Related Topics

- [Electrochemistry family](../README.md)
- [DTA Library](../../../../develop/libraries/dta/README.md)
- [API Reference](../../../../reference/README.md)
