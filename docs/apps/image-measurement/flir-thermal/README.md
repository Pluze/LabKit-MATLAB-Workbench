# FLIR Thermal

FLIR Thermal decodes radiometric FLIR JPEG/RJPEG files, displays calibrated
temperature maps, measures rectangular ROI hot/cold/mean values, and exports
rendered images with Celsius data.

## Requirements And Launch

The app uses the LabKit UI framework and Thermal library. A `.jpg`, `.jpeg`, or
`.rjpg` extension alone is insufficient; the file must contain a readable FLIR
raw thermal record and calibration metadata.

```matlab
labkit_FLIRThermal_app
```

## Inputs And Navigation

Use **Add FLIR files or folder** to load one or more radiometric images. The
selected row is the current image; Previous/Next change selection without
discarding per-image display range or measurement annotations. Source files
are read-only.

## Basic Workflow

1. Load radiometric files and inspect the decoded min/max/metadata summary.
2. Choose a palette and color mapping.
3. Set a range preset, per-image range, or shared group range.
4. Place a rectangular ROI and choose hot spot, cold spot, or mean reading.
5. Review the numeric result and marker.
6. Export the current image or the full batch.

Placing or dragging a reading ROI and refreshing its marker preserves the
current zoom. The reading is recalculated from the thermal matrix, not from
screen colors.

## Temperature Conversion

`labkit.thermal.readFile` extracts the raw sensor matrix and converts it to
Celsius. Environment-corrected conversion uses Planck constants plus available
emissivity, object distance, atmospheric/window transmission, reflected
temperature, and related metadata. Missing environmental fields may use
documented defaults and are listed in
`record.metadata.temperatureConversion`; required Planck constants are never
invented.

Absolute temperature accuracy depends on camera calibration and environmental
assumptions. Preserve conversion diagnostics with reported measurements.

## Display Controls

Palettes are Turbo, Iron, Hot, Parula, and Gray. Mapping modes are Linear, Log,
and Gamma; gamma defaults to 2.2 and is limited to 0.1-5. Display ranges are
stored per image. Actions can set each image independently, apply one shared
group range, fit the current image, or round configured bounds.

Palette, mapping, gamma, and color limits affect only mapping into display
colors. They do not transform the Celsius matrix or exported temperature
values.

## ROI Readings

The rectangular ROI includes both boundary pixels after its two corners are
rounded and clamped to the thermal matrix. Hot and cold readings report value
and `[x y]` location. Mean ignores non-finite pixels and also records ROI
geometry and finite pixel count. The marker is a display annotation; moving it
does not change source data.

## Outputs

Current or batch export can write PNG, TIFF, or JPEG rendered thermal images,
color scale graphics, Celsius matrices/tables, measurement values, and a
manifest. The clean image export excludes interactive toolbar chrome. Numeric
temperature outputs remain Celsius regardless of palette or mapping mode.

## Project And State

Saved projects keep portable source references, display parameters, export
settings, and lightweight per-image ranges and readings. Raw sensor matrices
and decoded Celsius matrices are transient session data: Runtime V2 resolves
the source references and the App decodes only the selected image again when a
project opens. Missing source files therefore use the framework's relinking
flow rather than embedding local absolute paths in the project.

An empty launch does not choose an output directory. Adding files establishes
the source-adjacent default; **Choose folder** remains available before export.

## Use Without The GUI

```matlab
record = labkit.thermal.readFile("capture.rjpg");
temperatureC = record.temperatureC;

point = flir_thermal.analysisRun.pointTemperatureReading( ...
    temperatureC, [120 80]);
[hot, cold, meanReading] = ...
    flir_thermal.analysisRun.roiTemperatureMeanReading( ...
        temperatureC, [90 60], [169 129]);
[imageHot, imageCold] = ...
    flir_thermal.analysisRun.extremeTemperatureReadings(temperatureC);
```

## Errors And Limitations

- Non-radiometric JPEG files are rejected even when their extension is valid.
- Coordinates refer to the decoded thermal matrix, not a separately scaled
  visible-light image.
- An ROI containing no finite temperature pixels cannot return a finite mean.
- JPEG export is visual and lossy; keep Celsius data for quantitative work.

## Related Topics

- [Thermal Library](../../../libraries/thermal/README.md)
- [Image Measurement family](../README.md)
- [API Reference](../../../libraries/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata, requirements, layout, actions,
presentation, renderers, and debug-sample capability. `projectSpec.m` is the
only durable-project entry; the version-1 payload needs creation and validation
but no migration. Root `createSession.m` rebuilds only the selected decoded
thermal item after Runtime V2 resolves sources.

The project validator requires the thermal-source collection and checks
thermal parameters and annotations; Runtime validates canonical buckets and
each source record first.

Decoded record shape lives with `+sourceFiles`, point and ROI calculations live
with `+analysisRun`, and lightweight durable readings live with
`+thermalAnnotations`; there is no generic `+appState` package. The App
requires `labkit.ui >=7 <8`, `labkit.image >=2 <3`, and
`labkit.thermal >=1.1 <2`. Source-path access, persistence, callback lifetime,
busy state, and managed region interaction remain framework-owned. Thermal
image, colorbar, and CSV manifest outputs are appended to the framework's
canonical empty output array; no invalid placeholder result is created before
batch export.

Its session factory returns only App-specific image selection and decoded
thermal cache fields. Runtime supplies absent canonical buckets and owns
workflow-log initialization.

The semantic layout follows the [Runtime callback contract](../../../framework/runtime.md#layout-and-action-rules):
every referenced action must be registered and resolves during layout construction.
