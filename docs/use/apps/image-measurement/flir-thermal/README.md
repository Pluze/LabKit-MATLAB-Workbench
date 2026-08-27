# FLIR Thermal

```labkit-page
id: app-flir-thermal
type: landing
audience: app-user
summary: Display calibrated FLIR temperature maps, measure rectangular region statistics, and export rendered images with Celsius data.
```

FLIR Thermal decodes radiometric FLIR JPEG/RJPEG files, displays calibrated temperature maps, measures rectangular ROI hot/cold/mean values, and exports rendered images with Celsius data.

Palette, range, ROI, and point labels are derived from the current thermal frame whenever the presentation refreshes, so no separate display-state cache must be maintained.

## Requirements And Launch

A `.jpg`, `.jpeg`, or `.rjpg` extension alone is insufficient; the file must contain a readable FLIR raw thermal record and calibration metadata.

```matlab
labkit_FLIRThermal_app
```

## Inputs And Navigation

Use **Add FLIR files** to select one or more radiometric images. Use the separate folder buttons for one folder or a recursive folder tree. Candidates that are not readable radiometric FLIR images are omitted with an aggregate notice. The selected row is the current image; Previous/Next change selection without discarding per-image display range or measurement annotations. Source files are read-only.

## Basic Workflow

1. Load radiometric files and inspect the decoded min/max/metadata summary.
2. Choose a palette and color mapping.
3. Set a range preset, per-image range, or shared group range.
4. Choose ROI hot spot, ROI cold spot, or ROI mean, then drag its rectangle.
5. Optionally click the image for an independent manual point reading.
6. Review the numeric results and markers.
7. Export the current image or the full batch.

Placing or dragging a reading ROI and refreshing its marker preserves the current zoom. Palette, mapping, and gamma changes also preserve the inspected region. Selecting a different source or changing the temperature range fits the paired image and temperature-scale axes to their new domains. The reading is recalculated from the thermal matrix, not from screen colors.

## ROI Readings

The rectangular ROI includes both boundary pixels after its two corners are rounded and clamped to the thermal matrix. Hot and cold readings report value and `[x y]` location. Mean ignores non-finite pixels and also records ROI geometry and finite pixel count. The marker is a display annotation; moving it does not change source data.

## Temperature Conversion

`labkit.thermal.readFile` extracts the raw sensor matrix and converts it to Celsius. Environment-corrected conversion uses Planck constants plus available emissivity, object distance, atmospheric/window transmission, reflected temperature, and related metadata. Missing environmental fields may use documented defaults and are listed in `record.metadata.temperatureConversion`; required Planck constants are never invented.

Absolute temperature accuracy depends on camera calibration and environmental assumptions. Preserve conversion diagnostics with reported measurements.

## Display Controls

Palettes are Turbo, Iron, Hot, Parula, and Gray. Mapping modes are Linear, Log, and Gamma; gamma defaults to 2.2 and is limited to 0.1-5. Display ranges are stored per image. Actions can set each image independently, apply one shared group range, fit the current image, or round configured bounds.

Palette, mapping, gamma, and color limits affect only mapping into display colors. They do not transform the Celsius matrix or exported temperature values.

Gamma and color-limit edits redraw the current thermal preview without adding routine INFO records for each committed value. Load, measurement, export, and actionable failure events remain the diagnostic milestones.

## Outputs

Current or batch export writes PNG, TIFF, or JPEG rendered thermal images, matching color scale graphics, Celsius CSV matrices, measurement values, and a batch CSV summary. The clean image export excludes interactive toolbar chrome. Numeric temperature outputs remain Celsius regardless of palette or mapping mode.

## Runtime State

Source references, display parameters, export settings, and per-image ranges and readings remain in memory while the App is open. Thermal data remains in the source files. Batch import reports and skips rejected selections before they enter the live source list.

An empty launch does not choose an output directory. Adding files establishes the source-adjacent default; **Choose folder** remains available before export.

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

## Function Reference

The generated pages for [`pointTemperatureReading`](../../../../reference/api/flir_thermal/analysisRun/pointTemperatureReading.html) and [`extremeTemperatureReadings`](../../../../reference/api/flir_thermal/analysisRun/extremeTemperatureReadings.html) specify coordinate order, clamping, nonfinite/empty behavior, returned fields, conversion failures, and related measurement APIs.

## Errors And Limitations

- Non-radiometric JPEG files are rejected even when their extension is valid.
- Coordinates refer to the decoded thermal matrix, not a separately scaled visible-light image.
- An ROI containing no finite temperature pixels cannot return a finite mean.
- JPEG export is visual and lossy; keep Celsius data for quantitative work.

## Related Topics

- [Thermal Library](../../../../develop/libraries/thermal/README.md)
- [Image Measurement family](../README.md)
- [API Reference](../../../../reference/README.md)
