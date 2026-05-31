function test_gui_layout_controls(scope)
%TEST_GUI_LAYOUT_CONTROLS Verify noninteractive GUI layout and safe callbacks.

    if nargin < 1 || isempty(scope)
        scope = 'all';
    end
    scope = lower(string(scope));

    assertUifigureAvailable();
    cleanup = onCleanup(@closeAllFigures);

    if scope == "all" || scope == "electrochem"
        checkMultiDTA();
        checkEIS();
        checkCVCSC();
        checkCVCSCFixtureLoad();
        checkVTResistance();
        checkCIC();
    end
    if scope == "all" || scope == "dic"
        checkDICPreprocess();
        checkDICPostprocess();
    end
    if scope == "all" || scope == "image_measurement"
        checkImageCurvatureMeasurement();
    end
    if scope == "all" || scope == "wearable"
        checkECGPrint();
    end
    if scope == "all" || scope == "ui"
        checkListboxItemsRefreshHelper();
        checkListboxSelectionHelper();
        checkLabeledSpinnerHelper();
        checkLogPanelHelper();
        checkReadOnlyTextHelpers();
        checkReadOnlyInfoRowHelper();
        checkResultTablePanelHelper();
        checkPanelGridHelper();
        checkPlotOptionsPanelHelper();
        checkCreateAxesHelper();
        checkAnchorCurveEditorHelper();
        checkRowResizeHandleHelper();
        checkCreateWorkbenchHelper();
        checkStandardWorkbenchShellHelper();
        checkTabbedDualPlotShellHelper();
        checkTopBottomPlotControlsHelper();
        checkTopBottomPlotStateHelpers();
        checkFileSelectionPanelHelper();
    end
    assert(any(scope == ["all", "electrochem", "dic", "image_measurement", "wearable", "ui"]), ...
        'Unknown GUI layout test scope: %s.', scope);
end

function checkECGPrint()
    fig = launchFigure('labkit_ECGPrint_app', 'ECG Signal Print + SNR Explorer');
    assertFigureMinimumSize(fig, 1480, 880);
    assertComponentCounts(fig, struct('Button', 6, 'DropDown', 4, ...
        'Table', 1, 'TextArea', 3, 'Axes', 4, 'Spinner', 10));
    assertButtonContract(fig, {'Open recording', 'Analyze current ROI', ...
        'Preview file header', 'Refresh import parsing', ...
        'Export segment SNR CSV', 'Export waveform PNG'});
    assertDropdownGroups(fig, [ ...
        dropdownGroup({'Auto', 'Yes', 'No'}, 1), ...
        dropdownGroup({'Auto', 'seconds', 'milliseconds', 'microseconds', 'nanoseconds'}, 1), ...
        dropdownGroup({'(none)'}, 1), ...
        dropdownGroup({'Template + residual band', 'Template + segments'}, 1)]);
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertAnyTableColumns(fig, {'Metric','Value'});
    assertAxesContract(fig, { ...
        axesSpec('Waveform + Peaks', 'Time (s)', 'Amplitude'), ...
        axesSpec('Template Noise RMS Over Time', 'Time (s)', 'Noise RMS'), ...
        axesSpec('Template SNR Over Time', 'Time (s)', 'SNR (dB)'), ...
        axesSpec('Template + Residual Band', 'Time from peak (s)', 'Amplitude')});
end

function checkImageCurvatureMeasurement()
    fig = launchFigure('labkit_CurvatureMeasurement_app', 'Image Curvature Measurement');
    assertFigureMinimumSize(fig, 1420, 860);
    assertComponentCounts(fig, struct('Button', 8, 'CheckBox', 2, ...
        'DropDown', 1, 'Table', 1, 'TextArea', 3, 'Axes', 1));
    assertButtonContract(fig, {'Open image', 'Start curve edit', ...
        'Undo last point', 'Clear curve', ...
        'Measure scale bar', 'Fit circle + curvature', ...
        'Export result CSV', 'Export overlay PNG'});
    assertCheckboxContract(fig, {'Densify before circle fit', ...
        'Show dense fit points'});
    assertDropdownGroups(fig, dropdownGroup({'Curve', 'Straight lines'}, 1));
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertTableColumns(fig, {'Metric', 'Value'});
    assertAxesContract(fig, {axesSpec('Image + Circle Fit', '', '')});
end

