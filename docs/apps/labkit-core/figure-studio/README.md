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
and immediately applies the **Published figure** preset. Studio restores a
publication-oriented plot frame, typography hierarchy, and semantic stroke
weights. It preserves authored data colors, line styles, markers, bar fills,
annotation positions, and axis ranges. The complete source presentation
remains available through **FIG default**.

## Handoff And Runtime State

A plot-context-menu handoff creates the same editable runtime state as loading
a FIG file. FIG sources, embedded plot snapshots, the selected subplot panel,
style settings, and canvas settings remain in memory while the App is open.
The default output folder follows the selected source.

## Load And Select Figures

On **Figure**, use **Add FIG files**, **Add folder**, or **Add folder tree**.
The source list accepts MATLAB `.fig` files and keeps one current selection. Selecting another source
opens its native graphics without rerunning the analysis. A mixed FIG is
listed as ordered **Subplot panel** choices (top-left to bottom-right, with a
title where one exists). Select one panel to preview, restyle, recalculate, and
export exactly that axes; Studio never combines multiple panels into one output.
The plot-context-menu handoff already represents one axes, so it provides one
panel. **Clear figures** removes all sources from the project.

For a source using **FIG default**, Figure Studio adopts its font, semantic
line widths, annotations, legend, grid, and axes appearance. Selecting
**Published figure** applies the maintained single-panel publication
hierarchy while retaining the source legend placement and authored object
appearance. When a new source or subplot is selected, Studio reapplies the
standard frame and typography without inferring scientific meaning from line
length, handle visibility, color, or object position. Logarithmic axes retain
MATLAB's native exponent formatting.
Switching a text preset never changes the selected plot-frame width, aspect,
outside-whitespace choice, or export scale.

## Editing And Output Controls

The control panel follows the workflow in four tabs: **Figure** loads one
panel and edits its axes; **Appearance** controls calibrated text, strokes,
frame, grid, and legend; **Geometry** controls the inner plot frame and outside
whitespace; **Export** writes the styled figure or a portable data package.

| Group | Controls |
| --- | --- |
| Axes | title, X/Y labels, unrestricted finite X/Y limits, linear/log scale, and normal/reverse direction |
| Text Style | preset, title/axis-label/tick/annotation font size, X tick-label angle, and grid visibility |
| Lines + Boundaries | data, uncertainty, main-graphic boundary, reference-line, and axes line widths; tick direction; top/right frame visibility |
| Legend | source/on/off display, location, font size, columns, and border |
| Output Geometry | published, source, 4:3, 3:2, 16:9, 1:1, or custom ratio; numeric frame width and height; tight, balanced, or generous outside whitespace |

**Published figure** retains the measured nine-panel reference **plot frame**
and visual calibration: a 900-by-725 px inner frame; 45 pt title, axis-label,
tick, annotation, and legend text; a 100 px legend token; 6.5 pt data strokes;
2 pt uncertainty strokes; and 1.5 pt boundary, reference, and axes strokes.
The calibration was derived by normalizing each reference panel to its detected
axes frame and comparing registered typography and strokes in pixels.
The default uses a complete top/right frame with no grid and no legend box.
Legend samples use long line tokens. These values are an editable visual
baseline, not a transformation of the source data or a journal-specific
template.
The configured width and aspect always describe the inside of the axes frame.
The interactive preview and every exported format use that same configured
plot-box aspect; a source axes' stored aspect metadata does not override it.
Native FIG and graphic exports also retain the tick positions and labels shown
in the preview instead of asking MATLAB to choose a sparser set for the
full-size export typography.
Figure Studio calculates the enclosing figure's outer margins from the current
title, labels, ticks, legend, and visible annotations, so changing a long
label cannot silently shrink the data region. **Outside whitespace** adds a
tight, balanced, or generous typography-relative margin beyond those measured
extents without changing the inner plot frame. Empty ruler text is ignored,
including the zero-area placeholders MATLAB exposes on logarithmic axes. If a
Windows desktop refuses the requested hidden figure size, Studio recomputes
the plot frame from the accepted canvas after reserving measured label and tick
insets plus a typography-derived minimum outer margin. Older Windows `print`
releases reserve one additional text line because their pre-print screen extent
can omit that line from the hardcopy bounds.
Enter the required frame width directly. While a named ratio is active, width
changes calculate the paired height; editing height selects **Custom** and
leaves both dimensions under explicit control. **Published** restores the
measured 900-by-725 ratio, while **Source** uses the imported axes ratio. The
workbench preview is a real interactive axes,
not a raster image. When its allotted screen area changes, Studio reflows only
the display text and strokes; project settings and export proportions remain
unchanged. This calibration is validated on both 72-PPI Linux renderers and
96-PPI desktop MATLAB so display-density differences do not restyle exports.
**Top/right frame** only shows or hides those two axes edges; it never changes
the plot-frame size.

