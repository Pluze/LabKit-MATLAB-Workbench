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
[thermal, status] = labkit.thermal.readRadiometricJpeg("capture.jpg");
assert(status.ok, status.message);
point = flir_thermal.analysisRun.pointTemperatureReading(thermal, [120 80]);
roi = flir_thermal.analysisRun.roiTemperatureMeanReading(thermal, [90 60 80 70]);
extremes = flir_thermal.analysisRun.extremeTemperatureReadings(thermal);
```

## See Also

- [Thermal Library](../../api/thermal.md)
- `labkit.thermal.rawToTemperatureC`

