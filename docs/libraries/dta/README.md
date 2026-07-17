# Gamry DTA Files

[API reference](../README.md) | [Electrochemistry apps](../../apps/electrochemistry/README.md)

The `labkit.dta` functions find and read Gamry DTA files without opening an
app. They recognize chrono, electrochemical impedance spectroscopy (EIS), and
cyclic-voltammetry/charge-time (CV/CT) data, and return ordinary MATLAB
structures and numeric arrays for further analysis.

## Start Here

Use `loadFile` when you know the path to one file:

```matlab
[item, status] = labkit.dta.loadFile("measurement.DTA", "auto");

if ~status.ok
    error("Could not read DTA file: %s", status.message)
end

switch item.type
    case "chrono"
        plot(item.t_s, item.Vf_V)
        xlabel("Time (s)")
        ylabel("Voltage (V)")
    case "eis"
        loglog(item.freq_Hz, item.Zmod_ohm)
        xlabel("Frequency (Hz)")
        ylabel("|Z| (ohm)")
    case "cvct"
        curve = item.curves(1);
        [x, y] = labkit.dta.getCurveXY(curve, "Vf", "Im");
        plot(x, y)
end
```

The second argument restricts the accepted data family. Use `"auto"` to
detect it, or use `"chrono"`, `"eis"`, or `"cvct"` when loading the wrong
family should be reported as a failure. Values are case-insensitive and may
contain surrounding whitespace. A blank value also means `"auto"`.

## Choose a Function

| Task | Function |
| --- | --- |
| Identify the data family in one file | [`labkit.dta.detectType`](../../reference/api/labkit/dta/detectType.html) |
| Read one file | [`labkit.dta.loadFile`](../../reference/api/labkit/dta/loadFile.html) |
| Read a known list of files | [`labkit.dta.loadFiles`](../../reference/api/labkit/dta/loadFiles.html) |
| Find and read every DTA file below a folder | [`labkit.dta.loadFolder`](../../reference/api/labkit/dta/loadFolder.html) |
| Find paths without reading their contents | [`labkit.dta.findFiles`](../../reference/api/labkit/dta/findFiles.html) |
| Select a chrono or EIS table | [`getMainCurve`](../../reference/api/labkit/dta/getMainCurve.html), [`getZCurve`](../../reference/api/labkit/dta/getZCurve.html) |
| Extract numeric columns from parsed tables | [`getColumn`](../../reference/api/labkit/dta/getColumn.html), [`getCurveXY`](../../reference/api/labkit/dta/getCurveXY.html) |
| Locate chrono pulse windows | [`labkit.dta.detectPulses`](../../reference/api/labkit/dta/detectPulses.html) |
| Check library version and compatibility | [`labkit.dta.version`](../../reference/api/labkit/dta/version.html) |

## Loading Several Files

`loadFiles` keeps every successful item and records failures instead of
stopping at the first unreadable file:

```matlab
files = ["run-01.DTA", "run-02.DTA", "run-03.DTA"];
[items, report] = labkit.dta.loadFiles(files, "chrono");

fprintf("Loaded %d of %d files.\n", ...
    report.nLoaded, report.nRequested)

for k = 1:numel(report.failed)
    warning("%s: %s", ...
        report.failed(k).filepath, report.failed(k).message)
end
```

`report.statuses` contains one status in the same order as the input paths.
`items` contains successful items only, so use the status array when you need
to match a result to every original position.

Use `loadFolder` for recursive folder import. It adds `folder`, `filepaths`,
and `nDiscovered` to the same report:

```matlab
[items, report] = labkit.dta.loadFolder("experiment", "eis");
```

## Chrono Data

A chrono item contains the parsed metadata and tables, the selected transient
curve, pulse information, and these unit-explicit vectors:

| Field | Meaning |
| --- | --- |
| `t_s` | Time in seconds |
| `Vf_V` | Measured voltage in volts |
| `Im_A` | Measured current in amperes |
| `pt` | Point number from the file, or a generated zero-based sequence |
| `controlMode` | `"current"`, `"voltage"`, or `"unknown"`, inferred from step metadata |
| `pulse` | Cathodic, gap, and anodic windows returned by `detectPulses` |
| `meta`, `tables`, `curve` | Parsed metadata, all parsed tables, and the selected T/Vf/Im table |

Rows with nonfinite T, Vf, or Im values are removed. Duplicate time values keep
their first occurrence. Loading fails when fewer than two valid samples remain.

