# UI Library

`labkit.ui.*` is the reusable MATLAB GUI foundation. It provides a standard workbench shape and domain-neutral UI helpers for lab-internal tools.

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
labkit.ui.createResultTablePanel(parent, titleText, row, columnNames, initialData);
labkit.ui.createLogPanel(parent, row, initialValue);
```

State and rendering helpers:

```matlab
labkit.ui.appendLog(txtLog, message);
[value, idx] = labkit.ui.refreshListboxSelection(lbFiles, names, preferredSelection, opts);
info = labkit.ui.plotXY(ax, x, y, labels, opts);
```

Use `createPanelGrid` for app-defined sections that only need the standard panel/grid styling. Use `refreshListboxSelection` for generic single- or multi-select listbox state updates.

Use `tabSpec(..., struct('resizeRows', ...))` when a left tab contains several stacked app-defined sections that may need manual height adjustment. When manually placing a component directly into a workbench tab grid, map the logical row through `labkit.ui.layoutRow(parentGrid, row)`. Most app code should use helpers such as `createPanelGrid`, `createResultTablePanel`, `createLogPanel`, and `createAxes`, which apply that mapping for their parent row. `labkit.ui.addRowResizeHandle` remains a lower-level helper for unusual app-local grids that intentionally reserve a physical handle row.

## Ownership Boundary

`labkit.ui.*` may provide:

- workbench shell creation
- tab specification helpers
- file-selection panels
- log panels and log append helpers
- panel/grid construction
- row-resize handles for stacked app-defined sections
- plot axes creation, reset, and prepared-X/Y plotting
- result table panels
- listbox selection refresh
- small labeled controls and domain-neutral state helpers

`labkit.ui.*` should not own:

- experiment names
- formulas, thresholds, or analysis definitions
- parser calls or file-format assumptions
- result field definitions
- export schemas
- app-specific callback choreography

Apps pass labels, callbacks, prepared vectors, table data, and option values into the GUI helpers. Reusable GUI helpers exist to remove MATLAB UI boilerplate, not to hide the domain workflow.
