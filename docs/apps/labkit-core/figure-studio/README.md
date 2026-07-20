# Figure Studio

Figure Studio restyles MATLAB figures, exports presentation copies, and
extracts supported visible graphics into a portable data package. It changes
presentation properties, not the calculation that produced the plot.

## Open Figure Studio

From the launcher, select **Figure Studio** and choose **Open**. From a source
checkout, run:

```matlab
labkit_FigureStudio_app
```

A LabKit plot can also send its current axes to Figure Studio through the plot
context menu. That handoff embeds a serializable plot snapshot in the project.

## Initialization And Runtime Context

`figure_studio.definition` declares an optional App SDK `OnStart` capability
named `figure_studio.initializeWorkbench`. Runtime calls it after the semantic
layout and first complete view exist but before startup readiness is released.
The entrypoint converts an optional axes handoff into the normal
`InitialProject` launch value. `createSession(project,callbackContext)` then
rebuilds only transient FIG data, and the initializer establishes the default
output folder and records restored-source status.

The initializer receives canonical `applicationState` and the sealed
`labkit.app.CallbackContext`. It does not receive axes, a service bag, native
components, or a launch-request object. Fixed-canvas resize reflow, callback
queueing, busy state, and readiness remain runtime-owned.

## Load And Select Figures

On **Figures**, choose **Add FIG files or scan folder**. The source list accepts
MATLAB `.fig` files and keeps one current selection. Selecting another source
loads that figure's plot snapshot and original style. **Clear figures** removes
all sources from the project.

For a source using **FIG default**, Figure Studio adopts its font, line, grid,
canvas, and axes appearance. Selecting **LabKit figure** applies the LabKit
preset while retaining the source canvas size.

## Style And Canvas Controls

| Group | Controls |
| --- | --- |
| Style | preset, all/title/label/tick font size, plot line width, axes line width, grid alpha, grid visibility |
| Canvas | 4:3, 16:9, 1:1, 3:2, or custom aspect; width; height; export scale; boundary visibility |

Changing **All font** updates title, label, and tick sizes together until a
specific font size is edited. Canvas width and height are stored as project
parameters. PNG and JPG resolution is `300 * Export x`, with a minimum of
72 dpi. SVG uses vector content.

## Quick Exports

The **Figures** tab provides:

- **Save FIG** for an editable MATLAB figure;
- **PNG** and **JPG** for raster output;
- **SVG** for vector output.

Each quick export also writes a LabKit result manifest beside the selected
file. The manifest records the source, style parameters, output identity, and
summary metadata.

## Export A Data Package

On **Export**, select an output folder and choose **Export data + script**.
Figure Studio creates a package containing supported visible data, style and
axes metadata, and a MATLAB recreation script. The extractor currently
recognizes visible line, scatter, image, surface, patch, text, and constant-line
objects. Unsupported graphics are skipped and reported as warnings.

The package represents displayed graphics in axes child order. It is intended
for audit, handoff, and plot recreation, not for reconstructing hidden source
data or rerunning the original analysis.

## Programmatic Data Extraction

```matlab
fig = openfig("result.fig", "invisible");
cleanup = onCleanup(@() close(fig));
ax = findobj(fig, "Type", "axes", "-depth", 1);

plotData = figure_studio.resultFiles.extractAxesData(ax(1));
```

`plotData.axes` contains titles, labels, scales, directions, limits, grid and
aspect settings, color order, font settings, and colormap when available.
`plotData.objects` contains the graphics type, display name, coordinate/color
data, style fields, and object metadata. `plotData.warnings` lists skipped
objects.

## Errors And Limitations

- A FIG must contain a readable axes to enter the editing workflow.
- Reopening a project with an existing but damaged or unsupported FIG stops
  the restore and preserves the currently open document; it is not presented
  as an empty figure source.
- Invisible objects are not exported.
- Callbacks, application data, custom classes, and analysis provenance inside
  the source figure are not treated as portable scientific data.
- Some object-specific rendering semantics cannot be reproduced from a plain
  graphics snapshot.

## Related Functions And Documentation

- `figure_studio.resultFiles.extractAxesData`
- `figure_studio.resultFiles.exportAxesPackage`
- `figure_studio.resultFiles.createStyledFigure`
- [LabKit Core apps](../README.md)
- [Plotting framework](../../../framework/README.md)

## Framework Compatibility

This App's `definition.m` owns its product metadata, `labkit.app >=1 <2`
requirement, layout, and optional capabilities. `projectSpec.m` is the single
durable-schema entry and keeps project creation and validation local;
`createSession.m` separately rebuilds decoded FIG data because it is transient
runtime state. The entrypoint only adapts the optional axes handoff and
delegates to App SDK runtime. App code binds controls directly to semantic
callbacks and uses the sealed callback context for status, dialogs, project
operations, resources, and resolved paths; busy-state and portable-reference
serialization mechanics remain framework-owned.

The project validator requires the figure-source collection and checks style
and embedded-plot fields; Runtime validates canonical buckets and each source
record first.

Its session factory returns only App-specific source selection, status
workflow, and decoded plot cache fields. Runtime supplies absent canonical
buckets and owns workflow-log initialization.

The semantic layout follows the [Runtime callback contract](../../../framework/guides/runtime.md#layout-and-action-rules):
every control and plot names its concrete callback or renderer, and the
definition validates those bindings before creating a figure.
