# Thermal API

[Public API index](README.md) · [App guide](../apps/README.md)

`labkit.thermal.*` is the GUI-free facade for reusable thermal source-file
parsing, raw thermal matrices, embedded calibration metadata,
raw-to-temperature conversion, and linear thermal palette rendering. It is
separate from `labkit.image`: ordinary image IO and filters stay in
`labkit.image`, while radiometric source formats and thermal calibration
mechanics live here.

`labkit.thermal.version()` returns the thermal facade contract version used by
app `requirements.m` declarations.

## Common Calls

```matlab
filter = labkit.thermal.fileDialogFilter("IncludeAll", true);
[records, report] = labkit.thermal.readFiles(paths, ...
    struct("SkipInvalid", true));
probe = labkit.thermal.inspectFile(paths(1));

values = records(1).temperatureC;
if all(isnan(values), "all")
    values = records(1).raw;
end

rgb = labkit.thermal.renderImage(values, ...
    struct("Limits", [20 40], "Palette", "iron"));
```

Current source support is FLIR radiometric JPEG/RJPEG files that contain an
embedded FFF RawThermalImage record. `readFile` returns a struct with:

- `path`, `name`, and `format`
- `raw`: the raw thermal signal matrix
- `temperatureC`: Celsius matrix when embedded calibration is complete, or
  `NaN` values when conversion is unavailable
- `units`: `"C"` or `"raw"`
- `metadata`: reader name, raw image type, byte-order normalization, embedded
  calibration fields, parsed FFF records, and `temperatureConversion`
  diagnostics describing correction mode and parameter provenance
- `message`: short conversion status text

`rawToTemperatureC` supports `"environment"` correction, which uses emissivity,
distance, reflected/atmospheric/window temperatures, humidity, transmission,
and Planck constants when available. `"planck-basic"` applies only the embedded
Planck constants.

Call `rawToTemperatureC` with two outputs to inspect conversion provenance:

```matlab
[temperatureC, diagnostics] = labkit.thermal.rawToTemperatureC( ...
    raw, calibration);
```

`diagnostics.usedDefaults` indicates that one or more environmental fields were
missing or invalid, `defaultedFields` names them, and `parameterSources` maps
each environmental field to `"calibration"` or `"default"`. Records returned
by `readFile` expose the same struct as
`record.metadata.temperatureConversion`. Planck constants are mandatory and
never receive generic fallback values.

Environment mode falls back to defined FLIR-model settings only when necessary,
including emissivity `1`, object distance `1 m`, reflected and atmospheric
temperature `20 C`, relative humidity `0.5`, and the standard atmospheric
transmission coefficients. These values make conversion possible but do not
establish measurement accuracy for the photographed material or environment.
Apps should visibly warn users whenever defaults were used. The FLIR Thermal
app shows that warning in both the file status and detail panel.

`renderImage` is the reusable facade renderer for linear thermal palette
mapping over a selected numeric range. App-level display modes such as log or
gamma color mapping belong to the owning app because they are workflow and UI
policy: the FLIR Thermal app applies those modes only while converting a
selected display range into RGB colors. They do not change the raw matrix,
Celsius matrix, thermal record, or exported temperature CSV values.

Use `inspectFile` or `readFiles(..., struct("SkipInvalid", true))` when a
workflow accepts mixed selections from a file dialog. The facade owns the
distinction between extension-compatible files and files that actually contain
readable thermal payloads; apps should present the returned report instead of
reimplementing that detection with app-local catch blocks.

## Ownership

The facade may own:

- thermal source extension lists and file-dialog filters
- compatibility inspection for deciding whether a file contains readable
  thermal payloads
- radiometric container parsing that exposes raw thermal matrices
- embedded calibration metadata normalization
- raw thermal signal to Celsius conversion
- generic linear thermal palette rendering
- private compatibility code for vendor container variants

Apps own:

- file queues, selected image state, and display-range defaults
- palette choices, log/gamma display mapping controls, and workflow wording
- colorbar export placement, manifests, filenames, and failed-row policy
- overlay-removal workflows, measurements, annotations, alerts, and logs
- any app-specific decisions about which matrix to show or export

Use `labkit.thermal.readFiles` when an app needs reusable thermal records. Apps
may copy returned fields into app-owned item structs. Keep app-owned readers
when they build workflow state, apply user policy, or combine thermal data with
other app inputs.

## Compatibility

Radiometric files vary by camera family and firmware. The facade should prefer
structural parsing and defensive metadata checks over hard-coded app behavior.
When adding compatibility for a new thermal source variant, add synthetic
fixtures or anonymous structural tests that preserve only format shape and do
not commit lab sample files, local paths, filenames, serial numbers, timestamps,
or identifying metadata.
