classdef GuiLayoutVtResistanceTest < matlab.unittest.TestCase
    %GUILAYOUTVTRESISTANCETEST Verify VT resistance GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function vt_resistance_workflow_loads_analyzes_and_plots_chrono(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
            secondFixture = dtaFixturePath('chrono_chronopot_current_pulse_1ms.DTA');
            fig = h.launchFigure('labkit_VTResistance_app', ...
                'Gamry VT Steady Resistance GUI');
            assertVtResistanceLayout(h, fig);
            verifyVtPlotAxisClearRemovesAnnotations();
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('files', fixture);

            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '1 file(s) loaded');
            testCase.verifyTrue(any(contains(driver.fileListItems('files'), ...
                'chrono_chronopot_current_pulse_0p2ms.DTA')), ...
                'VT resistance workflow should list the loaded chrono fixture.');
            data = driver.tableData('results');
            testCase.verifyEqual(size(data), [1 9], ...
                'VT resistance workflow should populate one batch result row.');
            testCase.verifyEqual(string(data{1, 9}), "metadata-current", ...
                'VT resistance workflow should report metadata-backed pulse detection.');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.status.valueHandle.Value), 'OK'), ...
                'VT resistance workflow should refresh the current-file status field.');
            testCase.verifyTrue(contains(string(ui.controls.averageR.valueHandle.Value), 'ohm'), ...
                'VT resistance workflow should refresh computed resistance summary fields.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.top.Children), 0, ...
                'VT resistance workflow should draw the top plot.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.bottom.Children), 0, ...
                'VT resistance workflow should draw the bottom plot.');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.definition.contractVersion, 2, ...
                'VT resistance workflow must execute through Runtime V2.');
            testCase.verifyFalse(isfield(runtime.state.project.inputs, 'items'), ...
                'VT resistance durable project must not own decoded DTA items.');
            testCase.verifyEqual(numel(runtime.state.session.cache.items), 1, ...
                'Decoded DTA items should live in the session cache.');

            driver.chooseFiles('files', secondFixture);
            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '2 file(s) loaded');
            testCase.verifyTrue(contains(driver.fileSelection('files'), ...
                'chrono_chronopot_current_pulse_1ms.DTA'), ...
                'VT resistance append should select the newly added chrono file.');
            ui = driver.registry();
            choices = vt_resistance.userInterface.analysisChoices();
            ui.controls.voltageMode.valueHandle.Value = choices.voltageModes(2);
            h.invokeCallback(ui.controls.voltageMode.valueHandle, 'ValueChangedFcn');
            [updated, detail] = h.waitForCondition(fig, ...
                @() any(contains(string(driver.logValue('appLog')), ...
                'Reanalyzed 2 loaded file(s) with shared analysis settings.')), 5);
            testCase.verifyTrue(updated, h.waitDiagnostic(detail, ...
                'operation', 'VT resistance whole-batch recomputation'));

            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() rmdir(outputFolder, 's'));
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            runtime.request.outputChooser = @(~, ~, ~) deal( ...
                'vt_steady_resistance_results.csv', char(outputFolder));
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            driver.click('Export results CSV');
            testCase.verifyTrue(isfile(fullfile(outputFolder, ...
                'vt_steady_resistance_results.csv')));
            manifestPath = fullfile(outputFolder, ...
                'vt_steady_resistance_results.labkit.json');
            testCase.verifyTrue(isfile(manifestPath), ...
                'VT resistance export should write a standard result manifest.');
            manifest = jsondecode(fileread(manifestPath));
            testCase.verifyEqual(string(manifest.format), "labkit.result");
            testCase.verifyEqual(string(manifest.outputs.status), "success");

            projectPath = fullfile(outputFolder, 'vt-resistance-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload.inputs, 'items'));
            driver.click('Clear all');
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            testCase.verifyEqual(char(driver.fileStatus('files')), ...
                '2 file(s) loaded');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(numel(runtime.state.session.cache.items), 2);
            clear outputCleanup;
        end
    end
end

function assertVtResistanceLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
        'Clear all', 'Export results CSV'});
    h.assertTextsAbsent(fig, {'Re-analyze file', 'Refresh plots', ...
        'Swap top / bottom', 'Reset axes'});
    h.assertCheckboxContract(fig, {'Show markers', 'Shade windows', 'Grid'});
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    choices = vt_resistance.userInterface.analysisChoices();
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup(cellstr(choices.pulseModes), 1), ...
        h.dropdownGroup(cellstr(choices.steadyWindows), 1), ...
        h.dropdownGroup(cellstr(choices.voltageModes), 1), ...
        h.dropdownGroup(cellstr(choices.xAxes), 2), ...
        h.dropdownGroup(cellstr(choices.yAxes), 2)]);
    h.assertDropdownCallbacksPresent(fig);
end

function verifyVtPlotAxisClearRemovesAnnotations()
    fig = uifigure('Visible', 'off');
    cleaner = onCleanup(@() delete(fig));
    ax = uiaxes(fig);
    plot(ax, 1:3, [1 4 2], 'HandleVisibility', 'off');
    hold(ax, 'on');
    xline(ax, 2, ':', 'marker');
    text(ax, 2, 3, 'annotation', 'HandleVisibility', 'off');
    labkit.ui.plot.clear(ax, "ResetScale", true);
    assert(isempty(ax.Children), ...
        'VT plot refresh should remove previous hidden markers and annotations.');
    assert(strcmp(ax.XLimMode, 'auto') && strcmp(ax.YLimMode, 'auto'), ...
        'VT plot refresh should restore automatic axis limits.');
end
