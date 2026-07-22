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
snapshots, the selected subplot panel, style settings, and canvas settings.
Decoded source graphics are rebuilt after load, and the default output folder
follows the restored source.

## Load And Select Figures

On **Figures**, choose **Add FIG files or scan folder**. The source list accepts
MATLAB `.fig` files and keeps one current selection. Selecting another source
opens its native graphics without rerunning the analysis. A mixed FIG is
listed as ordered **Subplot panel** choices (top-left to bottom-right, with a
title where one exists). Select one panel to preview, restyle, recalculate, and
export exactly that axes; Studio never combines multiple panels into one output.
The plot-context-menu handoff already represents one axes, so it provides one
panel. **Clear figures** removes all sources from the project.

For a source using **FIG default**, Figure Studio adopts its font, semantic
line widths, annotations, legend, grid, and axes appearance. Selecting
**LabKit figure** applies the calibrated single-panel publication hierarchy
while retaining the source legend placement. Switching a text preset never
changes the selected plot-frame width, aspect, or export scale.

## Style And Canvas Controls

| Group | Controls |
| --- | --- |
| Text Style | preset, all/title/axis-label/tick/annotation font size, X tick-label angle, grid alpha, grid visibility |
| Lines + Boundaries | data, uncertainty, main-graphic boundary, reference-line, and axes line widths |
| Legend | source/on/off display, location, font size, columns, and border |
| Plot frame | reference, 6:5, 4:3, 16:9, 1:1, 3:2, or source aspect; a fixed plot width or source size; export supersampling; top/right frame visibility |

Changing **All font** updates title, axis-label, tick, annotation, and legend
sizes together. Individual controls then provide category-level refinement.
**LabKit figure** uses a calibrated 900-by-725 px reference **plot frame**:
45 pt title, axis-label, tick, annotation, and legend text; 6.5 pt data strokes;
2 pt uncertainty strokes; and 1.5 pt boundary, reference, and axes strokes.
The default uses a complete top/right frame with no grid and no legend box.
Legend samples use the reference's long line tokens. These editable baselines
come from normalized pixel measurements across all nine panels of the maintained
3-by-3 visual reference, not from a single imported FIG.
The configured width and aspect always describe the inside of the axes frame.
Figure Studio calculates the enclosing figure's outer margins from the current
title, labels, ticks, legend, and visible annotations, so changing a long
label cannot silently shrink the data region. Empty ruler text is ignored,
including the zero-area placeholders MATLAB exposes on logarithmic axes.
Choose **Source size** or one of
640, 720, 900, 960, 1200, 1237, 1364, 1600, or 2400 px; an aspect choice sets the
paired plot-frame height. The workbench preview is a real interactive axes,
not a raster image. When its allotted screen area changes, Studio reflows only
the display text and strokes; project settings and export proportions remain
unchanged. This calibration is validated on both 72-PPI Linux renderers and
96-PPI desktop MATLAB so display-density differences do not restyle exports.
**Export x** is raster supersampling only. **Top/right frame** only
shows or hides those two axes edges; it never changes the plot-frame size.

Font controls use 0.5 pt steps and line controls use 0.1 pt steps. The preset
styles every existing category but does not create or move a legend by default, because
either action can cover data. Use the Legend panel for those explicit layout
changes. **X tick labels** retains the source angle, makes labels horizontal,
or rotates them 45 degrees.

PNG and JPG resolution is `300 * Export x`, with a minimum of 72 dpi. SVG uses
vector content. **FIG default** records the source plot-frame ratio as its
reference, so reopening a source does not rescale its original typography. If
limits are stale after copying or editing, use **Recalculate X/Y limits** to
fit the visible graphics, update the interactive viewport, and refresh the
four limit inputs. The X/Y minimum and maximum controls accept values within
the finite visible-data extent expanded by exactly 50% on both sides; they do
not change the source calculation.

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
axes metadata, and a MATLAB recreation script. For preview, editable FIG
export, and image export, Studio first copies the selected native axes
hierarchy when MATLAB permits the parent transition. This preserves MATLAB
graphics that can be copied into the target axes, including ordinary grouped
charts such as `boxplot`. Native child stacking is retained, so lines, markers,
and text drawn over an image remain above that image in both the interactive
preview and exports. UIAxes sources are rebuilt into conventional export
axes from the portable snapshot, retaining the displayed scientific axis
exponents as well as visible data. The portable data package separately recognizes
visible line, bar, error-bar, area, scatter, image, surface, patch, rectangle,
text, and constant-line objects. Existing legend text, visibility, placement,
orientation, column count, font, interpreter, and border are retained.
Explicit axis ticks, tick labels, label rotations, axis locations, and tick
geometry are retained as visible presentation metadata. Visible graphics with
hidden handles, such as error bars or significance brackets intentionally
excluded from legends, are also retained without adding legend entries.
Portable-package unsupported graphics are skipped and reported as warnings;
the original FIG remains the authoritative source for object types that cannot
be represented in that portable package.

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
- A selected single axes is copied natively when MATLAB supports that parent
  transition. The portable data package remains deliberately narrower and is
  not a promise of pixel-identical reconstruction of every MATLAB chart class.
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
