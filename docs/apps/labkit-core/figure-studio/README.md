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
context menu. That handoff embeds a serializable plot snapshot in the project
and immediately applies the **LabKit figure** preset. The source style remains
available through **FIG default**.

## Project And Handoff

A plot-context-menu handoff creates the same editable project state as loading
a FIG file. Saved projects retain portable FIG sources, embedded plot
snapshots, style settings, and canvas settings. Decoded FIG graphics are
rebuilt after load, and the default output folder follows the restored source.

## Load And Select Figures

On **Figures**, choose **Add FIG files or scan folder**. The source list accepts
MATLAB `.fig` files and keeps one current selection. Selecting another source
loads that figure's plot snapshot and original style. **Clear figures** removes
all sources from the project.

For a source using **FIG default**, Figure Studio adopts its font, semantic
line widths, annotations, legend, grid, canvas, and axes appearance. Selecting
**LabKit figure** applies the calibrated 720-by-600 reference canvas and
publication hierarchy while retaining the source legend placement. The source
canvas and presentation remain available by switching back to **FIG default**.

## Style And Canvas Controls

| Group | Controls |
| --- | --- |
| Text Style | preset, all/title/axis-label/tick/annotation font size, X tick-label angle, grid alpha, grid visibility |
| Lines + Boundaries | data, uncertainty, main-graphic boundary, reference-line, and axes line widths |
| Legend | source/on/off display, location, font size, columns, and border |
| Canvas | 6:5, 4:3, 16:9, 1:1, 3:2, or custom aspect; width; height; export scale; boundary visibility |

Changing **All font** updates title, axis-label, tick, annotation, and legend
sizes together. Individual controls then provide category-level refinement.
**LabKit figure** uses a calibrated 720-by-600 reference canvas: 24 pt title
and axis labels, 20 pt ticks and annotations, 15 pt legend text, 1.1 pt graphic
and uncertainty boundaries, and 1.2 pt data, reference, and axes lines. These
are editable baseline values, not fixed output sizes. Text and strokes scale
with the smaller width/height ratio relative to the reference canvas. A
1440-by-1200 output therefore doubles them, while a 360-by-300 output halves
them. Preview fitting compensates for that canvas scale so changing export
dimensions does not make the on-screen preview jump in apparent size.

Font controls use 0.5 pt steps, line controls use 0.1 pt steps, and canvas
dimensions use 10 px steps for precise adjustment. The preset styles every
existing category but does not create or move a legend by default, because
either action can cover data. Use the Legend panel for those explicit layout
changes. **X tick labels** retains the source angle, makes labels horizontal,
or rotates them 45 degrees.

Canvas width and height are stored as project parameters. PNG and JPG
resolution is `300 * Export x`, with a minimum of 72 dpi. SVG uses vector
content. **FIG default** records the source figure's own canvas as its
reference, so reopening a source does not rescale its original typography.

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
axes metadata, and a MATLAB recreation script. The extractor recognizes
visible line, bar, error-bar, area, scatter, image, surface, patch, rectangle,
text, and constant-line objects. Existing legend text, visibility, placement,
orientation, column count, font, interpreter, and border are retained.
Explicit axis ticks, tick labels, label rotations, axis locations, and tick
geometry are retained as visible presentation metadata. Visible graphics with
hidden handles, such as error bars or significance brackets intentionally
excluded from legends, are also retained without adding legend entries.
Unsupported graphics are skipped and reported as warnings.

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

`plotData.axes` contains titles, labels, ticks, tick labels, scales, directions,
limits, grid and aspect settings, color order, font settings, and colormap
when available.
`plotData.objects` contains the graphics type, display name, coordinate/color
data, style fields, and object metadata. `plotData.warnings` lists skipped
objects.

## Errors And Limitations

- A FIG must contain a readable axes to enter the editing workflow.
- Reopening a project with an existing but damaged or unsupported FIG stops
  the restore and preserves the currently open document; it is not presented
  as an empty figure source.
- Invisible objects are not exported.
- Figure Studio preserves supported visible elements rather than promising a
  pixel-identical copy of every MATLAB chart class.
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