function checkDICPreprocess()
    fig = launchFigure('labkit_DICPreprocess_app', 'DIC Image Preprocess');
    assertFigureMinimumSize(fig, 1400, 860);
    assertComponentCounts(fig, struct('Button', 19, 'DropDown', 2, ...
        'TextArea', 4, 'Axes', 2));
    assertButtonContract(fig, {'Open reference image', 'Open moving image', ...
        'Select points + align', 'Auto align current pair', ...
        'Start/reset crop ROI', 'Apply ROI crop', 'Cancel ROI', ...
        'Undo align/crop', 'Save current images', 'Reset to originals', ...
        'Start ROI edit', 'Preview ROI mask', 'Add to mask', ...
        'Subtract from mask', 'Undo point', 'Undo mask edit', ...
        'Clear boundary', 'Clear mask', 'Save ROI mask'});
    assertDropdownGroups(fig, [ ...
        dropdownGroup({'Current pair', 'Current moving image', ...
        'False-color overlay', 'Original pair', 'ROI mask'}, 1), ...
        dropdownGroup({'Curve', 'Straight lines'}, 1)]);
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertAxesContract(fig, { ...
        axesSpec('Reference', '', ''), ...
        axesSpec('Current Preview', '', '')});
    assertDropdownCallbacksPresent(fig);
    assert(~isempty(fig.WindowScrollWheelFcn), ...
        'DIC preprocess should install a preview scroll-wheel zoom callback.');
end

function checkDICPostprocess()
    fig = launchFigure('labkit_DICPostprocess_app', 'DIC Strain Postprocess');
    assertFigureMinimumSize(fig, 1450, 880);
    assertComponentCounts(fig, struct('Button', 7, 'Table', 1, ...
        'TextArea', 2, 'Axes', 2));
    assertButtonContract(fig, {'Open DIC MAT', 'Open reference image', ...
        'Open mask image', 'Generate overlays + summary', ...
        'Save overlay PNGs', 'Export summary CSV', ...
        'Export strain colorbar + levels'});
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertTableColumns(fig, {'Metric','EXX','EYY'});
    assertAxesContract(fig, { ...
        axesSpec('EXX Overlay', '', ''), ...
        axesSpec('EYY Overlay', '', '')});
end

function checkMultiDTA()
    fig = launchFigure('labkit_ChronoOverlay_app', 'Gamry Multi-DTA Plot Export GUI');
    assertFigureMinimumSize(fig, 1400, 850);
    assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 2, 'DropDown', 1, ...
        'ListBox', 1, 'TextArea', 2, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Remove selected', ...
        'Clear all', 'Export curves CSV'});
    assertCheckboxContract(fig, {'Show file-name legend', 'Show grid'});
    assertDropdownGroups(fig, dropdownGroup({'Time (s)', 'Time (ms)', 'Sample #'}, 1));
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertAxesContract(fig, { ...
        axesSpec('Voltage', 'Time (s)', 'Vf (V)'), ...
        axesSpec('Current', 'Time (s)', 'Im (A)')});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Time (ms)');
    invokeCheckbox(fig, 'Show file-name legend', false);
    invokeButton(fig, 'Clear all');
end

function checkEIS()
    fig = launchFigure('labkit_EIS_app', 'Gamry EIS Multi-DTA Plot GUI');
    assertFigureMinimumSize(fig, 1400, 850);
    assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 5, 'DropDown', 2, ...
        'ListBox', 1, 'TextArea', 3, 'Axes', 1));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Remove selected', ...
        'Clear all', 'Export current plot CSV'});
    assertCheckboxContract(fig, {'Show markers', 'Log X', 'Log Y', 'Legend', 'Grid'});
    assertDropdownGroups(fig, dropdownGroup(eisAxisItems(), 2));
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertAxesContract(fig, {axesSpec('EIS Overlay', 'Zreal (ohm)', '-Zimag (ohm)')});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Freq (Hz)');
    invokeCheckbox(fig, 'Log X', true);
    invokeButton(fig, 'Clear all');
end

