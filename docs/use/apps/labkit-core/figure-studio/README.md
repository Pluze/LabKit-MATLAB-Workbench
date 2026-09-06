# Figure Studio

```labkit-page
id: app-figure-studio
type: landing
audience: app-user
summary: Turn visible MATLAB graphics into an editable scientific figure while preserving plotted values and allowing controlled presentation changes.
```

Figure Studio turns visible MATLAB graphics into an editable scientific-figure document. It preserves the plotted values while letting the user revise layout, axes, tick text, semantic graphic categories, individual objects, annotations, and publication output from one shared document model. It does not rerun or change the calculation that produced the source plot.

## Open Figure Studio

From the launcher, select **Figure Studio** and choose **Open**. From a source checkout, run:

```matlab
labkit_FigureStudio_app
```

A LabKit plot can also send its current axes directly through **Send this plot to Studio** in the plot context menu, or through the Studio button on a standalone popout. That handoff embeds a serializable snapshot and starts with the calibrated **LabKit figure** preset. Loading a `.fig` file retains **FIG default** as an alternative source-presentation baseline.

## Load Figures And Build A Multi-Panel Layout

On **Figures**, use **Add FIG files**, **Add folder**, or **Add folder tree**. The source list accepts MATLAB `.fig` files without rerunning their analyses. A mixed FIG exposes its axes in top-left-to-bottom-right order. The selected source panel becomes the active editing panel, and all imported panels belong to the same semantic document.

On **Canvas + Panels**, set the exact output width, height, and left, right, top, and bottom padding. Each panel has editable normalized X, Y, width, and height values plus optional shared-X and shared-Y group names. Duplicate or delete panels, make an automatic grid, align edges, equalize dimensions, or distribute spacing. Locked panels retain their geometry. The preview and every export consume the same panel rectangles and canvas dimensions.

## Edit Axes, Labels, And Every Tick

**Axes + Tick Labels** provides independent X, left Y, right Y, and Z controls. For each axis, edit scale, direction, displayed minimum and maximum, and axis position. Title, subtitle, X label, left Y label, right Y label, and Z label are plain editable text.

Tick location and tick formatting are separate decisions. Location modes are:

- **Auto**, which replans from the edited range;
- **Nice count**, which targets a readable count;
- **Fixed step**, which uses a declared interval;
- **Explicit**, which preserves the entered values.

Formatting can be automatic, fixed decimal, scientific, engineering, percent, or explicit text, with precision, prefix, and suffix controls. The tick table then exposes every individual value and label together with visibility, hierarchy level, rotation, font size, weight, and color. Add or remove rows and rewrite one label without changing its numeric position. Per-tick typography is represented by editable text objects when a MATLAB ruler cannot express it natively.

Changing a range refreshes all non-explicit ticks, so values newly inside the range receive labels and values outside it disappear. Adding an annotation beyond the current limits expands the affected range and replans its ticks. Log axes reject invalid nonpositive ranges and data rather than producing a misleading display. Dual-Y imports retain independent limits, labels, ticks, and object-side assignments; a low-confidence assignment appears in preflight for review.

Color-mapped panels expose colormap, color limits, colorbar visibility, location, label, tick values, and tick labels. Legends retain source content by default and expose display, placement, font size, columns, and border. The full-width **Legend** workspace page maps each original series name to its editable legend name, position, and **Show** checkbox. Enter a position to move a row without changing graphic stacking; uncheck Show to omit only its legend entry. Duplicate legend labels are allowed because rows remain attached to their plotted objects. Empty names are rejected; use Show to omit a row.

Legend edits join the document Undo/Redo history. Changing fonts, lines, presets, or other parameters preserves edited names, order, and row selection. The table, **Open figure** windows, clipboard copies, and file exports use the current legend. Turning global legend display Off keeps row edits for later On; unchecking every row leaves the legend empty even when global display is On. Each panel owns its own legend. The table edits supported data-series objects; annotations and images do not become artificial legend series.

Choosing a different source or panel, editing an axis range/scale/direction, or explicitly recalculating limits fits the preview to that coordinate domain. Typography, colors, ticks, labels, layers, legends, colorbars, and annotation edits preserve the region being inspected, including on dual-Y figures.

## Publication Style And Geometry

The high-value global controls remain intentionally small:

| Area | Controls |
| --- | --- |
| Text | preset; all, title, label, tick, annotation, and legend sizes; X-label angle |
| Scientific strokes | data, uncertainty, main-boundary, reference, and axes widths |
| Legend | original-to-new names, row position and inclusion; source/on/off, location, size, columns, and border |
| Plot frame | reference or common aspect; declared width; top/right frame; raster scale |
| Exact document | canvas width and height; four paddings; panel rectangles |

**LabKit figure** uses a calibrated 900-by-725 px reference plot frame with 45 pt title, label, tick, annotation, and legend text; 6.5 pt data strokes; 2 pt uncertainty strokes; and 1.5 pt boundary, reference, and axes strokes. The hierarchy comes from normalized measurements across the maintained nine-panel published-figure reference. It uses a complete top/right frame, no grid, no legend box, long legend line tokens, white-ground bars with semantic boundary colors, and automatic wrapping for long categorical X labels.

The configured geometry describes the axes frame rather than allowing long text to shrink it. Studio reserves outer margins from the visible title, labels, ticks, legend, annotations, and renderer-specific minimums. Preview, editable FIG, vector, and raster output therefore share the approved frame, tick set, text-to-plot proportion, and semantic line hierarchy. Raster output uses `300 * Export x` dpi with a 72 dpi minimum; SVG remains vector content.