### Pulse Detection

The default mode, `"Metadata first, then auto"`, first looks for negative and
positive ISTEP/TSTEP metadata. If current-step metadata is absent, it can use
VSTEP/TSTEP timing. If metadata detection fails, it locates dominant negative
and positive segments in the measured current.

```matlab
[pulse, message] = labkit.dta.detectPulses( ...
    item.t_s, item.Im_A, item.meta, "Metadata first, then auto");
```

Other modes are `"Metadata only"` and `"Auto from Im only"`. Programmatic
aliases `"metadata_first"`, `"metadata_only"`, and `"current_only"` are also
accepted. Current-based detection uses 25 percent of `max(abs(Im))` as its
threshold, with a `1e-12 A` floor, then selects the longest cathodic segment
and the longest later anodic segment.

On success, `pulse.cath`, `pulse.gap`, and `pulse.anod` provide times in
seconds and currents in amperes. `pulse.ok` is false and numeric fields are
`NaN` when a valid cathodic/anodic pair cannot be found. Always check
`pulse.ok` before using the windows in a calculation.

## EIS Data

An EIS item selects the `ZCURVE` table, or the first compatible table with
Freq, Zreal, and Zimag columns. It exposes these unit-explicit vectors:

| Field | Meaning |
| --- | --- |
| `freq_Hz` | Frequency in hertz |
| `time_s` | Elapsed time in seconds |
| `point` | Point number |
| `Zreal_ohm` | Real impedance in ohms |
| `Zimag_ohm` | Imaginary impedance in ohms |
| `negZimag_ohm` | Negative imaginary impedance in ohms |
| `Zmod_ohm` | Impedance magnitude in ohms |
| `Zphz_deg` | Phase angle in degrees |
| `Idc_A` | DC current in amperes |
| `Vdc_V` | DC voltage in volts |

Rows are retained when at least one primary impedance value is finite. Missing
optional columns are returned as same-length `NaN` vectors. Loading fails when
fewer than two usable ZCURVE rows remain.

## CV/CT Data

A CV/CT item contains `curves` in file order and exposes the parsed scan rate
as `scanRate_V_per_s`. The parser converts a Gamry `SCANRATE` value from mV/s
to V/s. Each curve retains its headers, units, numeric data, and information
about which values were parsed successfully.

Use exact header names with `getCurveXY`:

```matlab
curve = item.curves(1);
[voltageV, currentA, xname, yname] = ...
    labkit.dta.getCurveXY(curve, "Vf", "Im");
```

Rows where either selected column is `NaN` are removed as a pair.
`getCurveXY` returns empty arrays and empty names when either header is absent.

## Parsed Table Structure

Chrono and EIS parsers return `tables`, a structure array containing the table
name, headers, units when available, and numeric data. Use `getMainCurve` or
`getZCurve` to select a compatible table, then use `getColumn` for
case-insensitive column lookup:

```matlab
[curve, ok, message] = labkit.dta.getMainCurve(item.tables);
if ok
    timeSec = labkit.dta.getColumn(curve, "T");
    currentA = labkit.dta.getColumn(curve, "Im");
end
```

`getColumn` returns `[]` when the requested header is absent. It does not
change units or remove `NaN` values.

## File Format and Limitations

The reader treats DTA files as tab-delimited text. It scans metadata and named
TABLE or CURVE sections, preserves headers and units when available, and
converts numeric rows conservatively. Gamry software versions and experiment
methods can produce additional sections or columns. Successful parsing means
that a supported core curve was found; it does not imply that every
vendor-specific field was interpreted.

`detectType` and `loadFile` return readable status messages for missing files,
unsupported content, parse failures, and expected-kind mismatches. Invalid
argument types and invalid expected-kind strings throw documented LabKit
errors.

## Reference Contract

Open an individual DTA function page for exact accepted kinds, path forms,
status fields, thrown errors, and related loaders or accessors. Public help is
checked against implemented options and its executable examples are run in a
clean MATLAB test process.

## Related Topics

- [CIC](../../apps/electrochemistry/cic/README.md),
  [CSC](../../apps/electrochemistry/csc/README.md), and
  [EIS](../../apps/electrochemistry/eis/README.md) use DTA records in
  interactive workflows.
- [Contract functions](../../framework/contracts.md) explain how apps declare a
  compatible `labkit.dta` API version.
- [Project history](../../history/README.md) lists parser, schema, and
  compatibility changes.