function checkCVCSC()
    fig = launchFigure('labkit_CSC_app', 'Gamry DTA GUI (literature CSC)');
    assertFigureMinimumSize(fig, 1500, 900);
    assertComponentCounts(fig, struct('Button', 9, 'CheckBox', 6, 'DropDown', 6, ...
        'ListBox', 1, 'TextArea', 1, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Clear all', ...
        'Reload selected', 'Auto CV + CT', 'Swap Top/Bottom', 'Compare Q / CSC', ...
        'Refresh Plots', 'Clear Both'});
    assertCheckboxContract(fig, {'Grid', 'Hold', 'Show Trim'});
    assertDropdownGroups(fig, [ ...
        dropdownGroup({'(none)'}, 5), ...
        dropdownGroup({'Full', 'Cathodic', 'Anodic'}, 1)]);
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertAxesContract(fig, { ...
        axesSpec('Top Plot', 'X', 'Y'), ...
        axesSpec('Bottom Plot', 'X', 'Y')});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Cathodic');
    invokeButton(fig, 'Refresh Plots');
    invokeButton(fig, 'Clear Both');
end

function checkCVCSCFixtureLoad()
    fixture = dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');
    diagnostics = labkit_CSC_app('__test_loadFile__', fixture);

    assert(strcmp(diagnostics.file, fixture), 'CSC load should update the selected file field.');
    assert(~isempty(diagnostics.curveItems) && ~strcmp(diagnostics.curveItems{1}, '(none)'), ...
        'CSC load should populate parsed curve items.');
    assert(diagnostics.topLineCount >= 1, 'CSC load should render at least one top plot line.');
    assert(diagnostics.bottomLineCount >= 1, 'CSC load should render at least one bottom plot line.');
    assert(contains(diagnostics.qct, 'C'), 'CSC load should compute and display CT charge.');
    assert(contains(diagnostics.qcv, 'C'), 'CSC load should compute and display CV charge.');
    assert(~contains(diagnostics.status, 'Ready'), 'CSC load should update status after analysis.');
end

function checkVTResistance()
    fig = launchFigure('labkit_VTResistance_app', 'Gamry VT Steady Resistance GUI');
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
    fig = launchFigure('labkit_CIC_app', 'Gamry CIC GUI (Voltage Transient)');
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

function checkListboxItemsRefreshHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_file_listbox_refresh_probe');
    cleaner = onCleanup(@() delete(fig));
    lb = uilistbox(fig, 'Items', {}, 'Multiselect', 'on');

    labkit.ui.refreshListboxItems(lb, {'a.DTA', 'b.DTA'});
    assert(sameStringCell(lb.Items, {'a.DTA', 'b.DTA'}), ...
        'File listbox helper should populate item display names.');
    assert(sameStringCell(lb.Value, {'a.DTA', 'b.DTA'}), ...
        'File listbox helper should select all items when there is no prior selection.');

    lb.Value = {'b.DTA'};
    labkit.ui.refreshListboxItems(lb, {'b.DTA', 'c.DTA'});
    assert(sameStringCell(lb.Items, {'b.DTA', 'c.DTA'}), ...
        'File listbox helper should update item display names.');
    assert(sameStringCell(lb.Value, {'b.DTA'}), ...
        'File listbox helper should preserve valid prior selections.');

    labkit.ui.refreshListboxItems(lb, {});
    assert(isempty(lb.Items) && isempty(lb.Value), ...
        'File listbox helper should clear listbox items and values for empty sessions.');
end

function checkListboxSelectionHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_file_listbox_selection_probe');
    cleaner = onCleanup(@() delete(fig));
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
    assert(sameStringCell(value, {'x.DTA', 'y.DTA'}) && isequal(idx, [1 2]), ...
        'Listbox selection helper should support selecting all multi-select items by default.');

    [value, idx] = labkit.ui.refreshListboxSelection( ...
        multiList, {'y.DTA', 'z.DTA'}, {'y.DTA', 'missing.DTA'}, ...
        struct('defaultSelection', 'all'));
    assert(sameStringCell(value, {'y.DTA'}) && isequal(idx, 1), ...
        'Listbox selection helper should preserve only valid multi-select choices.');
end

function checkLogPanelHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_log_panel_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);

    ui = labkit.ui.createLogPanel(grid, 2, {'Started.'});
    assert(strcmp(ui.panel.Title, 'Log'), 'Log panel helper should preserve the panel title.');
    assert(ui.panel.Layout.Row == 2, 'Log panel helper should place the panel in the requested row.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), 'Log panel helper should preserve grid padding.');
    assert(strcmp(ui.textArea.Editable, 'off'), 'Log panel helper should create a read-only text area.');
    assert(sameStringCell(ui.textArea.Value, {'Started.'}), ...
        'Log panel helper should preserve supplied initial log text.');
end

function checkLabeledSpinnerHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_labeled_spinner_probe');
    cleaner = onCleanup(@() delete(fig));
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

function checkReadOnlyTextHelpers()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_read_only_text_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);

    field = labkit.ui.createReadOnlyTextField(grid, 'Value', 'Status');
    field.Layout.Row = 1;
    assert(strcmp(field.Editable, 'off') && strcmp(field.Value, 'Status'), ...
        'Read-only text field helper should create a non-editable text field.');

    panelUi = labkit.ui.createReadOnlyTextPanel(grid, 'Notes', 2, {'one', 'two'});
    assert(strcmp(panelUi.panel.Title, 'Notes'), ...
        'Read-only text panel helper should preserve the panel title.');
    assert(strcmp(panelUi.textArea.Editable, 'off') && ...
        sameStringCell(panelUi.textArea.Value, {'one', 'two'}), ...
        'Read-only text panel helper should preserve read-only text lines.');
end

function checkReadOnlyInfoRowHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_read_only_info_row_probe');
    cleaner = onCleanup(@() delete(fig));
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

function checkResultTablePanelHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_result_table_panel_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);

    ui = labkit.ui.createResultTablePanel(grid, 'Batch Results', 2, ...
        {'File', 'Value'}, cell(0, 2));
    assert(strcmp(ui.panel.Title, 'Batch Results'), ...
        'Result table panel helper should preserve the panel title.');
    assert(ui.panel.Layout.Row == 2, ...
        'Result table panel helper should place the panel in the requested row.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), ...
        'Result table panel helper should preserve grid padding.');
    assert(sameStringCell(ui.table.ColumnName, {'File', 'Value'}), ...
        'Result table panel helper should preserve supplied column names.');
    assert(isequal(size(ui.table.Data), [0 2]), ...
        'Result table panel helper should preserve supplied empty table width.');
end

function checkPanelGridHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_panel_grid_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);

    ui = labkit.ui.createPanelGrid(grid, 'Probe Panel', 2, [3 2]);
    assert(strcmp(ui.panel.Title, 'Probe Panel'), ...
        'Panel-grid helper should preserve the requested panel title.');
    assert(ui.panel.Layout.Row == 2, ...
        'Panel-grid helper should place the panel in the requested row.');
    assert(sameStringCell(ui.grid.RowHeight, {'fit', 'fit', 'fit'}), ...
        'Panel-grid helper should default to fit-height rows.');
    assert(sameStringCell(ui.grid.ColumnWidth, {'fit', '1x'}), ...
        'Panel-grid helper should default two-column controls to label/value widths.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), ...
        'Panel-grid helper should preserve standard padding.');

    opts = struct('columnWidth', {{'1x', '1x'}}, 'padding', [0 0 0 0]);
    ui2 = labkit.ui.createPanelGrid(grid, 'Actions', 1, [2 2], opts);
    assert(sameStringCell(ui2.grid.ColumnWidth, {'1x', '1x'}), ...
        'Panel-grid helper should support explicit action-column widths.');
    assert(isequal(ui2.grid.Padding, [0 0 0 0]), ...
        'Panel-grid helper should support explicit padding.');

    growGrid = uigridlayout(fig, [1 1]);
    growGrid.RowHeight = {50};
    labkit.ui.createPanelGrid(growGrid, 'Tall Controls', 1, [5 2]);
    assert(growGrid.RowHeight{1} > 50, ...
        'Panel-grid helper should grow undersized fixed parent rows to avoid clipped controls.');
end

function checkPlotOptionsPanelHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_plot_options_panel_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [3 1]);

    ui = labkit.ui.createPlotOptionsPanel(grid, 3);
    assert(strcmp(ui.panel.Title, 'Plot Options'), 'Plot-options helper should preserve the panel title.');
    assert(ui.panel.Layout.Row == 3, 'Plot-options helper should place the panel in row 3.');
    assert(sameStringCell(ui.grid.RowHeight, {'fit', 'fit', 'fit'}), ...
        'Plot-options helper should create fit-height rows.');
    assert(sameStringCell(ui.grid.ColumnWidth, {'fit', '1x'}), ...
        'Plot-options helper should preserve column widths.');
    assert(isequal(ui.grid.Padding, [8 8 8 8]), 'Plot-options helper should preserve padding.');
    assert(ui.grid.RowSpacing == 8 && ui.grid.ColumnSpacing == 8, ...
        'Plot-options helper should preserve row and column spacing.');

    ui2 = labkit.ui.createPlotOptionsPanel(grid, 2, 2);
    assert(ui2.panel.Layout.Row == 2, ...
        'Plot-options helper should support an explicit parent-grid row.');
