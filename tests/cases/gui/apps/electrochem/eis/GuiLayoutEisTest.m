classdef GuiLayoutEisTest < matlab.uitest.TestCase
    %GUILAYOUTEISTEST Verify EIS GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function eis_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_EIS_app', 'Gamry EIS Multi-DTA Plot GUI');
            ui = getappdata(fig, 'labkitUiRegistry');
            h.assertStandardWorkbenchLayout(fig);
            h.assertComponentCounts(fig, struct('Button', 6, 'CheckBox', 5, ...
                'DropDown', 2, 'ListBox', 1, 'TextArea', 3, 'Axes', 1));
            h.assertButtonContract(fig, {'Open DTA file(s)', ...
                'Open folder recursively', 'Remove selected', ...
                'Clear all', 'Export current plot CSV'});
            h.assertCheckboxContract(fig, {'Show markers', 'Log X', 'Log Y', ...
                'Legend', 'Grid'});
            h.assertDropdownGroups(fig, h.dropdownGroup(eisAxisItems(), 2));
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertAxesContract(fig, { ...
                h.axesSpec('EIS Overlay', 'Zreal (ohm)', '-Zimag (ohm)')});
            assertActionGroupWrapsLongFileActions(ui);
            h.assertDropdownCallbacksPresent(fig);
            h.invokeDropdownValue(fig, 'Freq (Hz)');
            h.invokeCheckbox(fig, 'Log X', true);
            h.invokeButton(fig, 'Clear all');
        end

        function eis_file_button_loads_selected_dta(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('eis_potentiostatic_zcurve.DTA');
            fig = h.launchFigure('labkit_EIS_app', 'Gamry EIS Multi-DTA Plot GUI');
            ui = getappdata(fig, 'labkitUiRegistry');
            ui.controls.files.props.dialogProvider = @(~) string(fixture);
            setappdata(fig, 'labkitUiRegistry', ui);

            h.invokeButton(fig, 'Open DTA file(s)');

            testCase.verifyEqual(ui.controls.files.status.Value, '1 file(s) loaded');
            testCase.verifyTrue(any(strcmp(ui.controls.files.listbox.Items, ...
                'eis_potentiostatic_zcurve.DTA')), ...
                'Open DTA file(s) should load the dialog-selected EIS fixture.');
            testCase.verifyNotEqual(ui.controls.summary.textArea.Value, ...
                {'No files loaded.'}, ...
                'Open DTA file(s) should refresh the EIS summary.');
            ax = ui.controls.plot.axesById.overlay;
            ax.XLim = [-1e4 5e4];
            ax.YLim = [4e4 13e4];
            ax.XLimMode = 'manual';
            ax.YLimMode = 'manual';

            h.invokeDropdownValue(fig, 'log10(Freq)');
            h.invokeCheckbox(fig, 'Log Y', true);

            testCase.verifyEqual(ax.XLimMode, 'auto');
            testCase.verifyEqual(ax.YLimMode, 'auto');
            testCase.verifyLessThan(diff(ax.XLim), 10, ...
                'Changing EIS coordinate selections should discard stale zoomed X limits.');
            testCase.verifyLessThan(diff(log10(ax.YLim)), 6, ...
                'Changing EIS log coordinate selections should discard stale zoomed Y limits.');
        end
    end
end

function assertActionGroupWrapsLongFileActions(ui)
    group = ui.controls.fileActions;
    assert(numel(group.grid.RowHeight) == 2 && ...
        numel(group.grid.ColumnWidth) == 2, ...
        'Long file actions should wrap to two columns instead of truncating in one row.');
    exportButton = group.actions.exportPlot.button;
    assert(isequal(exportButton.Layout.Row, 2) && ...
        isequal(exportButton.Layout.Column, [1 2]), ...
        'Odd trailing file action should span the second row.');
end

function items = eisAxisItems()
    items = {'Freq (Hz)', 'log10(Freq)', 'Time (s)', 'Point #', ...
        'Zreal (ohm)', 'Zimag (ohm)', '-Zimag (ohm)', 'Zmod (ohm)', ...
        'Zphz (deg)', 'Idc (A)', 'Vdc (V)'};
end
