function test_gui_layout_ui_helpers()
%TEST_GUI_LAYOUT_UI_HELPERS Verify reusable UI helper layout contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures()); %#ok<NASGU>

    checkListboxItemsRefreshHelper(h);
    checkListboxSelectionHelper(h);
    checkLabeledSpinnerHelper();
    checkLogPanelHelper(h);
    checkReadOnlyTextHelpers(h);
    checkReadOnlyInfoRowHelper();
    checkResultTablePanelHelper(h);
    checkPanelGridHelper(h);
    checkPlotOptionsPanelHelper(h);
    checkCreateAxesHelper(h);
    checkAnchorCurveEditorHelper();
    checkRowResizeHandleHelper(h);
    checkCreateWorkbenchHelper(h);
    checkTopBottomPlotControlsHelper(h);
    checkTopBottomPlotStateHelpers(h);
    checkRunWithBusyStateHelper();
    checkFileSelectionPanelHelper(h);
end

function checkListboxItemsRefreshHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_file_listbox_refresh_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    lb = uilistbox(fig, 'Items', {}, 'Multiselect', 'on');

    labkit.ui.refreshListboxItems(lb, {'a.DTA', 'b.DTA'});
    assert(h.sameStringCell(lb.Items, {'a.DTA', 'b.DTA'}), ...
        'File listbox helper should populate item display names.');
    assert(h.sameStringCell(lb.Value, {'a.DTA', 'b.DTA'}), ...
        'File listbox helper should select all items when there is no prior selection.');

    lb.Value = {'b.DTA'};
    labkit.ui.refreshListboxItems(lb, {'b.DTA', 'c.DTA'});
    assert(h.sameStringCell(lb.Items, {'b.DTA', 'c.DTA'}), ...
        'File listbox helper should update item display names.');
    assert(h.sameStringCell(lb.Value, {'b.DTA'}), ...
        'File listbox helper should preserve valid prior selections.');

    labkit.ui.refreshListboxItems(lb, {});
    assert(isempty(lb.Items) && isempty(lb.Value), ...
        'File listbox helper should clear listbox items and values for empty sessions.');
end

function checkListboxSelectionHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_file_listbox_selection_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    singleList = uilistbox(grid, 'Items', {}, 'Multiselect', 'off');
    [value, idx] = labkit.ui.refreshListboxSelection(singleList, {'a.DTA', 'b.DTA'}, []);
    assert(strcmp(value, 'a.DTA') && idx == 1, ...
        'Listbox selection helper should select the first single-select item by default.');

    [value, idx] = labkit.ui.refreshListboxSelection(singleList, {'b.DTA', 'c.DTA'}, 2);
    assert(strcmp(value, 'c.DTA') && idx == 2, ...
        'Listbox selection helper should accept a preferred single-select index.');

    multiList = uilistbox(grid, 'Items', {}, 'Multiselect', 'on');
    [value, idx] = labkit.ui.refreshListboxSelection( ...
        multiList, {'x.DTA', 'y.DTA'}, {}, struct('defaultSelection', 'all'));
    assert(h.sameStringCell(value, {'x.DTA', 'y.DTA'}) && isequal(idx, [1 2]), ...
        'Listbox selection helper should support selecting all multi-select items by default.');

    [value, idx] = labkit.ui.refreshListboxSelection( ...
        multiList, {'y.DTA', 'z.DTA'}, {'y.DTA', 'missing.DTA'}, ...
        struct('defaultSelection', 'all'));
    assert(h.sameStringCell(value, {'y.DTA'}) && isequal(idx, 1), ...
        'Listbox selection helper should preserve only valid multi-select choices.');
end

function checkLogPanelHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_log_panel_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    ui = labkit.ui.createLogPanel(grid, 2, {'Started.'});
    assert(strcmp(ui.panel.Title, 'Log'), 'Log panel helper should preserve the panel title.');
    assert(ui.panel.Layout.Row == 2, 'Log panel helper should place the panel in the requested row.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), 'Log panel helper should preserve grid padding.');
    assert(strcmp(ui.textArea.Editable, 'off'), 'Log panel helper should create a read-only text area.');
    assert(h.sameStringCell(ui.textArea.Value, {'Started.'}), ...
        'Log panel helper should preserve supplied initial log text.');
end

function checkLabeledSpinnerHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_labeled_spinner_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [1 2]);

    [lbl, spinner] = labkit.ui.createLabeledSpinner(grid, 'Probe value:', ...
        'Value', 2, 'Limits', [0 10], 'Step', 0.5);
    assert(strcmp(lbl.Text, 'Probe value:'), ...
        'Labeled spinner helper should preserve label text.');
    assert(strcmp(lbl.HorizontalAlignment, 'right'), ...
        'Labeled spinner helper should right-align labels.');
    assert(spinner.Value == 2 && isequal(spinner.Limits, [0 10]) && spinner.Step == 0.5, ...
        'Labeled spinner helper should pass spinner options through.');
end

function checkReadOnlyTextHelpers(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_read_only_text_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    field = labkit.ui.createReadOnlyTextField(grid, 'Value', 'Status');
    field.Layout.Row = 1;
    assert(strcmp(field.Editable, 'off') && strcmp(field.Value, 'Status'), ...
        'Read-only text field helper should create a non-editable text field.');

    panelUi = labkit.ui.createReadOnlyTextPanel(grid, 'Notes', 2, {'one', 'two'});
    assert(strcmp(panelUi.panel.Title, 'Notes'), ...
        'Read-only text panel helper should preserve the panel title.');
    assert(strcmp(panelUi.textArea.Editable, 'off') && ...
        h.sameStringCell(panelUi.textArea.Value, {'one', 'two'}), ...
        'Read-only text panel helper should preserve read-only text lines.');
end

function checkReadOnlyInfoRowHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_read_only_info_row_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 2]);

    [field, lbl] = labkit.ui.createReadOnlyInfoRow(grid, 2, 'Probe:');
    assert(strcmp(lbl.Text, 'Probe:'), 'Read-only info row should preserve label text.');
    assert(strcmp(lbl.HorizontalAlignment, 'right'), ...
        'Read-only info row should preserve right-aligned labels.');
    assert(lbl.Layout.Row == 2 && lbl.Layout.Column == 1, ...
        'Read-only info row should place the label in the requested row and first column.');
    assert(field.Layout.Row == 2 && field.Layout.Column == 2, ...
        'Read-only info row should place the field in the requested row and second column.');
    assert(strcmp(field.Editable, 'off'), ...
        'Read-only info row should create a read-only field.');
    assert(strcmp(field.Value, '-'), ...
        'Read-only info row should preserve the default empty summary value.');
end

function checkResultTablePanelHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_result_table_panel_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    ui = labkit.ui.createResultTablePanel(grid, 'Batch Results', 2, ...
        {'File', 'Value'}, cell(0, 2));
    assert(strcmp(ui.panel.Title, 'Batch Results'), ...
        'Result table panel helper should preserve the panel title.');
    assert(ui.panel.Layout.Row == 2, ...
        'Result table panel helper should place the panel in the requested row.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), ...
        'Result table panel helper should preserve grid padding.');
    assert(h.sameStringCell(ui.table.ColumnName, {'File', 'Value'}), ...
        'Result table panel helper should preserve supplied column names.');
    assert(isequal(size(ui.table.Data), [0 2]), ...
        'Result table panel helper should preserve supplied empty table width.');
end

function checkPanelGridHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_panel_grid_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    ui = labkit.ui.createPanelGrid(grid, 'Probe Panel', 2, [3 2]);
    assert(strcmp(ui.panel.Title, 'Probe Panel'), ...
        'Panel-grid helper should preserve the requested panel title.');
    assert(ui.panel.Layout.Row == 2, ...
        'Panel-grid helper should place the panel in the requested row.');
    assert(h.sameStringCell(ui.grid.RowHeight, {'fit', 'fit', 'fit'}), ...
        'Panel-grid helper should default to fit-height rows.');
    assert(h.sameStringCell(ui.grid.ColumnWidth, {'fit', '1x'}), ...
        'Panel-grid helper should default two-column controls to label/value widths.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), ...
        'Panel-grid helper should preserve standard padding.');

    opts = struct('columnWidth', {{'1x', '1x'}}, 'padding', [0 0 0 0]);
    ui2 = labkit.ui.createPanelGrid(grid, 'Actions', 1, [2 2], opts);
    assert(h.sameStringCell(ui2.grid.ColumnWidth, {'1x', '1x'}), ...
        'Panel-grid helper should support explicit action-column widths.');
    assert(isequal(ui2.grid.Padding, [0 0 0 0]), ...
        'Panel-grid helper should support explicit padding.');

    growGrid = uigridlayout(fig, [1 1]);
    growGrid.RowHeight = {50};
    labkit.ui.createPanelGrid(growGrid, 'Tall Controls', 1, [5 2]);
    assert(growGrid.RowHeight{1} > 50, ...
        'Panel-grid helper should grow undersized fixed parent rows to avoid clipped controls.');