Use **Import style** and **Export style** to reuse the document-, type-, and role-level presentation baseline in another figure. The style file has a validated Figure Studio schema; source data and object-specific edits are not smuggled into a reusable style.

## Publication Preflight

Preflight reports **ready**, **review**, or **blocked** and supplies a suggested fix for each issue. It checks invalid canvas padding, panels outside the canvas, panel overlap, nonpositive log data, missing axis labels, ambiguous dual-Y assignment, visible objects outside limits, unusually small text or thin strokes, and import warnings. For dual-Y panels, each series is checked against its assigned Y axis, including that axis's logarithmic scale and displayed limits. Blocking errors stop publication export. Warnings remain visible so the user can make an informed scientific-layout decision.

## Exports And Editable Package

The **Figure** tab provides **Open figure**, which opens a detached editable MATLAB figure containing every panel and the current legend names, order and inclusion. Open it again after further edits to obtain a new current copy; existing output windows remain independent and survive closing Studio. Use this command for a complete Studio figure; the framework axes context-menu popout is a single-axis copy and does not retain custom legend order.

The **Figure** tab provides **Copy figure**, which copies the complete styled document, including every panel, to the clipboard as one raster image at the configured export scale. It uses the same publication preflight and layout as file export; blocking issues must be resolved first. Copying does not change file-export destinations or result records.

The **Figure** tab also provides editable FIG, PNG, JPG, and SVG output. **Export editable package** writes:

- `figure_studio_project.mat`, containing the semantic document, style, and preflight report;
- `figure_document.json` and `preflight.json` for language-neutral inspection;
- `editable_figure.fig`, containing the complete editable MATLAB figure;
- one folder per panel with visible plot data and a standalone MATLAB reconstruction script;
- `manifest.json` and a package README.

The supported portable graphics include line, scatter, bar, error bar, box-chart, area, patch, image, surface, rectangle, text, and constant-line objects. Direct App UI-axes and dual-Y handoffs use the portable snapshot because MATLAB cannot natively clone all such axes. Native copying remains the fidelity path for copyable ordinary MATLAB grouped graphics, while the semantic portable path drives deterministic editing, multi-panel assembly, scripts, and audit data. Visible child stacking, legend participation, logarithmic notation, dual Y axes, explicit ticks, and colorbars are retained. Unsupported objects stay native when possible and generate an explicit warning; they are never silently presented as portable data.

The package records displayed graphics in layer order. It supports audit, handoff, and plot recreation, but it does not reconstruct hidden measurements, callbacks, application data, custom chart internals, or analysis provenance.

## Document And Selection Model

The editable document contains an exact pixel canvas, one or more normalized panels, axes and color metadata, visible graphic nodes, semantic groups, style rules, selection, warnings, and command history. Source plot coordinates are locked: presentation edits cannot silently mutate measured values. Annotations created in Studio are unlocked and can be moved, resized, duplicated, grouped, ordered, or deleted.

Style resolution follows this order:

1. source appearance;
2. document rule;
3. graphic-type rule;
4. semantic-role rule;
5. group rule;
6. individual-object override.

The **Objects + Layers** table exposes visibility, lock state, legend participation, graphic type, inferred role, name, group, and left/right Y-axis assignment. Select several elements to apply one edit to the selection, its type, role, group, or the full document. A mixed selection remains mixed until the user assigns a value. **Reset to parent** removes the selected override instead of copying a stale default. Objects can be grouped, ungrouped, duplicated, reordered, numerically moved or scaled, aligned, and distributed.

Studio recognizes common LabKit roles such as data series, uncertainty bands, graphic boundaries, reference lines, analysis windows, significance brackets and labels, scale bars, measurement points, trajectories, and skeleton segments. Related primitives are recovered as compound groups when the source geometry and metadata make that relationship clear. Ambiguous classifications remain editable and are reported by preflight instead of being silently treated as authoritative.

## Add Scientific Annotations

The **Annotations** section creates text, arrows, reference lines, regions, scale bars, significance brackets, and labeled measurements in data coordinates. Scale bars, brackets, and measurements are compound objects: edit the whole group for category-level changes or select a child line, point, or label for fine control. The selected editable annotation can also be dragged or resized directly in the preview. Every change is recorded by the shared undo/redo history.

## Programmatic Data Extraction

```matlab
fig = openfig("result.fig", "invisible");
cleanup = onCleanup(@() close(fig));
ax = findobj(fig, "Type", "axes", "-depth", 1);

plotData = figure_studio.resultFiles.extractAxesData(ax(1));
```

`plotData.axes` contains labels, limits, scales, directions, ticks, dual-Y rulers, grid and frame state, legend, colorbar, color limits, color order, font settings, and colormap. `plotData.objects` contains graphic type, semantic name, displayed coordinates and colors, style, axis side, and source-group metadata. `plotData.warnings` lists objects that could not enter the portable contract.

## Related Functions And Documentation

- `figure_studio.resultFiles.extractAxesData`
- `figure_studio.resultFiles.exportAxesPackage`
- `figure_studio.resultFiles.createStyledFigure`
- [LabKit Core apps](../README.md)
- [Plotting framework](../../../../develop/framework/README.md)

## Errors And Limitations

- A FIG must contain a readable axes; a damaged source is rejected without replacing the current selection.
- Invisible objects are not exported as visible scientific graphics.
- Source data coordinates remain locked. Change the originating analysis when the scientific values themselves must change.
- Automatic role and dual-axis inference cannot recover intent that is absent from both graphics metadata and geometry; verify preflight warnings.
- Custom chart classes and some object-specific native rendering semantics may remain locked native content instead of editable portable nodes.
- The editable snapshot is not a replacement for the source dataset or the code that generated it.
