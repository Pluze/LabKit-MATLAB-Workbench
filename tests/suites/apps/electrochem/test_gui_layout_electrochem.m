function test_gui_layout_electrochem()
%TEST_GUI_LAYOUT_ELECTROCHEM Verify electrochemistry GUI layout contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures()); %#ok<NASGU>

    checkMultiDTA(h);
    checkEIS(h);
    checkCVCSC(h);
    checkCVCSCFixtureLoad();
    checkVTResistance(h);
    checkCIC(h);
end

function checkMultiDTA(h)
    fig = h.launchFigure('labkit_ChronoOverlay_app', 'Gamry Multi-DTA Plot Export GUI');
    h.assertFigureMinimumSize(fig, 1400, 850);
    h.assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 2, 'DropDown', 1, ...
        'ListBox', 1, 'TextArea', 2, 'Axes', 2));
    h.assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Remove selected', ...
        'Clear all', 'Export curves CSV'});
    h.assertCheckboxContract(fig, {'Show file-name legend', 'Show grid'});
    h.assertDropdownGroups(fig, h.dropdownGroup({'Time (s)', 'Time (ms)', 'Sample #'}, 1));
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertAxesContract(fig, { ...
        h.axesSpec('Voltage', 'Time (s)', 'Vf (V)'), ...
        h.axesSpec('Current', 'Time (s)', 'Im (A)')});
    h.assertDropdownCallbacksPresent(fig);
    h.invokeDropdownValue(fig, 'Time (ms)');
    h.invokeCheckbox(fig, 'Show file-name legend', false);
    h.invokeButton(fig, 'Clear all');
end

function checkEIS(h)
    fig = h.launchFigure('labkit_EIS_app', 'Gamry EIS Multi-DTA Plot GUI');
    h.assertFigureMinimumSize(fig, 1400, 850);
    h.assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 5, 'DropDown', 2, ...
        'ListBox', 1, 'TextArea', 3, 'Axes', 1));
    h.assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Remove selected', ...
        'Clear all', 'Export current plot CSV'});
    h.assertCheckboxContract(fig, {'Show markers', 'Log X', 'Log Y', 'Legend', 'Grid'});
    h.assertDropdownGroups(fig, h.dropdownGroup(eisAxisItems(), 2));
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertAxesContract(fig, {h.axesSpec('EIS Overlay', 'Zreal (ohm)', '-Zimag (ohm)')});
    h.assertDropdownCallbacksPresent(fig);
    h.invokeDropdownValue(fig, 'Freq (Hz)');
    h.invokeCheckbox(fig, 'Log X', true);
    h.invokeButton(fig, 'Clear all');
end

function checkCVCSC(h)
    fig = h.launchFigure('labkit_CSC_app', 'Gamry DTA GUI (literature CSC)');
    h.assertFigureMinimumSize(fig, 1500, 900);
    h.assertComponentCounts(fig, struct('Button', 9, 'CheckBox', 6, 'DropDown', 6, ...
        'ListBox', 1, 'TextArea', 1, 'Axes', 2));
    h.assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Clear all', ...
        'Reload selected', 'Auto CV + CT', 'Swap Top/Bottom', 'Compare Q / CSC', ...
        'Refresh Plots', 'Clear Both'});
    h.assertCheckboxContract(fig, {'Grid', 'Hold', 'Show Trim'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'(none)'}, 5), ...
        h.dropdownGroup({'Full', 'Cathodic', 'Anodic'}, 1)]);
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertAxesContract(fig, { ...
        h.axesSpec('Top Plot', 'X', 'Y'), ...
        h.axesSpec('Bottom Plot', 'X', 'Y')});
    h.assertDropdownCallbacksPresent(fig);
    h.invokeDropdownValue(fig, 'Cathodic');
    h.invokeButton(fig, 'Refresh Plots');
    h.invokeButton(fig, 'Clear Both');
end

function checkCVCSCFixtureLoad()
    fixture = dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');
    diagnostics = labkit_CSC_app('__labkit_test__', 'loadFileDiagnostics', fixture);

    assert(strcmp(diagnostics.file, fixture), 'CSC load should update the selected file field.');
    assert(~isempty(diagnostics.curveItems) && ~strcmp(diagnostics.curveItems{1}, '(none)'), ...
        'CSC load should populate parsed curve items.');
    assert(diagnostics.topLineCount >= 1, 'CSC load should render at least one top plot line.');
    assert(diagnostics.bottomLineCount >= 1, 'CSC load should render at least one bottom plot line.');
    assert(contains(diagnostics.qct, 'C'), 'CSC load should compute and display CT charge.');
    assert(contains(diagnostics.qcv, 'C'), 'CSC load should compute and display CV charge.');
    assert(~contains(diagnostics.status, 'Ready'), 'CSC load should update status after analysis.');