end

function checkPlotOptionsPanelHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_plot_options_panel_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [3 1]);

    ui = labkit.ui.createPlotOptionsPanel(grid, 3);
    assert(strcmp(ui.panel.Title, 'Plot Options'), 'Plot-options helper should preserve the panel title.');
    assert(ui.panel.Layout.Row == 3, 'Plot-options helper should place the panel in row 3.');
    assert(h.sameStringCell(ui.grid.RowHeight, {'fit', 'fit', 'fit'}), ...
        'Plot-options helper should create fit-height rows.');
    assert(h.sameStringCell(ui.grid.ColumnWidth, {'fit', '1x'}), ...
        'Plot-options helper should preserve column widths.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), 'Plot-options helper should preserve padding.');
    assert(ui.grid.RowSpacing == 8 && ui.grid.ColumnSpacing == 8, ...
        'Plot-options helper should preserve row and column spacing.');

    ui2 = labkit.ui.createPlotOptionsPanel(grid, 2, 2);
    assert(ui2.panel.Layout.Row == 2, ...
        'Plot-options helper should support an explicit parent-grid row.');
end

function checkCreateAxesHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_create_axes_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    ax = labkit.ui.createAxes(grid, 2, 'Probe Title', 'Probe X', 'Probe Y');
    plot(ax, 1:3, [1 4 2], 'DisplayName', 'probe');
    labkit.ui.enableAxesPopout(ax);
    assert(ax.Layout.Row == 2, 'Axes helper should set the requested layout row.');
    assert(strcmp(char(ax.Title.String), 'Probe Title'), 'Axes helper should preserve the title.');
    assert(strcmp(char(ax.XLabel.String), 'Probe X'), 'Axes helper should preserve the x label.');
    assert(strcmp(char(ax.YLabel.String), 'Probe Y'), 'Axes helper should preserve the y label.');
    h.assertAxesPopoutEnabled(ax, 'Axes helper should install the LabKit popout context action.');

    popoutFig = labkit.ui.popoutAxes(ax);
    popoutCleaner = onCleanup(@() delete(popoutFig)); %#ok<NASGU>
    popoutAxes = findobj(popoutFig, 'Type', 'axes');
    assert(numel(popoutAxes) >= 1, 'Axes popout should create an editable figure axes.');
    assert(strcmp(char(popoutAxes(1).Title.String), 'Probe Title'), ...
        'Axes popout should preserve the source title.');
    assert(~isempty(popoutAxes(1).Children), ...
        'Axes popout should copy plotted children.');
    assert(strcmp(popoutAxes(1).DataAspectRatioMode, 'auto') && ...
        strcmp(popoutAxes(1).PlotBoxAspectRatioMode, 'auto'), ...
        'Axes popout should leave the copied plot with freely adjustable aspect ratio.');
    h.assertAxesChildrenUsePopoutMenu(ax, ...
        'Axes helper should attach the popout menu to plotted child objects.');

    imgAx = labkit.ui.createAxes(grid, 1, 'Image Probe', '', '');
    hImage = labkit.ui.showImageAxes(imgAx, zeros(12, 16, 3, 'uint8'), 'Image Probe');
    assert(strcmp(char(imgAx.Title.String), 'Image Probe'), ...
        'Image axes helper should preserve the supplied title.');
    assert(isequal(hImage.ContextMenu, imgAx.ContextMenu), ...
        'Image axes helper should attach the popout menu to the image object.');
end

function checkAnchorCurveEditorHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_anchor_curve_editor_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    ax = uiaxes(fig);
    image(ax, zeros(40, 60, 3, 'uint8'));
    axis(ax, 'image');

    changed = false;
    editor = labkit.ui.createAnchorCurveEditor(ax, [40 60 3], ...
        struct('figure', fig, ...
        'closed', true, ...
        'style', 'Curve', ...
        'onChanged', @(~,~) markChanged()));
    editor.start([10 10; 30 12; 28 30]);
    assert(changed, 'Anchor curve editor should fire the change callback when started.');
    points = editor.getPoints();
    assert(isequal(size(points), [3 2]), 'Anchor curve editor should preserve anchor points.');
    curve = editor.curvePoints();
    assert(~isempty(curve), 'Anchor curve editor should generate display curve points.');
    editor.setStyle('Straight lines');
    curve = editor.curvePoints();
    assert(isequal(curve(1, :), curve(end, :)), ...
        'Closed straight-line editor curves should end at the first point.');
    editor.setStyle('Curve');
    editor.setPoints([10 10; 40 10; 40 30; 10 30]);
    editor.insertPoint([25 10]);
    points = editor.getPoints();
    assert(isequal(size(points), [5 2]) && isequal(points(2, :), [25 10]), ...
        'Anchor curve editor should insert new anchors into the nearest displayed curve segment.');
    twoPointEditor = labkit.ui.createAnchorCurveEditor(ax, [40 60 3], ...
        struct('figure', fig, 'closed', false, 'style', 'Straight lines', 'maxPoints', 2));
    twoPointEditor.start([5 5; 20 5]);
    twoPointEditor.insertPoint([30 5]);
    assert(isequal(size(twoPointEditor.getPoints()), [2 2]), ...
        'Anchor curve editor should enforce maxPoints for two-anchor tools.');
    openEditor = labkit.ui.createAnchorCurveEditor(ax, [40 60 3], ...
        struct('figure', fig, 'closed', false, 'style', 'Straight lines'));
    openEditor.start([10 10; 40 30]);
    openEditor.insertPoint([25 20]);
    points = openEditor.getPoints();
    assert(isequal(points(2, :), [25 20]), ...
        'Open anchor editor should insert points that are close to an existing segment.');
    spiralEditor = labkit.ui.createAnchorCurveEditor(ax, [60 70 3], ...
        struct('figure', fig, 'closed', false, 'style', 'Straight lines'));
    spiralEditor.start([20 20; 55 20; 55 55; 35 55; 35 35; 48 35]);
    spiralEditor.insertPoint([48 45]);
    points = spiralEditor.getPoints();
    assert(isequal(points(end, :), [48 45]), ...
        'Open anchor editor should extend nearby endpoints instead of inserting into an inner spiral segment.');
    editor.undoLast();
    assert(isequal(size(editor.getPoints()), [4 2]), ...
        'Anchor curve editor should remove the last anchor.');
    editor.clearPoints();
    assert(isempty(editor.getPoints()), 'Anchor curve editor should clear anchors.');

    function markChanged()
        changed = true;
    end
end

function checkRowResizeHandleHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_row_resize_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [3 1]);
    grid.RowHeight = {120, 6, 140};

    top = uipanel(grid, 'Title', 'Top');
    top.Layout.Row = 1;
    bottom = uipanel(grid, 'Title', 'Bottom');
    bottom.Layout.Row = 3;

    handle = labkit.ui.addRowResizeHandle(fig, grid, 2, ...
        struct('minTopHeight', 80, 'minBottomHeight', 90));
    assert(handle.Layout.Row == 2, 'Row-resize handle should live in the requested row.');
    assert(isequal(grid.RowHeight, {120, 6, 140}), ...
        'Row-resize handle should preserve existing adjacent row heights before dragging.');
    h.assertCallbackPresent(handle, 'ButtonDownFcn', 'row-resize handle');
    h.invokeCallback(handle, 'ButtonDownFcn');
    assert(~isempty(fig.WindowButtonMotionFcn) && ~isempty(fig.WindowButtonUpFcn), ...
        'Row-resize drag should install temporary figure motion callbacks.');
    h.invokeCallback(fig, 'WindowButtonUpFcn');
    assert(isempty(fig.WindowButtonMotionFcn) && isempty(fig.WindowButtonUpFcn), ...
        'Row-resize drag should clear temporary figure callbacks after release.');
