classdef GuiLayoutEisTest < matlab.unittest.TestCase
    %GUILAYOUTEISTEST Verify EIS GUI layout and workflow contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function eis_file_button_loads_selected_dta(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('eis_potentiostatic_zcurve.DTA');
            secondFolder = string(tempname);
            mkdir(secondFolder);
            secondCleanup = onCleanup(@() rmdir(secondFolder, 's'));
            secondFixture = fullfile(secondFolder, 'eis_replicate_zcurve.DTA');
            copyfile(fixture, secondFixture);
            fig = h.launchFigure('labkit_EIS_app', 'Gamry EIS Multi-DTA Plot GUI');
            assertEisLayout(h, fig);
            axisItems = eis.userInterface.axisItems();
            h.invokeDropdownValue(fig, char(axisItems(1)));
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
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.definition.contractVersion, 2, ...
                'EIS workflow must execute through Runtime V2.');
            testCase.verifyFalse(isfield(runtime.state.project.inputs, 'items'), ...
                'EIS durable project must not own decoded DTA items.');
            testCase.verifyEqual(numel(runtime.state.session.cache.items), 1, ...
                'EIS decoded DTA items should live in the session cache.');
            workflow.chooseFiles('files', secondFixture);
            workflow.click('Add DTA files');
            workflow.selectFile('files', 'eis_potentiostatic_zcurve.DTA');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(numel(runtime.state.session.selection.paths), 1, ...
                'EIS should commit a one-file selection subset.');
            testCase.verifyTrue(contains(workflow.fileSelection('files'), ...
                'eis_potentiostatic_zcurve.DTA'), ...
                'EIS presentation should preserve the selected subset.');
            ax.XLim = [-1e4 5e4];
            ax.YLim = [4e4 13e4];
            ax.XLimMode = 'manual';
            ax.YLimMode = 'manual';

            workflow.dropdown(char(axisItems(2)));
            workflow.checkbox('Log Y', true);

            testCase.verifyLessThan(diff(ax.XLim), 10, ...
                'Changing EIS coordinate selections should discard stale zoomed X limits.');
            testCase.verifyLessThan(diff(log10(ax.YLim)), 6, ...
                'Changing EIS log coordinate selections should discard stale zoomed Y limits.');

            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() rmdir(outputFolder, 's'));
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            runtime.request.outputChooser = @(~, ~, ~) deal( ...
                'gamry_eis_plot_export.csv', char(outputFolder));
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            workflow.click('Export current plot CSV');
            testCase.verifyTrue(isfile(fullfile( ...
                outputFolder, 'gamry_eis_plot_export.csv')));
            manifestPath = fullfile(outputFolder, ...
                'gamry_eis_plot_export.labkit.json');
            testCase.verifyTrue(isfile(manifestPath), ...
                'EIS export should write a standard result manifest.');
            manifest = jsondecode(fileread(manifestPath));
            testCase.verifyEqual(string(manifest.format), "labkit.result");

            projectPath = fullfile(outputFolder, 'eis-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield( ...
                saved.labkitProject.payload.inputs, 'items'), ...
                'EIS project files must exclude decoded DTA items.');
            workflow.click('Clear all');
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            testCase.verifyEqual(char(workflow.fileStatus('files')), ...
                '2 file(s) loaded', ...
                'EIS project reopen should rebuild decoded sources.');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(numel(runtime.state.session.cache.items), 2);
            clear outputCleanup;
            clear secondCleanup;
        end
    end
end

function assertEisLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
        'Clear all', 'Export current plot CSV'});
    h.assertCheckboxContract(fig, {'Show markers', 'Log X', 'Log Y', ...
        'Legend', 'Grid'});
    h.assertDropdownGroups(fig, ...
        h.dropdownGroup(cellstr(eis.userInterface.axisItems()), 2));
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertDropdownCallbacksPresent(fig);
end
