classdef GuiLayoutEisTest < matlab.uitest.TestCase
    %GUILAYOUTEISTEST Verify EIS GUI layout and workflow contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function eis_file_button_loads_selected_dta(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('eis_potentiostatic_zcurve.DTA');
            fig = h.launchFigure('labkit_EIS_app', 'Gamry EIS Multi-DTA Plot GUI');
            assertEisLayout(h, fig);
            h.invokeDropdownValue(fig, 'Freq (Hz)');
            h.invokeCheckbox(fig, 'Log X', true);
            workflow = labkitWorkflowDriver(fig);
            workflow.chooseFiles('files', fixture);

            workflow.click('Add DTA files');

            testCase.verifyEqual(char(workflow.fileStatus('files')), '1 file(s) loaded');
            testCase.verifyTrue(any(contains(workflow.fileListItems('files'), ...
                'eis_potentiostatic_zcurve.DTA')), ...
                'Add DTA files should load the dialog-selected EIS fixture.');
            testCase.verifyNotEqual(workflow.textAreaValue('summary'), ...
                {'No files loaded.'}, ...
                'Add DTA files should refresh the EIS summary.');
            ui = workflow.registry();
            ax = ui.controls.plot.axesById.overlay;
            ax.XLim = [-1e4 5e4];
            ax.YLim = [4e4 13e4];
            ax.XLimMode = 'manual';
            ax.YLimMode = 'manual';

            workflow.dropdown('log10(Freq)');
            workflow.checkbox('Log Y', true);

            testCase.verifyLessThan(diff(ax.XLim), 10, ...
                'Changing EIS coordinate selections should discard stale zoomed X limits.');
            testCase.verifyLessThan(diff(log10(ax.YLim)), 6, ...
                'Changing EIS log coordinate selections should discard stale zoomed Y limits.');
        end
    end
end

function assertEisLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
        'Clear all', 'Export current plot CSV'});
    h.assertCheckboxContract(fig, {'Show markers', 'Log X', 'Log Y', ...
        'Legend', 'Grid'});
    h.assertDropdownGroups(fig, h.dropdownGroup(eisAxisItems(), 2));
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertDropdownCallbacksPresent(fig);
end

function items = eisAxisItems()
    items = {'Freq (Hz)', 'log10(Freq)', 'Time (s)', 'Point #', ...
        'Zreal (ohm)', 'Zimag (ohm)', '-Zimag (ohm)', 'Zmod (ohm)', ...
        'Zphz (deg)', 'Idc (A)', 'Vdc (V)'};
end