end

function checkCreateWorkbenchHelper(h)
    opts = struct();
    opts.rightTitle = 'Preview';
    opts.rightGridSize = [2 1];
    opts.rightRowHeight = {'1x', 'fit'};
    opts.rightRowSpacing = 7;
    ui = labkit.ui.createWorkbench( ...
        'labkit_create_workbench_probe', ...
        [40 30 1200 760], ...
        330, ...
        opts);
    cleaner = onCleanup(@() delete(ui.fig)); %#ok<NASGU>

    assert(isequal(ui.main.ColumnWidth, {330, 6, '1x'}), ...
        'Workbench helper should create the standard resizable left/separator/right layout.');
    h.assertTabTitles(ui.fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertScrollablePanel(ui.filesAnalysisScrollPanel, 'Files + Analysis tab');
    h.assertScrollableGrid(ui.filesAnalysisGrid, 'Files + Analysis grid');
    assert(numel(ui.filesAnalysisResizeHandles) == 2, ...
        'Standard Files + Analysis tab should expose two row-resize handles.');
    assert(numel(ui.summaryResultsResizeHandles) == 1, ...
        'Standard Summary + Results tab should expose one row-resize handle.');
    assert(isequal(ui.filesAnalysisGrid.UserData.LabKitLogicalRowMap, [1 3 5]), ...
        'Workbench should keep standard app rows mapped behind the shell.');
    assert(strcmp(ui.rightPanel.Title, 'Preview'), ...
        'Workbench helper should preserve the requested right panel title.');
    assert(isequal(ui.rightGrid.RowHeight, {'1x', 'fit'}), ...
        'Workbench helper should preserve custom right-grid rows.');

    customOpts = struct();
    customOpts.rightTitle = 'Custom';
    customOpts.tabs = labkit.ui.tabSpec( ...
        'probe', 'Probe Controls', [2 1], {'fit', '1x'});
    custom = labkit.ui.createWorkbench( ...
        'labkit_custom_tab_workbench_probe', ...
        [40 30 1200 760], ...
        330, ...
        customOpts);
    cleaner3 = onCleanup(@() delete(custom.fig)); %#ok<NASGU>
    h.assertTabTitles(custom.fig, {'Probe Controls'});
    h.assertScrollablePanel(custom.probeScrollPanel, 'Probe Controls tab');
    h.assertScrollableGrid(custom.probeGrid, 'Probe Controls grid');
    assert(h.sameStringCell(custom.probeGrid.RowHeight, {'fit', '1x'}), ...
        'Workbench helper should preserve custom tab specs.');
    assert(isempty(custom.probeResizeHandles), ...
        'Custom tabs without resizeRows should not create resize handles.');

    dual = labkit.ui.createWorkbench( ...
        'labkit_create_dual_plot_workbench_probe', ...
        [40 30 1200 760], ...
        330, ...
        struct('rightKind', 'dualPlot'));
    cleaner2 = onCleanup(@() delete(dual.fig)); %#ok<NASGU>
    assert(h.sameStringCell(dual.rightGrid.RowHeight, {'fit', '1x', 'fit', '1x'}), ...
        'Workbench helper should configure the standard dual-plot right region.');
    assert(strcmp(char(dual.topAxes.Title.String), 'Top Plot'), ...
        'Workbench helper should create a titled top axes for dual-plot apps.');
    assert(strcmp(char(dual.bottomAxes.Title.String), 'Bottom Plot'), ...
        'Workbench helper should create a titled bottom axes for dual-plot apps.');

    dualNoControls = labkit.ui.createWorkbench( ...
        'labkit_create_dual_plot_no_controls_probe', ...
        [40 30 1200 760], ...
        330, ...
        struct('rightKind', 'dualPlot', 'showPlotControls', false));
    cleaner4 = onCleanup(@() delete(dualNoControls.fig)); %#ok<NASGU>
    assert(h.sameStringCell(dualNoControls.rightGrid.RowHeight, {'1x', '1x'}), ...
        'Workbench helper should support dual-plot output without empty control rows.');
    assert(isempty(dualNoControls.topControlsPanel) && isempty(dualNoControls.bottomControlsPanel), ...
        'Dual-plot output without controls should not create empty plot-control panels.');
    assert(dualNoControls.topAxes.Layout.Row == 1 && dualNoControls.bottomAxes.Layout.Row == 2, ...
        'Dual-plot output without controls should place axes directly in the output grid.');
end

function checkTopBottomPlotControlsHelper(h)
    shell = createDualPlotWorkbenchForTest('labkit_top_bottom_plot_controls_probe');
    cleaner = onCleanup(@() delete(shell.fig)); %#ok<NASGU>

    topDefaults = struct('x', 'Time (s)', 'y', 'VT: Vf vs time', 'grid', true);
    bottomDefaults = struct('x', 'Sample #', 'y', 'IT: Im vs time', 'grid', false);
    ui = labkit.ui.createTopBottomPlotControls( ...
        shell.topControlsPanel, ...
        shell.bottomControlsPanel, ...
        {'Time (s)', 'Sample #'}, ...
        {'VT: Vf vs time', 'IT: Im vs time'}, ...
        topDefaults, ...
        bottomDefaults, ...
        []);

    assert(isequal(ui.topGrid.ColumnWidth, {'fit', '1x', 'fit', '1x', '1x'}), ...
        'Top/bottom plot controls should preserve column widths.');
    assert(isequal(ui.topGrid.Padding, [8 6 8 6]), ...
        'Top/bottom plot controls should preserve grid padding.');
    assert(ui.topGrid.ColumnSpacing == 8, ...
        'Top/bottom plot controls should preserve column spacing.');
    assert(h.sameStringCell(ui.topX.Items, {'Time (s)', 'Sample #'}), ...
        'Top X dropdown should preserve supplied X items.');
    assert(h.sameStringCell(ui.topY.Items, {'VT: Vf vs time', 'IT: Im vs time'}), ...
        'Top Y dropdown should preserve supplied Y items.');
    assert(strcmp(ui.topX.Value, 'Time (s)'), ...
        'Top X dropdown should preserve the supplied default value.');
    assert(strcmp(ui.topY.Value, 'VT: Vf vs time'), ...
        'Top Y dropdown should preserve the supplied default value.');
    assert(ui.topGridCheckbox.Value == true, ...
        'Top grid checkbox should preserve the supplied default value.');
    assert(strcmp(ui.bottomX.Value, 'Sample #'), ...
        'Bottom X dropdown should preserve the supplied default value.');
    assert(strcmp(ui.bottomY.Value, 'IT: Im vs time'), ...
        'Bottom Y dropdown should preserve the supplied default value.');
    assert(ui.bottomGridCheckbox.Value == false, ...
        'Bottom grid checkbox should preserve the supplied default value.');
end

function checkTopBottomPlotStateHelpers(h)
    shell = createDualPlotWorkbenchForTest('labkit_top_bottom_plot_state_probe');
    cleaner = onCleanup(@() delete(shell.fig)); %#ok<NASGU>

    topDefaults = struct('x', 'Time (s)', 'y', 'VT: Vf vs time', 'grid', true);
    bottomDefaults = struct('x', 'Sample #', 'y', 'IT: Im vs time', 'grid', false);
    ui = labkit.ui.createTopBottomPlotControls( ...
        shell.topControlsPanel, ...
        shell.bottomControlsPanel, ...
        {'Time (s)', 'Sample #'}, ...
        {'VT: Vf vs time', 'IT: Im vs time'}, ...
        topDefaults, ...
        bottomDefaults, ...
        []);

    labkit.ui.setTopBottomPlotSelections(ui.topX, ui.topY, ui.bottomX, ui.bottomY, ...
        bottomDefaults, topDefaults);
    assert(strcmp(ui.topX.Value, 'Sample #') && strcmp(ui.bottomX.Value, 'Time (s)'), ...
        'Top/bottom selection setter should apply supplied X defaults.');
    assert(strcmp(ui.topY.Value, 'IT: Im vs time') && strcmp(ui.bottomY.Value, 'VT: Vf vs time'), ...
        'Top/bottom selection setter should apply supplied Y defaults.');

    labkit.ui.swapTopBottomPlotSelections(ui.topX, ui.topY, ui.bottomX, ui.bottomY);
    assert(strcmp(ui.topX.Value, 'Time (s)') && strcmp(ui.topY.Value, 'VT: Vf vs time'), ...
        'Top/bottom selection swap should move bottom selections to the top.');
    assert(strcmp(ui.bottomX.Value, 'Sample #') && strcmp(ui.bottomY.Value, 'IT: Im vs time'), ...
        'Top/bottom selection swap should move top selections to the bottom.');

    shell.topAxes.XScale = 'log';
    shell.bottomAxes.YScale = 'log';
    labkit.ui.hardResetAxis(shell.topAxes, 'Top Plot', true);
    labkit.ui.hardResetAxis(shell.bottomAxes, 'Bottom Plot', true);
    assert(strcmp(char(shell.topAxes.Title.String), 'Top Plot'), ...
        'Hard axis reset should preserve the supplied top axes title.');
    assert(strcmp(char(shell.bottomAxes.Title.String), 'Bottom Plot'), ...
        'Hard axis reset should preserve the supplied bottom axes title.');
    assert(strcmp(shell.topAxes.XScale, 'linear') && strcmp(shell.bottomAxes.YScale, 'linear'), ...
        'Hard axis reset should optionally reset axis scales.');
    h.assertAxesPopoutEnabled(shell.topAxes, 'Hard axis reset should install top-axis popout.');
    h.assertAxesPopoutEnabled(shell.bottomAxes, 'Hard axis reset should install bottom-axis popout.');
end

function shell = createDualPlotWorkbenchForTest(figName)
    opts = struct();
    opts.rightKind = 'dualPlot';
    opts.controlsTitle = 'Controls';
    opts.rightTitle = 'Plots';
    opts.topPlotTitle = 'Top Plot';
    opts.bottomPlotTitle = 'Bottom Plot';
    shell = labkit.ui.createWorkbench(figName, [40 30 1680 980], 430, opts);
end

function checkFileSelectionPanelHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_file_selection_panel_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [3 1]);

    callbacks = struct();
    callbacks.onOpenFiles = @(~,~) [];
    callbacks.onOpenFolder = @(~,~) [];
    callbacks.onClearAll = @(~,~) [];
    callbacks.onExport = @(~,~) [];
    callbacks.onSelectFile = @(~,~) [];

    labels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'clearAll', 'Clear all', ...
        'export', 'Export results CSV', ...
        'loadedText', 'No files loaded');
    ui = labkit.ui.createFileSelectionPanel(grid, labels, callbacks);
    assert(strcmp(ui.panel.Title, 'Files'), 'File-selection panel should preserve the panel title.');
    assert(ui.panel.Layout.Row == 1, 'File-selection panel should place the panel in row 1.');
    assert(h.sameStringCell(ui.grid.RowHeight, {'fit', '1x', 'fit'}), ...
        'File-selection panel should preserve row heights.');
    assert(h.sameStringCell(ui.grid.ColumnWidth, {'1x'}), ...
        'File-selection panel should preserve column widths.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), ...
        'File-selection panel should preserve padding.');
    assert(ui.grid.RowSpacing == 8 && ui.grid.ColumnSpacing == 0, ...
        'File-selection panel should preserve row and column spacing.');
    assert(isequal(ui.buttonGrid.ColumnWidth, {'1x', '1x'}), ...
        'File-selection panel should preserve button-grid columns.');
    assert(strcmp(ui.openButton.Text, 'Open DTA file(s)'), ...
        'File-selection panel should preserve the open-file button text.');
    assert(strcmp(ui.openFolderButton.Text, 'Open folder recursively'), ...
        'File-selection panel should preserve the open-folder button text.');
    assert(strcmp(ui.clearButton.Text, 'Clear all'), ...
        'File-selection panel should preserve the clear button text.');
    assert(strcmp(ui.exportButton.Text, 'Export results CSV'), ...
        'File-selection panel should preserve the export button text.');
    assert(strcmp(ui.listbox.Multiselect, 'off'), ...
        'File-selection panel should default to a single-select listbox.');
    assert(strcmp(ui.loadedText.Editable, 'off'), ...
        'File-selection panel should create a read-only loaded-count field.');
    assert(strcmp(ui.loadedText.Value, 'No files loaded'), ...
        'File-selection panel should preserve the default loaded-count text.');
    h.assertCallbackPresent(ui.openButton, 'ButtonPushedFcn', 'Open DTA file(s)');
    h.assertCallbackPresent(ui.openFolderButton, 'ButtonPushedFcn', 'Open folder recursively');
    h.assertCallbackPresent(ui.clearButton, 'ButtonPushedFcn', 'Clear all');
    h.assertCallbackPresent(ui.exportButton, 'ButtonPushedFcn', 'Export results CSV');
    h.assertCallbackPresent(ui.listbox, 'ValueChangedFcn', 'file listbox');

    multiCallbacks = callbacks;
    multiCallbacks.onRemoveSelected = @(~,~) [];
    multiLabels = labels;
    multiLabels.removeSelected = 'Remove selected';
    multiUi = labkit.ui.createFileSelectionPanel(grid, multiLabels, multiCallbacks, ...
        struct('showRemoveSelected', true, 'multiselect', 'on', 'row', 2));
    assert(strcmp(multiUi.listbox.Multiselect, 'on'), ...
        'File-selection panel should support multi-select listboxes.');
    assert(strcmp(multiUi.removeButton.Text, 'Remove selected'), ...
        'File-selection panel should create remove-selected controls when requested.');
    assert(multiUi.exportButton.Layout.Row == 3, ...
        'File-selection panel should place export below remove/clear when remove is enabled.');
