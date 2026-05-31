# UI Library

`labkit.ui.*` is the reusable MATLAB GUI foundation. It provides a standard workbench shape and domain-neutral UI helpers for lab-internal tools.

The UI library should stay small and app-neutral. It owns reusable layout and interaction mechanics; apps own scientific workflow, wording, result definitions, plotting choices, and exports.

## Standard App Shell

Every app should start from the same basic shell:

```text
left side:  resizable tabbed controls
right side: live plots, images, tables, or primary output
```

The default left tabs are:

```text
Files + Analysis
Summary + Results
Log
```

Apps may pass custom tab specs when a workflow needs different pages. The app still owns the controls inside each tab.
The left tab host and each tab content grid are scrollable, so app-specific sections can extend below the visible window without hiding controls.
Tabs can also declare draggable row boundaries through `resizeRows`; this is a shell-level behavior, and app code should continue to use logical grid row numbers.

## Core Entry Point

Use `labkit.ui.createWorkbench` for both small and large apps:

```matlab
opts = struct();
opts.rightTitle = 'Plots';
opts.rightGridSize = [1 1];
opts.rightRowHeight = {'1x'};
ui = labkit.ui.createWorkbench(titleText, position, leftWidth, opts);

dualOpts = struct('rightKind', 'dualPlot');
ui = labkit.ui.createWorkbench(titleText, position, leftWidth, dualOpts);

imageOpts = struct('rightKind', 'dualPlot', 'showPlotControls', false);
ui = labkit.ui.createWorkbench(titleText, position, leftWidth, imageOpts);
```

Use `opts.rightKind = 'dualPlot'` for the common top/bottom live-plot layout. By default it includes small top/bottom control panels for axis selectors and plot options. Set `opts.showPlotControls = false` for image/overlay apps that only need the two output axes; this avoids empty control rows compressing the plot area.

For custom right-side arrangements, pass `rightGridSize`, `rightRowHeight`, and `rightRowSpacing`.

App files should not rebuild split-pane layout plumbing or own their own separator-drag behavior.

Custom left-tab sizing is declared in the tab spec:

```matlab
opts.tabs = labkit.ui.tabSpec( ...
    'filesAnalysis', 'Files + Analysis', [4 1], ...
    {240, 210, 330, 170}, ...
    struct('resizeRows', [1 2 3]));
```

Here `resizeRows = [1 2 3]` means the user can drag the boundaries after logical rows 1, 2, and 3. The framework may create internal handle rows, but app code still places sections in rows 1 through 4 through LabKit layout helpers.

## Common Helpers

Construction helpers:

```matlab
labkit.ui.createFileSelectionPanel(parent, labels, callbacks, opts);
labkit.ui.createPanelGrid(parent, titleText, row, gridSize, opts);
labkit.ui.createPlotOptionsPanel(parent, numRows, row);
labkit.ui.createTopBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, onChange);
labkit.ui.createLabeledDropdown(parent, labelText, ...);
labkit.ui.createLabeledEditField(parent, labelText, style, ...);
labkit.ui.createLabeledSpinner(parent, labelText, ...);
labkit.ui.createReadOnlyTextField(parent, ...);
labkit.ui.createReadOnlyTextPanel(parent, titleText, row, lines, opts);
labkit.ui.createResultTablePanel(parent, titleText, row, columnNames, initialData);
labkit.ui.createLogPanel(parent, row, initialValue);
labkit.ui.createAnchorCurveEditor(ax, imageSize, opts);
```

State and rendering helpers:

```matlab
labkit.ui.appendLog(txtLog, message);
[value, idx] = labkit.ui.refreshListboxSelection(lbFiles, names, preferredSelection, opts);
info = labkit.ui.plotXY(ax, x, y, labels, opts);
labkit.ui.enableAxesPopout(ax);
fig = labkit.ui.popoutAxes(ax);
hImage = labkit.ui.showImageAxes(ax, imageData, titleText);
```

