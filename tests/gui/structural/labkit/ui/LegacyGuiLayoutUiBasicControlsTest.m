classdef LegacyGuiLayoutUiBasicControlsTest < matlab.uitest.TestCase
    %LEGACYGUILAYOUTUIBASICCONTROLSTEST Official wrapper for migrated legacy coverage.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_basic_controls(testCase)
            setupLabKitTestPath();
            legacy_test_gui_layout_ui_basic_controls();
        end
    end
end

function legacy_test_gui_layout_ui_basic_controls()
%TEST_GUI_LAYOUT_UI_BASIC_CONTROLS Verify basic reusable UI controls/panels.

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
    checkFileSelectionPanelHelper(h);
end

function checkListboxItemsRefreshHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_file_listbox_refresh_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    lb = uilistbox(fig, 'Items', {}, 'Multiselect', 'on');

    labkit.ui.view.update(lb, 'listItems', {'a.DTA', 'b.DTA'});
    assert(h.sameStringCell(lb.Items, {'a.DTA', 'b.DTA'}), ...
        'File listbox helper should populate item display names.');
    assert(h.sameStringCell(lb.Value, {'a.DTA', 'b.DTA'}), ...
        'File listbox helper should select all items when there is no prior selection.');

    lb.Value = {'b.DTA'};
    labkit.ui.view.update(lb, 'listItems', {'b.DTA', 'c.DTA'});
    assert(h.sameStringCell(lb.Items, {'b.DTA', 'c.DTA'}), ...
        'File listbox helper should update item display names.');
    assert(h.sameStringCell(lb.Value, {'b.DTA'}), ...
        'File listbox helper should preserve valid prior selections.');

    labkit.ui.view.update(lb, 'listItems', {});
    assert(isempty(lb.Items) && isempty(lb.Value), ...
        'File listbox helper should clear listbox items and values for empty sessions.');
end

function checkListboxSelectionHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_file_listbox_selection_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    singleList = uilistbox(grid, 'Items', {}, 'Multiselect', 'off');
    [value, idx] = labkit.ui.view.update(singleList, 'listSelection', {'a.DTA', 'b.DTA'}, []);
    assert(strcmp(value, 'a.DTA') && idx == 1, ...
        'Listbox selection helper should select the first single-select item by default.');

    [value, idx] = labkit.ui.view.update(singleList, 'listSelection', {'b.DTA', 'c.DTA'}, 2);
    assert(strcmp(value, 'c.DTA') && idx == 2, ...
        'Listbox selection helper should accept a preferred single-select index.');

    multiList = uilistbox(grid, 'Items', {}, 'Multiselect', 'on');
    [value, idx] = labkit.ui.view.update( ...
        multiList, 'listSelection', {'x.DTA', 'y.DTA'}, {}, ...
        struct('defaultSelection', 'all'));
    assert(h.sameStringCell(value, {'x.DTA', 'y.DTA'}) && isequal(idx, [1 2]), ...
        'Listbox selection helper should support selecting all multi-select items by default.');

    [value, idx] = labkit.ui.view.update( ...
        multiList, 'listSelection', {'y.DTA', 'z.DTA'}, {'y.DTA', 'missing.DTA'}, ...
        struct('defaultSelection', 'all'));
    assert(h.sameStringCell(value, {'y.DTA'}) && isequal(idx, 1), ...
        'Listbox selection helper should preserve only valid multi-select choices.');
end

function checkLogPanelHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_log_panel_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    ui = labkit.ui.view.panel(grid, 'log', 2, {'Started.'});
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

    [lbl, spinner] = labkit.ui.view.form(grid, 'spinner', 'Probe value:', ...
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

    field = labkit.ui.view.form(grid, 'readonly', 'Value', 'Status');
    field.Layout.Row = 1;
    assert(strcmp(field.Editable, 'off') && strcmp(field.Value, 'Status'), ...
        'Read-only text field helper should create a non-editable text field.');

    panelUi = labkit.ui.view.panel(grid, 'text', 'Notes', 2, {'one', 'two'});
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

    [field, lbl] = labkit.ui.view.form(grid, 'info', 2, 'Probe:');
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

    ui = labkit.ui.view.panel(grid, 'table', 'Batch Results', 2, ...
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

    ui = labkit.ui.view.section(grid, 'Probe Panel', 2, [3 2]);
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
    ui2 = labkit.ui.view.section(grid, 'Actions', 1, [2 2], opts);
    assert(h.sameStringCell(ui2.grid.ColumnWidth, {'1x', '1x'}), ...
        'Panel-grid helper should support explicit action-column widths.');
    assert(isequal(ui2.grid.Padding, [0 0 0 0]), ...
        'Panel-grid helper should support explicit padding.');

    growGrid = uigridlayout(fig, [1 1]);
    growGrid.RowHeight = {50};
    labkit.ui.view.section(growGrid, 'Tall Controls', 1, [5 2]);
    assert(growGrid.RowHeight{1} > 50, ...
        'Panel-grid helper should grow undersized fixed parent rows to avoid clipped controls.');
end

function checkPlotOptionsPanelHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_plot_options_panel_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [3 1]);

    ui = labkit.ui.view.panel(grid, 'plotOptions', 3);
    assert(strcmp(ui.panel.Title, 'Plot Options'), 'Plot-options helper should preserve the panel title.');
    assert(ui.panel.Layout.Row == 3, 'Plot-options helper should place the panel in row 3.');
    assert(h.sameStringCell(ui.grid.RowHeight, {'fit', 'fit', 'fit'}), ...
        'Plot-options helper should create fit-height rows.');
    assert(h.sameStringCell(ui.grid.ColumnWidth, {'fit', '1x'}), ...
        'Plot-options helper should preserve column widths.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), 'Plot-options helper should preserve padding.');
    assert(ui.grid.RowSpacing == 8 && ui.grid.ColumnSpacing == 8, ...
        'Plot-options helper should preserve row and column spacing.');

    ui2 = labkit.ui.view.panel(grid, 'plotOptions', 2, 2);
    assert(ui2.panel.Layout.Row == 2, ...
        'Plot-options helper should support an explicit parent-grid row.');
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
    ui = labkit.ui.view.panel(grid, 'files', labels, callbacks);
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
    multiUi = labkit.ui.view.panel(grid, 'files', multiLabels, multiCallbacks, ...
        struct('showRemoveSelected', true, 'multiselect', 'on', 'row', 2));
    assert(strcmp(multiUi.listbox.Multiselect, 'on'), ...
        'File-selection panel should support multi-select listboxes.');
    assert(strcmp(multiUi.removeButton.Text, 'Remove selected'), ...
        'File-selection panel should create remove-selected controls when requested.');
    assert(multiUi.exportButton.Layout.Row == 3, ...
        'File-selection panel should place export below remove/clear when remove is enabled.');
end
