function test_gui_layout_controls()
%TEST_GUI_LAYOUT_CONTROLS Verify noninteractive GUI layout and safe callbacks.

    assertUifigureAvailable();
    cleanup = onCleanup(@closeAllFigures);

    checkMultiDTA();
    checkEIS();
    checkCVCSC();
    checkVTResistance();
    checkCIC();
    checkFileListboxRefreshHelper();
    checkSingleSelectFileListboxRefreshHelper();
    checkInfoLogAreaHelpers();
    checkPlotOptionsPanelHelper();
    checkCreateAxesHelper();
    checkTabbedDualPlotShellHelper();
    checkTopBottomPlotControlsHelper();
    checkSingleSelectFilePanelHelper();
end

function checkMultiDTA()
    fig = launchFigure('gamrywb_ChronoOverlay_app', 'Gamry Multi-DTA Plot Export GUI');
    assertFigureMinimumSize(fig, 1400, 850);
    assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 2, 'DropDown', 1, ...
        'ListBox', 1, 'TextArea', 2, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Remove selected', ...
        'Clear all', 'Export curves CSV'});
    assertCheckboxContract(fig, {'Show file-name legend', 'Show grid'});
    assertDropdownGroups(fig, dropdownGroup({'Time (s)', 'Time (ms)', 'Sample #'}, 1));
    assertAxesContract(fig, { ...
        axesSpec('Voltage', 'Time (s)', 'Vf (V)'), ...
        axesSpec('Current', 'Time (s)', 'Im (A)')});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Time (ms)');
    invokeCheckbox(fig, 'Show file-name legend', false);
    invokeButton(fig, 'Clear all');
end

function checkEIS()
    fig = launchFigure('gamrywb_EIS_app', 'Gamry EIS Multi-DTA Plot GUI');
    assertFigureMinimumSize(fig, 1400, 850);
    assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 5, 'DropDown', 2, ...
        'ListBox', 1, 'TextArea', 3, 'Axes', 1));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Remove selected', ...
        'Clear all', 'Export current plot CSV'});
    assertCheckboxContract(fig, {'Show markers', 'Log X', 'Log Y', 'Legend', 'Grid'});
    assertDropdownGroups(fig, dropdownGroup(eisAxisItems(), 2));
    assertAxesContract(fig, {axesSpec('EIS Overlay', 'Zreal (ohm)', '-Zimag (ohm)')});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Freq (Hz)');
    invokeCheckbox(fig, 'Log X', true);
    invokeButton(fig, 'Clear all');
end

function checkCVCSC()
    fig = launchFigure('gamrywb_CSC_app', 'Gamry DTA GUI (literature CSC)');
    assertFigureMinimumSize(fig, 1500, 900);
    assertComponentCounts(fig, struct('Button', 7, 'CheckBox', 6, 'DropDown', 6, ...
        'TextArea', 1, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA', 'Reload', 'Auto CV + CT', 'Swap Top/Bottom', ...
        'Compare Q / CSC', 'Refresh Plots', 'Clear Both'});
    assertCheckboxContract(fig, {'Grid', 'Hold', 'Show Trim'});
    assertDropdownGroups(fig, [ ...
        dropdownGroup({'(none)'}, 5), ...
        dropdownGroup({'Full', 'Cathodic', 'Anodic'}, 1)]);
    assertAxesContract(fig, { ...
        axesSpec('Top Plot', 'X', 'Y'), ...
        axesSpec('Bottom Plot', 'X', 'Y')});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Cathodic');
    invokeButton(fig, 'Refresh Plots');
    invokeButton(fig, 'Clear Both');
end

