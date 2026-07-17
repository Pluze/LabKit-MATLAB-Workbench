# Thermal Images

[API reference](../README.md) | [FLIR Thermal app](../../apps/image-measurement/flir-thermal/README.md)

The `labkit.thermal` functions read FLIR radiometric JPEG files, expose their
raw sensor data and calibration metadata, convert sensor values to degrees
Celsius, and create display-ready RGB images. They can be called from MATLAB
without opening a LabKit app.

## Start Here

Use this sequence when you want to analyze thermal files in a script:

```matlab
files = ["capture-01.rjpg", "capture-02.rjpg"];
[records, report] = labkit.thermal.readFiles(files, ...
    struct("SkipInvalid", true));

for k = 1:numel(records)
    temperatureC = records(k).temperatureC;
    fprintf("%s: %.1f to %.1f C\n", records(k).name, ...
        min(temperatureC, [], "all"), max(temperatureC, [], "all"));
end

fprintf("Loaded %d files; skipped %d.\n", ...
    report.loaded, report.skipped)
```

`readFiles` preserves the input order. With `SkipInvalid` set to `true`, it
returns every readable record and describes unreadable files in
`report.failures`. Without that option, the first read error stops the call.

## Choose a Function

| Task | Function |
| --- | --- |
| Read one radiometric image | [`labkit.thermal.readFile`](../../reference/api/labkit/thermal/readFile.html) |
| Read a list of images | [`labkit.thermal.readFiles`](../../reference/api/labkit/thermal/readFiles.html) |
| Check a file without throwing a read error | [`labkit.thermal.inspectFile`](../../reference/api/labkit/thermal/inspectFile.html) |
| Convert raw counts with supplied calibration | [`labkit.thermal.rawToTemperatureC`](../../reference/api/labkit/thermal/rawToTemperatureC.html) |
| Convert a numeric matrix to RGB colours | [`labkit.thermal.renderImage`](../../reference/api/labkit/thermal/renderImage.html) |
| Build a file-dialog filter | [`labkit.thermal.fileDialogFilter`](../../reference/api/labkit/thermal/fileDialogFilter.html) |
| Test or list recognized extensions | [`isSupportedPath`](../../reference/api/labkit/thermal/isSupportedPath.html), [`supportedExtensions`](../../reference/api/labkit/thermal/supportedExtensions.html) |
| Check library version and compatibility | [`labkit.thermal.version`](../../reference/api/labkit/thermal/version.html) |

## Thermal Records

`readFile` returns one structure with these fields:

| Field | Meaning |
| --- | --- |
| `path`, `name` | Source location and filename |
| `format` | Detected radiometric container format |
| `raw` | Decoded sensor-count matrix |
| `temperatureC` | Same-size double matrix in degrees Celsius; invalid conversion pixels are `NaN` |
| `units` | `"C"` when temperature conversion succeeded, otherwise `"raw"` |
| `metadata` | Parsed FLIR tags, calibration values, record information, and conversion diagnostics |
| `message` | Short description of the conversion result |

An ordinary JPEG preview is not a temperature matrix. The reader looks for an
embedded FLIR FFF `RawThermalImage` record and uses that sensor data for the
conversion. A `.jpg` or `.rjpg` extension therefore indicates only a candidate
file. Call `inspectFile` when you need to know whether the contents are
actually readable as thermal data.

## Temperature Correction

The default `"environment"` correction uses the camera's Planck constants and,
when available, emissivity, object distance, reflected apparent temperature,
atmospheric temperature, humidity, infrared-window temperature, and
infrared-window transmission. Missing environmental values receive documented
defaults so that conversion can continue. The five Planck constants never
receive fallback values.

Use two outputs from `rawToTemperatureC` to see exactly what happened:

```matlab
[temperatureC, diagnostics] = labkit.thermal.rawToTemperatureC( ...
    raw, calibration, struct("Correction", "environment"));

if diagnostics.usedDefaults
    fprintf("Defaults used for: %s\n", ...
        strjoin(diagnostics.defaultedFields, ", "))
end
```

`diagnostics.parameterSources` records `"calibration"` or `"default"` for
each environmental input. A conversion that used defaults may be useful for
previewing data, but the result is not evidence that the assumed emissivity,
distance, humidity, or temperatures match the experiment. Check those values
before using the temperatures in quantitative analysis.

Choose `"planck-basic"` only when you intentionally want the conversion based
on the five Planck constants alone:

```matlab
temperatureC = labkit.thermal.rawToTemperatureC(raw, calibration, ...
    struct("Correction", "planck-basic"));
```

## Rendering a Temperature Matrix

`renderImage` maps a numeric matrix onto a colour palette. It does not change
the temperatures and does not perform calibration.

```matlab
rgb = labkit.thermal.renderImage(temperatureC, ...
    struct("Limits", [20 40], "Palette", "iron", "Levels", 256));
image(rgb)
axis image off
```

Values outside `Limits` are clipped to the end colours. Supported palettes are
`"turbo"`, `"parula"`, `"hot"`, `"gray"`, and `"iron"`. The FLIR Thermal app
also offers display-only log and gamma controls; those controls are app
features and do not alter exported temperature values.

## Supported Files and Limitations

The current reader supports FLIR radiometric JPEG and RJPEG files with an
embedded FFF raw-thermal record. Camera models and firmware revisions can
encode metadata differently. Use `inspectFile` or `readFiles` with
`SkipInvalid=true` for mixed or uncertain inputs, and retain the returned
failure messages when reporting an unsupported file.

Do not infer measurement accuracy from successful parsing alone. Quantitative
temperature accuracy still depends on the camera calibration and on correct
environmental inputs for the photographed material and scene.

## Reference Contract

Each generated Thermal API page distinguishes returned status from thrown
errors and documents every implemented option, default, legal value, output
field, and related function. Executable examples and package-wide public-help
discovery prevent the manual and callable surface from silently diverging.

## Related Topics

- [Image functions](../image/README.md) cover ordinary image IO and image
  processing that does not use radiometric calibration.
- [FLIR Thermal app](../../apps/image-measurement/flir-thermal/README.md)
  provides interactive file review, measurements, display controls, and
  exports.
- [Project history](../../history/README.md) lists changes to thermal file
  support and calibration behavior.