Font controls use 0.5 pt steps and line controls use 0.1 pt steps. The preset
styles every existing category but does not create or move a legend by default, because
either action can cover data. Use the Legend panel for those explicit layout
changes. **X tick labels** retains the source angle, makes labels horizontal,
or rotates them 45 degrees.

PNG and JPG use the calibrated 600 dpi default; SVG uses vector content. On
MATLAB releases before R2025a, Figure Studio uses MATLAB's
native `print` exporter to retain the complete styled figure because
`exportgraphics` does not yet support figure padding or SVG. **FIG default**
records the source plot-frame ratio as its
reference, so reopening a source does not rescale its original typography.
Edit the four limit inputs to show any finite ascending range, including a
range outside the currently visible data. Figure Studio does not clamp an
explicit viewport to a data-derived envelope. If limits are stale after
copying or editing, use **Recalculate X/Y limits** to fit the visible graphics,
update the interactive viewport, and refresh the inputs. Axis and text changes
refresh the same deterministic renderer used for export.

## Figure Exports

The **Export** tab provides:

- **Editable FIG** for an editable MATLAB figure;
- **PNG** and **JPG** for raster output;
- **SVG** for vector output.

## Export A Data Package

On **Export**, select a package folder and choose **Export data + script**.
Figure Studio creates a package containing supported visible data, style and
axes metadata, and a MATLAB recreation script. For preview, editable FIG
export, and image export, Studio uses one renderer and first copies the
selected native axes hierarchy when MATLAB permits the parent transition. This preserves MATLAB
graphics that can be copied into the target axes, including ordinary grouped
charts such as `boxplot`. Native child stacking is retained, so lines, markers,
and text drawn over an image remain above that image in both the interactive
preview and exports. UIAxes sources are rebuilt into conventional export
axes from the portable snapshot, retaining the displayed scientific axis
exponents as well as visible data. The portable data package separately recognizes
visible line, bar, error-bar, area, scatter, image, surface, patch, rectangle,
text, and constant-line objects. Existing legend text, visibility, placement,
orientation, column count, font, interpreter, and border are retained.
Explicit titles, labels and their text interpreters, ranges, scales,
directions, ticks, tick labels, label rotations, axis locations, and tick
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
- A damaged or unsupported FIG is rejected without replacing the current
  in-memory source selection.
- Invisible objects are not exported.
- A selected single axes is copied natively when MATLAB supports that parent
  transition. The portable data package remains deliberately narrower and is
  not a promise of pixel-identical reconstruction of every MATLAB chart class.
- Callbacks, application data, custom classes, and analysis provenance inside
  the source figure are not treated as portable scientific data.
- Some object-specific rendering semantics cannot be reproduced from a plain
  graphics snapshot.
- Figure Studio edits one selected axes at a time. It does not yet provide a
  general property inspector for every MATLAB graphics class.

## Related Functions And Documentation

- `figure_studio.resultFiles.extractAxesData`
- `figure_studio.resultFiles.exportAxesPackage`
- `figure_studio.resultFiles.createStyledFigure`
- [LabKit Core apps](../README.md)
- [Plotting framework](../../../framework/README.md)
