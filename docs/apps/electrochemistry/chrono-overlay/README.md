# Chrono Overlay

Chrono Overlay compares voltage and current transients from multiple Gamry DTA
files on a common pulse-centered time axis and exports the aligned curves.

## Requirements And Launch

The app uses the LabKit App SDK and DTA library. Each source must contain a
readable chrono curve with time, voltage, and current data.

```matlab
labkit_ChronoOverlay_app
```

## Inputs

Use **Add DTA files** to select one or more `.DTA` files from one directory.
The app parses each file as chrono data and reports unreadable items. The file
list controls curve order, legend labels, and removal; selection does not
discard other loaded curves. The App runtime owns durable source identities,
portable project references, add/remove/clear behavior, and selection. It
rebuilds the transient decoded session only when the file collection changes.

## Basic Workflow

1. Add the DTA files to compare.
2. Inspect the overlaid voltage and current plots.
3. Choose seconds, milliseconds, or sample number for the X axis.
4. Set line width, legend visibility, and grid visibility.
5. Export the aligned curves CSV.

Plot styling does not alter exported values. Removing a file removes its
curves from both plots and the next export.

## Alignment Algorithm

For each valid transient, the app uses the detected cathodic/anodic blank
interval and defines time zero at its center. If pulse detection or the gap
center is unavailable, it explicitly falls back to the first recorded sample
and reports that fallback in the app log.

If files use different sample times, export constructs a merged aligned-time
axis and interpolates each voltage/current series onto that axis. Missing
coverage remains missing; the app does not extrapolate a transient beyond its
recorded time range.

## Parameters

| Parameter | Default | Effect |
| --- | ---: | --- |
| X axis | Time (s) | plot coordinate only; alternatives are Time (ms) and Sample # |
| Line width | 1.3 | rendered curve width |
| Show file-name legend | on | legend visibility |
| Show grid | on | axes grid visibility |

## Output

**Export curves CSV** writes `TimeGapCenterAligned_s` followed by paired
voltage and current columns for each source. Column names retain a sanitized
source identity. The app also writes a result manifest containing source
references, current parameters, and the CSV output role.

## Use Without The GUI

```matlab
[items, status] = labkit.dta.loadFiles(["run01.DTA", "run02.DTA"], ...
    "chrono");
assert(all([status.ok]), "One or more DTA files could not be read.");

aligned = arrayfun(@(item) ...
    chrono_overlay.sourceFiles.alignByPulseGap(item), items);
tableOut = chrono_overlay.resultFiles.buildOverlayExportTable(aligned);
```

These app-owned helpers expose the workflow to scripts but are not currently
listed as stable public APIs; reusable DTA reading is supported through
`labkit.dta`.

## Errors And Limitations

- A source without a detectable biphasic gap is aligned to its first sample;
  review the log before comparing it with gap-centered files.
- Interpolation enables a common export table but does not make differently
  sampled instruments scientifically identical.
- Compare only experiments whose control mode, scale, and units are compatible.

## Related Topics

- [Electrochemistry family](../README.md)
- [DTA Library](../../../libraries/dta/README.md)
- [CIC](../cic/README.md)
- [VT Resistance](../vt-resistance/README.md)

## Framework Compatibility

`definition.m` returns one validated `labkit.app.Definition`.
`projectSpec.m` returns the current version-2 `labkit.app.project.Schema` plus its
version-aware migration entry. `createSession(project,context)` resolves the
runtime-owned portable sources and rebuilds decoded DTA items because curves
remain transient caches. Layout bindings provide all four plot parameters and
the file collection without App callbacks or presenter duplication. The only
App StateHandler is CSV/result export; one renderer receives the voltage and
current axes in declared order. The App requires `labkit.app >=1 <2` and
`labkit.dta >=2 <3`.
