# Curvature Measurement

```labkit-page
id: app-curvature
type: landing
audience: app-user
summary: Curvature Measurement fits a circle to an ordered image curve, reports radius and curvature, measures traced arc length, and supports pixel-to-physical scale calibration.
```

Curvature Measurement fits a circle to an ordered image curve, reports radius and curvature, measures traced arc length, and supports pixel-to-physical scale calibration.

The combined measurement action computes traced length and circle-fit results from the same current curve and scale options, keeping the displayed summary and exported row aligned.

## Requirements And Launch

```matlab
labkit_CurvatureMeasurement_app
```

## Basic Workflow

The **Files + Analysis** tab contains the complete workflow:

1. Choose an image in the **Image** section.
2. Use **Measure reference pixels**, or enter **Reference pixels** directly, then enter the known reference length and unit.
3. Configure and place the optional display scale bar.
4. Use **Start curve edit** and place ordered anchors along the feature.
5. Drag anchors to refine the trace; undo or clear as needed, then finish curve editing.
6. Choose the densification settings and use **Measure length + curvature** to produce both results together.
7. Export the result CSV and overlay PNG.

The edit buttons change to **Finish curve edit** or **Finish reference edit** while their managed interaction is active. Curve and reference edits are mutually exclusive. Anchor edits and result overlays preserve the current axes zoom.

The **Summary + Results** tab reports curve length, radius, curvature, RMSE, fit center, and pixels per selected unit. **Details** explains the next valid step before a result exists and reports the current measurement afterward. **Tools > Diagnostics > Open Session Log...** records file, edit, fit, calibration, export, and runtime actions without consuming a workflow tab. Numeric fit-density and scale-bar adjustments do not add a routine INFO record for every committed value.

The chosen image remains a live source while the App is open.

## Curve Editing

Curve points are ordered by placement. **Undo last point** removes the newest anchor and **Clear curve** removes the complete trace. Neighboring duplicate points are removed before numeric fitting. At least three distinct points are required for the combined measurement. While curve editing is active, only the managed editable curve is drawn; the inactive static curve returns after the edit is finished.

## Scale Calibration And Bar

Measure the pixel distance spanning a known reference, enter its physical length, and choose `m`, `cm`, `mm`, `um`, or `nm`. Calibration stores reference pixels, reference length, unit, and pixels per unit. Scale-bar length defaults to 100 units; position defaults to Bottom right and color to Black. Placing or moving the display bar does not modify the fit.

## Fit Parameters And Semantics

**Densify before circle fit** is enabled by default with 300 dense points. Densification interpolates along the ordered trace before the least-squares circle fit; it changes sampling density, not the manually defined path. **Show dense fit points** is presentation-only.

For fitted radius `r`:

```text
curvature = 1 / r
```

Pixel-domain radius and curvature are always available. With calibration, radius and traced length are converted to the selected physical unit and curvature uses its reciprocal unit. Curve length is the sum of distances along the ordered polyline/densified curve specified by the API options; it is not the circumference of the fitted circle.

## Outputs

The CSV records point count, fit settings, center, radius, curvature, traced length, calibration, units, and status. The overlay PNG contains the source image, ordered curve, optional dense samples, fit residuals, fitted circle, center, and configured scale bar when available.

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
- A circle fit summarizes a curved segment; it does not prove the feature is truly circular. Inspect residuals and the overlay.

## Related Topics

- [Image Measurement family](../README.md)
- [Image Library](../../../../develop/libraries/image/README.md)
- [API Reference](../../../../reference/README.md)