end

function checkCreateAxesHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_create_axes_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);

    ax = labkit.ui.createAxes(grid, 2, 'Probe Title', 'Probe X', 'Probe Y');
    plot(ax, 1:3, [1 4 2], 'DisplayName', 'probe');
    labkit.ui.enableAxesPopout(ax);
    assert(ax.Layout.Row == 2, 'Axes helper should set the requested layout row.');
    assert(strcmp(char(ax.Title.String), 'Probe Title'), 'Axes helper should preserve the title.');
    assert(strcmp(char(ax.XLabel.String), 'Probe X'), 'Axes helper should preserve the x label.');
    assert(strcmp(char(ax.YLabel.String), 'Probe Y'), 'Axes helper should preserve the y label.');
    assertAxesPopoutEnabled(ax, 'Axes helper should install the LabKit popout context action.');

    popoutFig = labkit.ui.popoutAxes(ax);
    popoutCleaner = onCleanup(@() delete(popoutFig));
    popoutAxes = findobj(popoutFig, 'Type', 'axes');
    assert(numel(popoutAxes) >= 1, 'Axes popout should create an editable figure axes.');
    assert(strcmp(char(popoutAxes(1).Title.String), 'Probe Title'), ...
        'Axes popout should preserve the source title.');
    assert(~isempty(popoutAxes(1).Children), ...
        'Axes popout should copy plotted children.');
    assert(strcmp(popoutAxes(1).DataAspectRatioMode, 'auto') && ...
        strcmp(popoutAxes(1).PlotBoxAspectRatioMode, 'auto'), ...
        'Axes popout should leave the copied plot with freely adjustable aspect ratio.');
    assertAxesChildrenUsePopoutMenu(ax, ...
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
    cleaner = onCleanup(@() delete(fig));
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
        'Open anchor editor should insert points by shortest path order instead of always appending.');
    editor.undoLast();
    assert(isequal(size(editor.getPoints()), [4 2]), ...
        'Anchor curve editor should remove the last anchor.');
    editor.clearPoints();
    assert(isempty(editor.getPoints()), 'Anchor curve editor should clear anchors.');

    function markChanged()
        changed = true;
    end
end

function checkRowResizeHandleHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_row_resize_probe');
    cleaner = onCleanup(@() delete(fig));
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
    assertCallbackPresent(handle, 'ButtonDownFcn', 'row-resize handle');
    invokeCallback(handle, 'ButtonDownFcn');
    assert(~isempty(fig.WindowButtonMotionFcn) && ~isempty(fig.WindowButtonUpFcn), ...
        'Row-resize drag should install temporary figure motion callbacks.');
    invokeCallback(fig, 'WindowButtonUpFcn');
    assert(isempty(fig.WindowButtonMotionFcn) && isempty(fig.WindowButtonUpFcn), ...
        'Row-resize drag should clear temporary figure callbacks after release.');
end