end

function checkVTResistance(h)
    fig = h.launchFigure('labkit_VTResistance_app', 'Gamry VT Steady Resistance GUI');
    h.assertFigureMinimumSize(fig, 1600, 900);
    h.assertComponentCounts(fig, struct('Button', 8, 'CheckBox', 4, 'DropDown', 7, ...
        'ListBox', 1, 'Table', 1, 'TextArea', 1, 'Axes', 2));
    h.assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Clear all', ...
        'Export results CSV', 'Re-analyze file', 'Refresh plots', 'Swap top / bottom', ...
        'Reset axes'});
    h.assertCheckboxContract(fig, {'Show markers', 'Shade windows', 'Grid'});
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Metadata first, then auto', 'Metadata only', 'Auto from Im only'}, 1), ...
        h.dropdownGroup({'Full pulse median', 'Center 60% median'}, 1), ...
        h.dropdownGroup({'Baseline-corrected dV/I', 'Raw Vf/I'}, 1), ...
        h.dropdownGroup({'Time (s)', 'Sample #'}, 2), ...
        h.dropdownGroup({'VT: Vf vs time', 'IT: Im vs time'}, 2)]);
    h.assertTableColumns(fig, {'File','Ic(A)','Ia(A)','Vc_ss(V)','Va_ss(V)', ...
        'R_cath(ohm)','R_anod(ohm)','R_avg(ohm)','Detection'});
    h.assertAxesContract(fig, { ...
        h.axesSpec('Top Plot', '', ''), ...
        h.axesSpec('Bottom Plot', '', '')});
    h.assertDropdownCallbacksPresent(fig);
    h.invokeButton(fig, 'Refresh plots');
    h.invokeButton(fig, 'Reset axes');
    h.invokeButton(fig, 'Clear all');
end

function checkCIC(h)
    fig = h.launchFigure('labkit_CIC_app', 'Gamry CIC GUI (Voltage Transient)');
    h.assertFigureMinimumSize(fig, 1600, 900);
    h.assertComponentCounts(fig, struct('Button', 7, 'CheckBox', 6, 'DropDown', 8, ...
        'ListBox', 1, 'Table', 1, 'TextArea', 1, 'Axes', 2));
    h.assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Clear all', ...
        'Export results CSV', 'Refresh plots', 'Swap top / bottom', 'Reset axes'});
    h.assertCheckboxContract(fig, { ...
        'Show debug markers', 'Show window limits', 'Shade pulse windows', ...
        'Use measured Im integration for charge (recommended)'});
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Pt (-0.6 to 0.8 V)', 'PEDOT:PSS (-0.9 to 0.6 V)', 'Custom'}, 1), ...
        h.dropdownGroup({'Metadata first, then auto', 'Metadata only', 'Auto from Im only'}, 1), ...
        h.dropdownGroup({'Cathodic phase', 'Anodic phase', 'Total biphasic'}, 1), ...
        h.dropdownGroup({'mC/cm^2', 'uC/cm^2'}, 1), ...
        h.dropdownGroup({'Time (s)', 'Sample #'}, 2), ...
        h.dropdownGroup({'VT: Vf vs time', 'IT: Im vs time'}, 2)]);
    h.assertTableColumns(fig, {'File','Amp(A)','Emc(V)','Ema(V)', ...
        'Qc(mC/cm^2)','Qa(mC/cm^2)','Qtot(mC/cm^2)','Safe'});
    h.assertAxesContract(fig, { ...
        h.axesSpec('Top Plot', '', ''), ...
        h.axesSpec('Bottom Plot', '', '')});
    h.assertDropdownCallbacksPresent(fig);
    h.invokeButton(fig, 'Refresh plots');
    h.invokeButton(fig, 'Reset axes');
    h.invokeButton(fig, 'Clear all');
end

function items = eisAxisItems()
    items = {'Freq (Hz)', 'log10(Freq)', 'Time (s)', 'Point #', ...
        'Zreal (ohm)', 'Zimag (ohm)', '-Zimag (ohm)', 'Zmod (ohm)', ...
        'Zphz (deg)', 'Idc (A)', 'Vdc (V)'};
end
