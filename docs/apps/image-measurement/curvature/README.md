# Curvature Measurement

Curvature Measurement fits a calibrated curve through user-defined anchors and
reports curvature, radius, and curve length.

## Launch

```matlab
labkit_CurvatureMeasurement_app
```

## Workflow And Interaction

Load an image, establish the scale, enter anchor editing, and double-click to
place or remove anchors. The plot subtitle states the active interaction while
editing. Anchors can be refined before fitting; adding or removing a point does
not reset the current zoom.

## Scientific Semantics

Coordinates are fitted in calibrated units. Curvature is the inverse of the
fitted radius where the chosen model defines a radius; curve length follows
the fitted path rather than the straight-line distance between endpoints.
Scale and fit model must therefore accompany reported values.

## Use Without The GUI

```matlab
pointsPx = [20 80; 60 45; 110 30; 160 48];
fit = curvature.analysisRun.computeCurvatureFit(pointsPx, 0.01);
lengthValue = curvature.analysisRun.computeCurveLength(fit);
```

## Troubleshooting

- Spread anchors along the complete structure instead of clustering them.
- Check scale units before comparing radius or length across images.
- A visibly poor fit should be corrected at the anchors, not hidden by export.

## See Also

- `curvature.analysisRun.computeCurvatureFit`
- `curvature.analysisRun.computeCurveLength`