Use `createPanelGrid` for app-defined sections that only need the standard panel/grid styling. Fixed-height parent tab rows are automatically grown when the declared height is smaller than the section's estimated control height, so default app startup layouts should avoid clipping controls while still allowing user row resizing and scrolling. Use `createLabeledSpinner` for numeric settings that should support click/step adjustment, `createReadOnlyTextField` for single-line status or path display, and `createReadOnlyTextPanel` for app-owned usage notes, file previews, or other read-only multiline text. Use `refreshListboxSelection` for generic single- or multi-select listbox state updates.

Axes created through `labkit.ui.createAxes`, workbench dual-plot shells, or reset with `labkit.ui.hardResetAxis` get a standard right-click context action named `Open axes in new figure`. The same context menu is attached to plotted child objects such as images, lines, overlays, and ROI previews so image-heavy apps do not block the action. MATLAB does not reliably propagate axes context menus to graphics children created later, so app-local renderers that create new image or overlay objects should call `labkit.ui.enableAxesPopout(ax)` after drawing. It copies the current axes contents, labels, scales, grid state, and basic styling into a separate MATLAB figure for manual editing or export. The copied axes use automatic data and plot-box aspect-ratio modes so the standalone figure can be freely resized. Apps should not implement their own plot-popout behavior unless they need a domain-specific export workflow.

Use `showImageAxes` for app-neutral image display boilerplate: it draws an image, uses image-style axes limits, hides ticks, enables standard image navigation, and refreshes the axes popout menu onto the image object. Apps still own how image arrays, overlays, masks, and annotations are computed.

Use `tabSpec(..., struct('resizeRows', ...))` when a left tab contains several stacked app-defined sections that may need manual height adjustment. When manually placing a component directly into a workbench tab grid, map the logical row through `labkit.ui.layoutRow(parentGrid, row)`. Most app code should use helpers such as `createPanelGrid`, `createResultTablePanel`, `createLogPanel`, and `createAxes`, which apply that mapping for their parent row. `labkit.ui.addRowResizeHandle` remains a lower-level helper for unusual app-local grids that intentionally reserve a physical handle row.

Use `createAnchorCurveEditor` when an app needs DIC-style image anchor editing: double-click blank image space to add or insert anchors, drag anchors to move them, double-click anchors to delete them, switch between curve and straight-line preview, constrain the maximum point count for tools such as two-endpoint scale bars, and optionally install scroll-wheel zoom on the image axes. The helper owns generic interaction and preview graphics only; apps still own mask construction, scale bars, fitting, analysis, and exports.

## Ownership Boundary

`labkit.ui.*` may provide:

- workbench shell creation
- tab specification helpers
- file-selection panels
- log panels and log append helpers
- panel/grid construction
- row-resize handles for stacked app-defined sections
- anchor-curve editing on image axes
- plot axes creation, reset, prepared-X/Y plotting, and app-neutral axes popout
- app-neutral image display boilerplate for prepared image arrays
- result table panels
- listbox selection refresh
- small labeled controls, read-only text surfaces, and domain-neutral state helpers

`labkit.ui.*` should not own:

- experiment names
- formulas, thresholds, or analysis definitions
- parser calls or file-format assumptions
- result field definitions
- export schemas
- app-specific callback choreography

Apps pass labels, callbacks, prepared vectors, table data, and option values into the GUI helpers. Reusable GUI helpers exist to remove MATLAB UI boilerplate, not to hide the domain workflow.

Do not add a UI helper only because one app got large. Extract UI code when the behavior is generic, stable across real apps, and easier to test as a domain-neutral helper than as app-local code.

## UI Validation

Reusable UI helper and shell contracts are covered by local noninteractive GUI profiles:

```bash
scripts/run_matlab_tests.sh --profile ui
scripts/run_matlab_tests.sh --suite gui
```

These checks require MATLAB graphics/uifigure support and are not part of the default GitHub Actions job. The CI job runs the non-GUI suite; final interactive behavior is validated manually in the app windows.
