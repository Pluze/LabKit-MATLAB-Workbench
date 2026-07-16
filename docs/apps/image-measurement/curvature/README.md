# Curvature Measurement

Curvature Measurement fits a circle to an ordered image curve, reports radius
and curvature, measures traced arc length, and supports pixel-to-physical scale
calibration.

## Requirements And Launch

The app uses the LabKit UI framework and Image library.

```matlab
labkit_CurvatureMeasurement_app
```

## Basic Workflow

1. Choose an image.
2. Measure a known scale reference and enter its length/unit when physical
   values are required.
3. Start curve editing and place ordered anchors along the feature.
4. Drag anchors to refine the trace; undo or clear as needed.
5. Fit the circle and measure curve length.
6. Export the result CSV and overlay PNG.

The canvas title/subtitle identifies curve-edit mode and its placement/removal
gesture. Anchor edits and result overlays preserve the current axes zoom.

## Curve Editing

Curve points are ordered by placement. **Undo last point** removes the newest
anchor and **Clear curve** removes the complete trace. Neighboring duplicate
points are removed before numeric fitting. At least three distinct points are
required for a circle fit; length requires at least two.

## Fit Parameters And Semantics

**Densify before circle fit** is enabled by default with 300 dense points.
Densification interpolates along the ordered trace before the least-squares
circle fit; it changes sampling density, not the manually defined path.
**Show dense fit points** is presentation-only.

For fitted radius `r`:

```text
curvature = 1 / r
```

Pixel-domain radius and curvature are always available. With calibration,
radius and traced length are converted to the selected physical unit and
curvature uses its reciprocal unit. Curve length is the sum of distances along
the ordered polyline/densified curve specified by the API options; it is not
the circumference of the fitted circle.

## Scale Calibration And Bar

Measure the pixel distance spanning a known reference, enter its physical
length, and choose `m`, `cm`, `mm`, `um`, or `nm`. Calibration stores reference
pixels, reference length, unit, and pixels per unit. Scale-bar length defaults
to 100 units; position defaults to Bottom right and color to Black. Placing or
moving the display bar does not modify the fit.

## Outputs

The CSV records point count, fit settings, center, radius, curvature, traced
length, calibration, units, and status. The overlay PNG contains the source
image, curve, fitted circle, and configured scale bar when available. A result
manifest records source and parameter provenance.

## Use Without The GUI

```matlab
points = [100 80; 130 58; 165 52; 200 66; 225 95];
fit = curvature.analysisRun.computeCurvatureFit(points, ...
    struct("densify", true, "densePointCount", 300));
lengthResult = curvature.analysisRun.computeCurveLength(points, struct());
```

## Errors And Limitations

- Collinear or nearly collinear points do not define a stable finite circle.
- Calibration uncertainty propagates directly to physical radius and length.
- A circle fit summarizes a curved segment; it does not prove the feature is
  truly circular. Inspect residuals and the overlay.

## Related Topics

- [Image Measurement family](../README.md)
- [Image Library](../../../libraries/image/README.md)
- [API Reference](../../../libraries/README.md)
