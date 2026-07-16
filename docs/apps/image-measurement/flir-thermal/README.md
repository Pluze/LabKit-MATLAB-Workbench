# FLIR Thermal

FLIR Thermal decodes radiometric FLIR images, displays calibrated temperature,
and measures points, ROIs, minima, and maxima.

## Launch

```matlab
labkit_FLIRThermal_app
```

## Workflow

Load a radiometric image, inspect the temperature map, then place point or ROI
measurements. Markers and rectangles remain editable and preserve the current
zoom. Exports include the rendered view and measurement values without
overwriting the source image.

## Scientific Semantics

Temperature comes from the embedded raw sensor values and calibration
metadata through `labkit.thermal`. Point measurements sample the selected
pixel. ROI measurements use the pixels inside the ROI. Extreme measurements
report both value and location. Display color limits do not change numeric
temperature results.

## Use Without The GUI

```matlab
record = labkit.thermal.readFile("capture.jpg");
temperatureC = record.temperatureC;

point = flir_thermal.analysisRun.pointTemperatureReading( ...
    temperatureC, [120 80]);
[roiHot, roiCold, roiMean] = ...
    flir_thermal.analysisRun.roiTemperatureMeanReading( ...
    temperatureC, [90 60], [169 129]);
[imageHot, imageCold] = ...
    flir_thermal.analysisRun.extremeTemperatureReadings(temperatureC);
```

`pointTemperatureReading` rounds and clamps an `[x y]` pixel coordinate.
`roiTemperatureMeanReading` accepts two opposite ROI corners, includes both
boundary pixels, ignores non-finite temperature values, and reports hot, cold,
and mean records. Every point record contains `x`, `y`, and `temperatureC`;
the mean record also contains ROI geometry and `pixelCount`.

`labkit.thermal.readFile` accepts an optional `TemperatureCorrection` field.
Use `"environment"` for the metadata-aware correction path or
`"planck-basic"` when the intended calculation deliberately omits reflected,
atmospheric, distance, and window corrections.

## Errors And Limitations

- A supported JPEG extension does not guarantee that the file contains an
  embedded radiometric record and usable calibration metadata.
- Pixel coordinates refer to the calibrated thermal matrix, not a separately
  scaled screenshot or visible-light preview.
- Emissivity and environmental assumptions affect absolute temperature; keep
  the conversion metadata with any reported result.

## See Also

- [Thermal Library](../../../libraries/thermal/README.md)
- `labkit.thermal.readFile`
- `labkit.thermal.rawToTemperatureC`