end

function checkRunWithBusyStateHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_busy_state_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [3 1]);
    btnRun = uibutton(grid, 'Text', 'Run');
    btnExport = uibutton(grid, 'Text', 'Export', 'Enable', 'off');
    btnOther = uibutton(grid, 'Text', 'Other');
    fig.Pointer = 'arrow';

    opts = struct();
    opts.showDialog = false;
    opts.controls = {btnRun, btnExport};
    result = labkit.ui.runWithBusyState(fig, @probeWork, opts);

    assert(result == 42, ...
        'Busy-state helper should return the work callback output.');
    assert(strcmp(btnRun.Enable, 'on'), ...
        'Busy-state helper should restore enabled controls.');
    assert(strcmp(btnExport.Enable, 'off'), ...
        'Busy-state helper should restore controls that started disabled.');
    assert(strcmp(btnOther.Enable, 'on'), ...
        'Busy-state helper should not touch controls outside opts.controls.');
    assert(strcmp(fig.Pointer, 'arrow'), ...
        'Busy-state helper should restore the figure pointer.');

    assertThrows(@() labkit.ui.runWithBusyState(fig, @failingWork, opts), ...
        'labkit:ui:test:BusyFailure', ...
        'Busy-state helper should rethrow callback errors.');
    assert(strcmp(btnRun.Enable, 'on') && strcmp(btnExport.Enable, 'off'), ...
        'Busy-state helper should restore control states after callback errors.');
    assert(strcmp(fig.Pointer, 'arrow'), ...
        'Busy-state helper should restore the pointer after callback errors.');

    function value = probeWork()
        assert(strcmp(btnRun.Enable, 'off'), ...
            'Busy-state helper should disable active controls during work.');
        assert(strcmp(btnExport.Enable, 'off'), ...
            'Busy-state helper should keep initially disabled controls off during work.');
        assert(strcmp(btnOther.Enable, 'on'), ...
            'Busy-state helper should leave unrelated controls enabled during work.');
        assert(strcmp(fig.Pointer, 'watch'), ...
            'Busy-state helper should set a busy pointer during work.');
        value = 42;
    end

    function failingWork()
        assert(strcmp(btnRun.Enable, 'off'), ...
            'Busy-state helper should disable controls before failing work runs.');
        error('labkit:ui:test:BusyFailure', 'Synthetic busy-state failure.');
    end
end

function assertThrows(fn, expectedIdentifier, label)
    try
        fn();
    catch ME
        assert(strcmp(ME.identifier, expectedIdentifier), ...
            '%s Expected %s but caught %s.', ...
            label, expectedIdentifier, ME.identifier);
        return;
    end
    error('%s Expected an error with identifier %s.', label, expectedIdentifier);
end