function checkCreateWorkbenchHelper()
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
    cleaner = onCleanup(@() delete(ui.fig));

    assert(isequal(ui.main.ColumnWidth, {330, 6, '1x'}), ...
        'Workbench helper should create the standard resizable left/separator/right layout.');
    assertTabTitles(ui.fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertScrollablePanel(ui.filesAnalysisScrollPanel, 'Files + Analysis tab');
    assertScrollableGrid(ui.filesAnalysisGrid, 'Files + Analysis grid');
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
    assertTabTitles(custom.fig, {'Probe Controls'});
    assertScrollablePanel(custom.probeScrollPanel, 'Probe Controls tab');
    assertScrollableGrid(custom.probeGrid, 'Probe Controls grid');
    assert(sameStringCell(custom.probeGrid.RowHeight, {'fit', '1x'}), ...
        'Workbench helper should preserve custom tab specs.');
    assert(isempty(custom.probeResizeHandles), ...
        'Custom tabs without resizeRows should not create resize handles.');

    dual = labkit.ui.createWorkbench( ...
        'labkit_create_dual_plot_workbench_probe', ...
        [40 30 1200 760], ...
        330, ...
        struct('rightKind', 'dualPlot'));
    cleaner2 = onCleanup(@() delete(dual.fig)); %#ok<NASGU>
    assert(sameStringCell(dual.rightGrid.RowHeight, {'fit', '1x', 'fit', '1x'}), ...
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
    assert(sameStringCell(dualNoControls.rightGrid.RowHeight, {'1x', '1x'}), ...
        'Workbench helper should support dual-plot output without empty control rows.');
    assert(isempty(dualNoControls.topControlsPanel) && isempty(dualNoControls.bottomControlsPanel), ...
        'Dual-plot output without controls should not create empty plot-control panels.');
    assert(dualNoControls.topAxes.Layout.Row == 1 && dualNoControls.bottomAxes.Layout.Row == 2, ...
        'Dual-plot output without controls should place axes directly in the output grid.');
end

function labels = tabbedShellLabels()
    labels = struct( ...
        'controlsPanel', 'Controls', ...
        'filesAnalysisTab', 'Files + Analysis', ...
        'summaryResultsTab', 'Summary + Results', ...
        'logTab', 'Log', ...
        'plotsPanel', 'Plots', ...
        'topPlot', 'Top Plot', ...
        'bottomPlot', 'Bottom Plot');
end

function checkStandardWorkbenchShellHelper()
    ui = labkit.ui.createStandardWorkbenchShell( ...
        'labkit_standard_workbench_shell_probe', ...
        [40 30 1200 760], ...
        340, ...
        'Preview', ...
        [2 1], ...
        {'1x', 'fit'}, ...
        8);
    cleaner = onCleanup(@() delete(ui.fig));

    assert(isequal(ui.main.ColumnWidth, {340, 6, '1x'}), ...
        'Standard workbench shell should preserve the main column widths.');
    assertTabTitles(ui.fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertScrollablePanel(ui.filesAnalysisScrollPanel, 'Files + Analysis tab');
    assertScrollablePanel(ui.summaryResultsScrollPanel, 'Summary + Results tab');
    assertScrollablePanel(ui.logScrollPanel, 'Log tab');
    assertScrollableGrid(ui.filesAnalysisGrid, 'Files + Analysis grid');
    assertScrollableGrid(ui.summaryResultsGrid, 'Summary + Results grid');
    assertScrollableGrid(ui.logGrid, 'Log grid');
    assert(numel(ui.filesAnalysisResizeHandles) == 2, ...
        'Standard workbench shell should attach standard Files + Analysis row-resize handles.');
    assert(numel(ui.summaryResultsResizeHandles) == 1, ...
        'Standard workbench shell should attach standard Summary + Results row-resize handles.');
    assert(isequal(ui.rightGrid.RowHeight, {'1x', 'fit'}), ...
        'Standard workbench shell should preserve right-grid row heights.');
end

function checkTabbedDualPlotShellHelper()
    labels = tabbedShellLabels();
    ui = labkit.ui.createTabbedDualPlotShell( ...
        'labkit_tabbed_dual_plot_shell_probe', ...
        [40 30 1680 980], ...
        430, ...
        labels);
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
    assertScrollablePanel(ui.filesAnalysisScrollPanel, 'Files + Analysis tab');
    assertScrollablePanel(ui.summaryResultsScrollPanel, 'Summary + Results tab');
    assertScrollablePanel(ui.logScrollPanel, 'Log tab');
    assertScrollableGrid(ui.filesAnalysisGrid, 'Files + Analysis grid');
    assertScrollableGrid(ui.summaryResultsGrid, 'Summary + Results grid');
    assertScrollableGrid(ui.logGrid, 'Log grid');
    assert(isequal(ui.filesAnalysisGrid.RowHeight, {260, 6, 'fit', 6, 'fit'}), ...
        'Files + Analysis grid should preserve row heights.');
    assert(isequal(ui.summaryResultsGrid.RowHeight, {'fit', 6, '1x'}), ...
        'Summary + Results grid should preserve row heights.');
    assert(isequal(ui.filesAnalysisGrid.UserData.LabKitLogicalRowMap, [1 3 5]), ...
        'Files + Analysis grid should map logical rows to physical resize rows.');
    assert(isequal(ui.summaryResultsGrid.UserData.LabKitLogicalRowMap, [1 3]), ...
        'Summary + Results grid should map logical rows to physical resize rows.');
    assert(numel(ui.filesAnalysisResizeHandles) == 2, ...
        'Tabbed dual-plot shell should attach standard Files + Analysis row-resize handles.');
    assert(numel(ui.summaryResultsResizeHandles) == 1, ...
        'Tabbed dual-plot shell should attach standard Summary + Results row-resize handles.');
    assert(sameStringCell(ui.rightGrid.RowHeight, {'fit', '1x', 'fit', '1x'}), ...
        'Right plot grid should preserve top/bottom row heights.');
    assert(strcmp(char(ui.topAxes.Title.String), 'Top Plot'), ...
        'Tabbed dual-plot shell should create the top axes with the expected title.');
    assert(strcmp(char(ui.bottomAxes.Title.String), 'Bottom Plot'), ...
        'Tabbed dual-plot shell should create the bottom axes with the expected title.');
end

function checkTopBottomPlotControlsHelper()
    labels = tabbedShellLabels();
    shell = labkit.ui.createTabbedDualPlotShell( ...
        'labkit_top_bottom_plot_controls_probe', ...
        [40 30 1680 980], ...
        430, ...
        labels);
    cleaner = onCleanup(@() delete(shell.fig));

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

function checkTopBottomPlotStateHelpers()
    labels = tabbedShellLabels();
    shell = labkit.ui.createTabbedDualPlotShell( ...
        'labkit_top_bottom_plot_state_probe', ...
        [40 30 1680 980], ...
        430, ...
        labels);
    cleaner = onCleanup(@() delete(shell.fig));

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
    assertAxesPopoutEnabled(shell.topAxes, 'Hard axis reset should install top-axis popout.');
    assertAxesPopoutEnabled(shell.bottomAxes, 'Hard axis reset should install bottom-axis popout.');
end

function checkFileSelectionPanelHelper()
    fig = uifigure('Visible', 'off', 'Name', 'labkit_file_selection_panel_probe');
    cleaner = onCleanup(@() delete(fig));
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
    assert(sameStringCell(ui.grid.RowHeight, {'fit', '1x', 'fit'}), ...
        'File-selection panel should preserve row heights.');
    assert(sameStringCell(ui.grid.ColumnWidth, {'1x'}), ...
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
    assertCallbackPresent(ui.openButton, 'ButtonPushedFcn', 'Open DTA file(s)');
    assertCallbackPresent(ui.openFolderButton, 'ButtonPushedFcn', 'Open folder recursively');
    assertCallbackPresent(ui.clearButton, 'ButtonPushedFcn', 'Clear all');
    assertCallbackPresent(ui.exportButton, 'ButtonPushedFcn', 'Export results CSV');
    assertCallbackPresent(ui.listbox, 'ValueChangedFcn', 'file listbox');

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

function assertScrollablePanel(panel, label)
    assert(isprop(panel, 'Scrollable'), '%s should expose a Scrollable property.', label);
    assert(strcmp(char(panel.Scrollable), 'on'), '%s should be scrollable.', label);
end

function assertScrollableGrid(grid, label)
    assert(isprop(grid, 'Scrollable'), '%s should expose a Scrollable property.', label);
    assert(strcmp(char(grid.Scrollable), 'on'), '%s should be scrollable.', label);
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

function assertAxesPopoutEnabled(ax, message)
    menu = ax.ContextMenu;
    assert(~isempty(menu) && isvalid(menu), message);
    item = findall(menu, 'Type', 'uimenu', 'Tag', 'labkitAxesPopoutMenu');
    assert(numel(item) == 1, message);
    assert(strcmp(item.Text, 'Open axes in new figure'), message);
end

function assertAxesChildrenUsePopoutMenu(ax, message)
    menu = ax.ContextMenu;
    children = ax.Children;
    assert(~isempty(children), message);
    for k = 1:numel(children)
        if isprop(children(k), 'ContextMenu')
            assert(isequal(children(k).ContextMenu, menu), message);
        end
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

function assertAnyTableColumns(fig, expectedColumns)
    tables = findControlsByClass(fig, 'Table');
    for k = 1:numel(tables)
        if sameStringCell(tables{k}.ColumnName, expectedColumns)
            return;
        end
    end
    found = cell(1, numel(tables));
    for k = 1:numel(tables)
        found{k} = ['[' strjoin(toCellstr(tables{k}.ColumnName), ', ') ']'];
    end
    assert(false, 'Missing table columns [%s]. Found %s.', ...
        strjoin(expectedColumns, ', '), strjoin(found, '; '));
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
        f = uifigure('Visible', 'off', 'Name', 'labkit_gui_layout_probe');
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
