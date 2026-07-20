# Curvature Measurement

Every action and input-selection button provides hover help describing its
curve trace, calibration, curvature/length calculation, or export effect.

Curvature Measurement fits a circle to an ordered image curve, reports radius
and curvature, measures traced arc length, and supports pixel-to-physical scale
calibration.

## Requirements And Launch

The app uses the LabKit UI framework and Image library.

```matlab
labkit_CurvatureMeasurement_app
```

## Basic Workflow

The **Files + Analysis** tab contains the complete workflow:

1. Choose an image in the **Image** section.
2. Use **Measure reference pixels**, or enter **Reference pixels** directly,
   then enter the known reference length and unit.
3. Configure and place the optional display scale bar.
4. Use **Start curve edit** and place ordered anchors along the feature.
5. Drag anchors to refine the trace; undo or clear as needed, then finish
   curve editing.
6. Choose the densification settings, fit the circle, and measure curve
   length.
7. Export the result CSV and overlay PNG.

The edit buttons change to **Finish curve edit** or **Finish reference edit**
while their managed interaction is active. Curve and reference edits are
mutually exclusive. Anchor edits and result overlays preserve the current
axes zoom.

The **Summary + Results** tab reports curve length, radius, curvature, RMSE,
fit center, and pixels per selected unit. **Details** explains the next valid
step before a result exists and reports the current measurement afterward.
The **Log** tab records file, edit, fit, calibration, and export actions.

The chosen image is stored in the standard project `inputs.sources`
collection. Version 1 projects using the former singular `inputs.source`
field are upgraded on load and saved as payload version 2.

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
image, ordered curve, optional dense samples, fit residuals, fitted circle,
center, and configured scale bar when available. Each export writes its
standard result manifest with source and parameter provenance.

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
- [API Reference](../../../reference/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata, requirements, the composed
workbench, project/session boundaries, presentation, and debug-sample
capability. `+workbench/buildLayout.m` composes source selection, curve
editing, scale calibration, analysis/export, summary, log, and preview
surfaces from their owning capability packages. Layout nodes bind their
concrete callbacks and renderer directly; the App has no handler or renderer
registry.

`projectSpec.m` is the only durable-project entry and keeps current creation,
validation, and the version-1 source migration together. The runtime owns the
migration loop. Root `createSession.m` reconstructs the decoded image and
transient edit state after source relinking.

The project validator requires the image-source collection and checks
curvature parameters, annotations, and results; Runtime validates canonical
buckets and each source record first.

Fit/length result shapes and deterministic task fingerprints live with their
calculations under `+analysisRun`; there is no generic state or action
package. The App requires `labkit.app >=1 <2` and `labkit.image >=2 <3`;
source-path access, persistence, callback lifetime, result manifests, and
managed anchor/reference interactions remain framework-owned.

Its session factory returns only App-specific edit workflow, scale-bar view,
and decoded image cache fields. Runtime supplies absent canonical buckets and
owns workflow-log initialization.

The semantic layout follows the
[App framework contract](../../../framework/README.md): callbacks name the
complete application state, typed event value when present, and
`CallbackContext` at their direct boundary, then delegate scientific work
through narrow inputs.