function checkVTResistance()
    fig = launchFigure('gamrywb_VTResistance_app', 'Gamry VT Steady Resistance GUI');
    assertFigureMinimumSize(fig, 1600, 900);
    assertComponentCounts(fig, struct('Button', 8, 'CheckBox', 4, 'DropDown', 7, ...
        'ListBox', 1, 'Table', 1, 'TextArea', 1, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Clear all', ...
        'Export results CSV', 'Re-analyze file', 'Refresh plots', 'Swap top / bottom', ...
        'Reset axes'});
    assertCheckboxContract(fig, {'Show markers', 'Shade windows', 'Grid'});
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertDropdownGroups(fig, [ ...
        dropdownGroup({'Metadata first, then auto', 'Metadata only', 'Auto from Im only'}, 1), ...
        dropdownGroup({'Full pulse median', 'Center 60% median'}, 1), ...
        dropdownGroup({'Baseline-corrected dV/I', 'Raw Vf/I'}, 1), ...
        dropdownGroup({'Time (s)', 'Sample #'}, 2), ...
        dropdownGroup({'VT: Vf vs time', 'IT: Im vs time'}, 2)]);
    assertTableColumns(fig, {'File','Ic(A)','Ia(A)','Vc_ss(V)','Va_ss(V)', ...
        'R_cath(ohm)','R_anod(ohm)','R_avg(ohm)','Detection'});
    assertAxesContract(fig, { ...
        axesSpec('Top Plot', '', ''), ...
        axesSpec('Bottom Plot', '', '')});
    assertDropdownCallbacksPresent(fig);
    invokeButton(fig, 'Refresh plots');
    invokeButton(fig, 'Reset axes');
    invokeButton(fig, 'Clear all');
end

function checkCIC()
    fig = launchFigure('gamrywb_CIC_app', 'Gamry CIC GUI (Voltage Transient)');
    assertFigureMinimumSize(fig, 1600, 900);
    assertComponentCounts(fig, struct('Button', 7, 'CheckBox', 6, 'DropDown', 8, ...
        'ListBox', 1, 'Table', 1, 'TextArea', 1, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Clear all', ...
        'Export results CSV', 'Refresh plots', 'Swap top / bottom', 'Reset axes'});
    assertCheckboxContract(fig, { ...
        'Show debug markers', 'Show window limits', 'Shade pulse windows', ...
        'Use measured Im integration for charge (recommended)'});
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertDropdownGroups(fig, [ ...
        dropdownGroup({'Pt (-0.6 to 0.8 V)', 'PEDOT:PSS (-0.9 to 0.6 V)', 'Custom'}, 1), ...
        dropdownGroup({'Metadata first, then auto', 'Metadata only', 'Auto from Im only'}, 1), ...
        dropdownGroup({'Cathodic phase', 'Anodic phase', 'Total biphasic'}, 1), ...
        dropdownGroup({'mC/cm^2', 'uC/cm^2'}, 1), ...
        dropdownGroup({'Time (s)', 'Sample #'}, 2), ...
        dropdownGroup({'VT: Vf vs time', 'IT: Im vs time'}, 2)]);
    assertTableColumns(fig, {'File','Amp(A)','Emc(V)','Ema(V)', ...
        'Qc(mC/cm^2)','Qa(mC/cm^2)','Qtot(mC/cm^2)','Safe'});
    assertAxesContract(fig, { ...
        axesSpec('Top Plot', '', ''), ...
        axesSpec('Bottom Plot', '', '')});
    assertDropdownCallbacksPresent(fig);
    invokeButton(fig, 'Refresh plots');
    invokeButton(fig, 'Reset axes');
    invokeButton(fig, 'Clear all');
end

function checkFileListboxRefreshHelper()
    fig = uifigure('Visible', 'off', 'Name', 'gamrywb_file_listbox_refresh_probe');
    cleaner = onCleanup(@() delete(fig));
    lb = uilistbox(fig, 'Items', {}, 'Multiselect', 'on');

    items = struct('name', {'a.DTA', 'b.DTA'});
    gamrywb.ui.refreshFileListbox(lb, items);
    assert(sameStringCell(lb.Items, {'a.DTA', 'b.DTA'}), ...
        'File listbox helper should populate item display names.');
    assert(sameStringCell(lb.Value, {'a.DTA', 'b.DTA'}), ...
        'File listbox helper should select all items when there is no prior selection.');

    lb.Value = {'b.DTA'};
    items = struct('name', {'b.DTA', 'c.DTA'});
    gamrywb.ui.refreshFileListbox(lb, items);
    assert(sameStringCell(lb.Items, {'b.DTA', 'c.DTA'}), ...
        'File listbox helper should update item display names.');
    assert(sameStringCell(lb.Value, {'b.DTA'}), ...
        'File listbox helper should preserve valid prior selections.');

    gamrywb.ui.refreshFileListbox(lb, struct([]));
    assert(isempty(lb.Items) && isempty(lb.Value), ...
        'File listbox helper should clear listbox items and values for empty sessions.');
end

function checkSingleSelectFileListboxRefreshHelper()
    fig = uifigure('Visible', 'off', 'Name', 'gamrywb_single_select_file_listbox_refresh_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);
    lb = uilistbox(grid, 'Items', {}, 'Multiselect', 'off');
    loadedText = uieditfield(grid, 'text', 'Editable', 'off');

    items = struct('name', {'a.DTA', 'b.DTA'});
    currentIndex = gamrywb.ui.refreshSingleSelectFileListbox(lb, loadedText, items, []);
    assert(currentIndex == 1, ...
        'Single-select file listbox helper should default an empty current index to the first item.');
    assert(sameStringCell(lb.Items, {'a.DTA', 'b.DTA'}), ...
        'Single-select file listbox helper should populate item display names.');
    assert(strcmp(lb.Value, 'a.DTA'), ...
        'Single-select file listbox helper should select the first item by default.');
    assert(strcmp(loadedText.Value, '2 file(s) loaded'), ...
        'Single-select file listbox helper should update the loaded-count field.');

    currentIndex = gamrywb.ui.refreshSingleSelectFileListbox(lb, loadedText, items, 2);
    assert(currentIndex == 2 && strcmp(lb.Value, 'b.DTA'), ...
        'Single-select file listbox helper should preserve a valid current index.');

    currentIndex = gamrywb.ui.refreshSingleSelectFileListbox(lb, loadedText, items, 99);
    assert(currentIndex == 1 && strcmp(lb.Value, 'a.DTA'), ...
        'Single-select file listbox helper should reset an out-of-range current index.');

    currentIndex = gamrywb.ui.refreshSingleSelectFileListbox(lb, loadedText, struct([]), 1);
    assert(isempty(currentIndex), ...
        'Single-select file listbox helper should clear the current index for empty sessions.');
    assert(isempty(lb.Items) && isempty(lb.Value), ...
        'Single-select file listbox helper should clear listbox items and value for empty sessions.');
    assert(strcmp(loadedText.Value, 'No files loaded'), ...
        'Single-select file listbox helper should reset the loaded-count field for empty sessions.');
end

function checkInfoLogAreaHelpers()
    fig = uifigure('Visible', 'off', 'Name', 'gamrywb_info_log_area_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [5 1]);

    txtInfo = gamrywb.ui.createInfoArea(grid, {'Usage:', 'Line 1'});
    assert(txtInfo.Layout.Row == 4, 'Info area helper should place text area in row 4.');
    assert(strcmp(txtInfo.Editable, 'off'), 'Info area helper should create a read-only text area.');
    assert(sameStringCell(txtInfo.Value, {'Usage:', 'Line 1'}), ...
        'Info area helper should preserve supplied text.');

    txtLog = gamrywb.ui.createLogArea(grid);
    assert(txtLog.Layout.Row == 5, 'Log area helper should place text area in row 5.');
    assert(strcmp(txtLog.Editable, 'off'), 'Log area helper should create a read-only text area.');
    assert(sameStringCell(txtLog.Value, {'GUI started.'}), ...
        'Log area helper should preserve the default initial log line.');
end

function checkPlotOptionsPanelHelper()
    fig = uifigure('Visible', 'off', 'Name', 'gamrywb_plot_options_panel_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [3 1]);

    ui = gamrywb.ui.createPlotOptionsPanel(grid, 3);
    assert(strcmp(ui.panel.Title, 'Plot Options'), 'Plot-options helper should preserve the panel title.');
    assert(ui.panel.Layout.Row == 3, 'Plot-options helper should place the panel in row 3.');
    assert(sameStringCell(ui.grid.RowHeight, {'fit', 'fit', 'fit'}), ...
        'Plot-options helper should create fit-height rows.');
    assert(sameStringCell(ui.grid.ColumnWidth, {'fit', '1x'}), ...
        'Plot-options helper should preserve column widths.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), 'Plot-options helper should preserve padding.');
    assert(ui.grid.RowSpacing == 8 && ui.grid.ColumnSpacing == 8, ...
        'Plot-options helper should preserve row and column spacing.');
end

function checkCreateAxesHelper()
    fig = uifigure('Visible', 'off', 'Name', 'gamrywb_create_axes_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);

    ax = gamrywb.ui.createAxes(grid, 2, 'Probe Title', 'Probe X', 'Probe Y');
    assert(ax.Layout.Row == 2, 'Axes helper should set the requested layout row.');
    assert(strcmp(char(ax.Title.String), 'Probe Title'), 'Axes helper should preserve the title.');
    assert(strcmp(char(ax.XLabel.String), 'Probe X'), 'Axes helper should preserve the x label.');
    assert(strcmp(char(ax.YLabel.String), 'Probe Y'), 'Axes helper should preserve the y label.');
end

function checkTabbedDualPlotShellHelper()
    ui = gamrywb.ui.createTabbedDualPlotShell( ...
        'gamrywb_tabbed_dual_plot_shell_probe', ...
        [40 30 1680 980], ...
        430, ...
        []);
    cleaner = onCleanup(@() delete(ui.fig));

    assert(isequal(ui.main.ColumnWidth, {430, 6, '1x'}), ...
        'Tabbed dual-plot shell should preserve the main column widths.');
    assert(isequal(ui.main.Padding, [10 10 10 10]), ...
        'Tabbed dual-plot shell should preserve main padding.');
    assert(ui.main.ColumnSpacing == 0, ...
        'Tabbed dual-plot shell should preserve zero column spacing around the separator.');
    assert(strcmp(ui.leftPanel.Title, 'Controls'), ...
        'Tabbed dual-plot shell should preserve the controls panel title.');
    assertTabTitles(ui.fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assert(isequal(ui.filesAnalysisGrid.RowHeight, {260, 'fit', 'fit'}), ...
        'Files + Analysis grid should preserve row heights.');
    assert(sameStringCell(ui.summaryResultsGrid.RowHeight, {'fit', '1x'}), ...
        'Summary + Results grid should preserve row heights.');
    assert(sameStringCell(ui.rightGrid.RowHeight, {'fit', '1x', 'fit', '1x'}), ...
        'Right plot grid should preserve top/bottom row heights.');
    assert(strcmp(char(ui.topAxes.Title.String), 'Top Plot'), ...
        'Tabbed dual-plot shell should create the top axes with the expected title.');
    assert(strcmp(char(ui.bottomAxes.Title.String), 'Bottom Plot'), ...
        'Tabbed dual-plot shell should create the bottom axes with the expected title.');
end

function checkTopBottomPlotControlsHelper()
    shell = gamrywb.ui.createTabbedDualPlotShell( ...
        'gamrywb_top_bottom_plot_controls_probe', ...
        [40 30 1680 980], ...
        430, ...
        []);
    cleaner = onCleanup(@() delete(shell.fig));

    topDefaults = struct('x', 'Time (s)', 'y', 'VT: Vf vs time', 'grid', true);
    bottomDefaults = struct('x', 'Sample #', 'y', 'IT: Im vs time', 'grid', false);
    ui = gamrywb.ui.createTopBottomPlotControls( ...
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
    assert(sameStringCell(ui.topX.Items, {'Time (s)', 'Sample #'}), ...
        'Top X dropdown should preserve supplied X items.');
    assert(sameStringCell(ui.topY.Items, {'VT: Vf vs time', 'IT: Im vs time'}), ...
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

function checkSingleSelectFilePanelHelper()
    fig = uifigure('Visible', 'off', 'Name', 'gamrywb_single_select_file_panel_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [3 1]);

    callbacks = struct();
    callbacks.onOpenFiles = @(~,~) [];
    callbacks.onOpenFolder = @(~,~) [];
    callbacks.onClearAll = @(~,~) [];
    callbacks.onExport = @(~,~) [];
    callbacks.onSelectFile = @(~,~) [];

    ui = gamrywb.ui.createSingleSelectFilePanel(grid, 'Export results CSV', callbacks);
    assert(strcmp(ui.panel.Title, 'Files'), 'Single-select file panel should preserve the panel title.');
    assert(ui.panel.Layout.Row == 1, 'Single-select file panel should place the panel in row 1.');
    assert(sameStringCell(ui.grid.RowHeight, {'fit', '1x', 'fit'}), ...
        'Single-select file panel should preserve row heights.');
    assert(sameStringCell(ui.grid.ColumnWidth, {'1x'}), ...
        'Single-select file panel should preserve column widths.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), ...
        'Single-select file panel should preserve padding.');
    assert(ui.grid.RowSpacing == 8 && ui.grid.ColumnSpacing == 0, ...
        'Single-select file panel should preserve row and column spacing.');
    assert(isequal(ui.buttonGrid.ColumnWidth, {'1x', '1x'}), ...
        'Single-select file panel should preserve button-grid columns.');
    assert(strcmp(ui.openButton.Text, 'Open DTA file(s)'), ...
        'Single-select file panel should preserve the open-file button text.');
    assert(strcmp(ui.openFolderButton.Text, 'Open folder recursively'), ...
        'Single-select file panel should preserve the open-folder button text.');
    assert(strcmp(ui.clearButton.Text, 'Clear all'), ...
        'Single-select file panel should preserve the clear button text.');
    assert(strcmp(ui.exportButton.Text, 'Export results CSV'), ...
        'Single-select file panel should preserve the export button text.');
    assert(strcmp(ui.listbox.Multiselect, 'off'), ...
        'Single-select file panel should create a single-select listbox.');
    assert(strcmp(ui.loadedText.Editable, 'off'), ...
        'Single-select file panel should create a read-only loaded-count field.');
    assert(strcmp(ui.loadedText.Value, 'No files loaded'), ...
        'Single-select file panel should preserve the default loaded-count text.');
    assertCallbackPresent(ui.openButton, 'ButtonPushedFcn', 'Open DTA file(s)');
    assertCallbackPresent(ui.openFolderButton, 'ButtonPushedFcn', 'Open folder recursively');
    assertCallbackPresent(ui.clearButton, 'ButtonPushedFcn', 'Clear all');
    assertCallbackPresent(ui.exportButton, 'ButtonPushedFcn', 'Export results CSV');
    assertCallbackPresent(ui.listbox, 'ValueChangedFcn', 'file listbox');
end

function fig = launchFigure(entryName, expectedTitle)
    closeAllFigures();
    feval(entryName);
    drawnow;
    figs = findall(groot, 'Type', 'figure');
    names = getFigureNames(figs);
    idx = find(strcmp(names, expectedTitle), 1);
    assert(~isempty(idx), 'GUI entry point %s did not create expected figure "%s".', entryName, expectedTitle);
    fig = figs(idx);
end

function assertTexts(fig, expectedTexts)
    actual = string(getTextValues(fig));
    for k = 1:numel(expectedTexts)
        assert(any(actual == string(expectedTexts{k})), 'Missing GUI text/control: %s', expectedTexts{k});
    end
end

function assertButtonContract(fig, expectedTexts)
    assertTexts(fig, expectedTexts);
    for k = 1:numel(expectedTexts)
        h = findControlByText(fig, expectedTexts{k}, 'ButtonPushedFcn');
        assertCallbackPresent(h, 'ButtonPushedFcn', expectedTexts{k});
    end
end

function assertCheckboxContract(fig, expectedTexts)
    assertTexts(fig, expectedTexts);
end

function assertTabTitles(fig, expectedTitles)
    actual = string(getPropertyValues(fig, 'Title'));
    for k = 1:numel(expectedTitles)
        assert(any(actual == string(expectedTitles{k})), 'Missing GUI tab/panel title: %s', expectedTitles{k});
    end
end

function group = dropdownGroup(items, count)
    group = struct('items', {items}, 'count', count);
end

function items = eisAxisItems()
    items = {'Freq (Hz)', 'log10(Freq)', 'Time (s)', 'Point #', ...
        'Zreal (ohm)', 'Zimag (ohm)', '-Zimag (ohm)', 'Zmod (ohm)', ...
        'Zphz (deg)', 'Idc (A)', 'Vdc (V)'};
end

function assertDropdownGroups(fig, expectedGroups)
    dropdowns = findControlsByClass(fig, 'DropDown');
    for k = 1:numel(expectedGroups)
        expectedItems = expectedGroups(k).items;
        expectedCount = expectedGroups(k).count;
        actualCount = 0;
        for j = 1:numel(dropdowns)
            if sameStringCell(dropdowns{j}.Items, expectedItems)
                actualCount = actualCount + 1;
            end
        end
        assert(actualCount == expectedCount, ...
            'Expected %d dropdown(s) with items [%s], found %d.', ...
            expectedCount, strjoin(expectedItems, ', '), actualCount);
    end
end

function spec = axesSpec(titleText, xLabel, yLabel)
    spec = struct('title', titleText, 'xLabel', xLabel, 'yLabel', yLabel);
end

function assertAxesContract(fig, expectedAxes)
    axesHandles = findControlsByClass(fig, 'Axes');
    assert(numel(axesHandles) == numel(expectedAxes), ...
        'Expected %d axes contract entry/entries, found %d axes.', numel(expectedAxes), numel(axesHandles));
    for k = 1:numel(expectedAxes)
        found = false;
        for j = 1:numel(axesHandles)
            if axesMatches(axesHandles{j}, expectedAxes{k})
                found = true;
                break;
            end
        end
        assert(found, 'Missing axes contract: title="%s", xlabel="%s", ylabel="%s".', ...
            expectedAxes{k}.title, expectedAxes{k}.xLabel, expectedAxes{k}.yLabel);
    end
end

function tf = axesMatches(ax, spec)
    tf = strcmp(char(ax.Title.String), spec.title) && ...
        strcmp(char(ax.XLabel.String), spec.xLabel) && ...
        strcmp(char(ax.YLabel.String), spec.yLabel);
end

function assertTableColumns(fig, expectedColumns)
    tables = findControlsByClass(fig, 'Table');
    assert(numel(tables) == 1, 'Expected exactly one result table, found %d.', numel(tables));
    assert(sameStringCell(tables{1}.ColumnName, expectedColumns), ...
        'Result table columns changed. Expected [%s], found [%s].', ...
        strjoin(expectedColumns, ', '), strjoin(toCellstr(tables{1}.ColumnName), ', '));
end

function assertFigureMinimumSize(fig, minWidth, minHeight)
    pos = fig.Position;
    assert(pos(3) >= minWidth, 'Expected figure width >= %d, found %.0f.', minWidth, pos(3));
    assert(pos(4) >= minHeight, 'Expected figure height >= %d, found %.0f.', minHeight, pos(4));
end

function assertComponentCounts(fig, expectedCounts)
    names = fieldnames(expectedCounts);
    for k = 1:numel(names)
        name = names{k};
        expected = expectedCounts.(name);
        actual = countComponents(fig, name);
        assert(actual == expected, 'Expected %d %s component(s), found %d.', expected, name, actual);
    end
end

function count = countComponents(fig, classNamePart)
    controls = allGuiObjects(fig);
    count = 0;
    for k = 1:numel(controls)
        if contains(class(controls{k}), classNamePart)
            count = count + 1;
        end
    end
end

function controls = findControlsByClass(fig, classNamePart)
    allControls = allGuiObjects(fig);
    controls = {};
    for k = 1:numel(allControls)
        if contains(class(allControls{k}), classNamePart)
            controls{end+1} = allControls{k}; %#ok<AGROW>
        end
    end
end

function assertDropdownCallbacksPresent(fig)
    controls = allGuiObjects(fig);
    for k = 1:numel(controls)
        h = controls{k};
        if contains(class(h), 'DropDown') && isprop(h, 'ValueChangedFcn')
            assertCallbackPresent(h, 'ValueChangedFcn', describeControl(h));
        end
    end
end

function invokeDropdownValue(fig, value)
    controls = allGuiObjects(fig);
    for k = 1:numel(controls)
        h = controls{k};
        if isprop(h, 'Items') && isprop(h, 'Value') && any(strcmp(h.Items, value))
            h.Value = value;
            invokeCallback(h, 'ValueChangedFcn');
            drawnow;
            return;
        end
    end
    error('Dropdown value not found: %s', value);
end

function invokeCheckbox(fig, text, value)
    h = findControlByText(fig, text, 'Value');
    h.Value = value;
    invokeCallback(h, 'ValueChangedFcn');
    drawnow;
end

function invokeButton(fig, text)
    h = findControlByText(fig, text, 'ButtonPushedFcn');
    invokeCallback(h, 'ButtonPushedFcn');
    drawnow;
end

function h = findControlByText(fig, text, callbackProperty)
    controls = allGuiObjects(fig);
    for k = 1:numel(controls)
        candidate = controls{k};
        if isprop(candidate, 'Text') && strcmp(char(candidate.Text), text) && isprop(candidate, callbackProperty)
            h = candidate;
            return;
        end
    end
    error('Control not found: %s', text);
end

function invokeCallback(h, callbackProperty)
    cb = h.(callbackProperty);
    if isempty(cb)
        return;
    end
    if isa(cb, 'function_handle')
        cb(h, []);
    elseif iscell(cb) && ~isempty(cb) && isa(cb{1}, 'function_handle')
        cb{1}(h, [], cb{2:end});
    else
        error('Unsupported callback type for %s.', callbackProperty);
    end
end

function assertCallbackPresent(h, callbackProperty, label)
    assert(~isempty(h.(callbackProperty)), 'Missing %s callback for %s.', callbackProperty, label);
end

function label = describeControl(h)
    if isprop(h, 'Text') && ~isempty(h.Text)
        label = char(h.Text);
    elseif isprop(h, 'Items') && ~isempty(h.Items)
        items = h.Items;
        if isstring(items)
            items = cellstr(items);
        end
        label = ['dropdown [' strjoin(items, ', ') ']'];
    else
        label = class(h);
    end
end

function values = getTextValues(fig)
    values = getPropertyValues(fig, 'Text');
end

function values = getPropertyValues(fig, propertyName)
    controls = allGuiObjects(fig);
    values = {};
    for k = 1:numel(controls)
        h = controls{k};
        if isprop(h, propertyName)
            v = h.(propertyName);
            if ischar(v) || isstring(v)
                values{end+1} = char(v); %#ok<AGROW>
            end
        end
    end
end

function tf = sameStringCell(actual, expected)
    actual = reshape(string(toCellstr(actual)), 1, []);
    expected = reshape(string(toCellstr(expected)), 1, []);
    tf = isequal(actual, expected);
end

function values = toCellstr(values)
    if isstring(values)
        values = cellstr(values);
    elseif ischar(values)
        values = {values};
    elseif iscell(values)
        values = cellfun(@char, values, 'UniformOutput', false);
    else
        values = cellstr(string(values));
    end
end

function objects = allGuiObjects(root)
    objects = {root};
    if ~isprop(root, 'Children')
        return;
    end
    children = root.Children;
    for k = 1:numel(children)
        objects = [objects, allGuiObjects(children(k))]; %#ok<AGROW>
    end
end

function assertUifigureAvailable()
    try
        f = uifigure('Visible', 'off', 'Name', 'gamrywb_gui_layout_probe');
        delete(f);
    catch ME
        error('GUI layout tests require MATLAB uifigure support: %s', ME.message);
    end
end

function names = getFigureNames(figs)
    names = cell(size(figs));
    for i = 1:numel(figs)
        names{i} = figs(i).Name;
    end
end

function closeAllFigures()
    figs = findall(groot, 'Type', 'figure');
    if ~isempty(figs)
        delete(figs);
    end
    drawnow;
end
