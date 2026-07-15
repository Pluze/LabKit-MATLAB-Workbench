classdef GuiLayoutCicTest < matlab.unittest.TestCase
    %GUILAYOUTCICTEST Verify CIC GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function cic_workflow_loads_analyzes_and_plots_chrono(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
            secondFixture = dtaFixturePath('chrono_chronopot_current_pulse_1ms.DTA');
            thirdFolder = string(tempname);
            mkdir(thirdFolder);
            thirdCleanup = onCleanup(@() rmdir(thirdFolder, 's'));
            thirdFixture = fullfile(thirdFolder, 'chrono_third_pulse.DTA');
            copyfile(secondFixture, thirdFixture);
            fig = h.launchFigure('labkit_CIC_app', ...
                'Gamry CIC GUI (Voltage Transient)');
            assertCicLayout(h, fig);
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('files', fixture);

            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '1 file(s) loaded');
            testCase.verifyTrue(any(contains(driver.fileListItems('files'), ...
                'chrono_chronopot_current_pulse_0p2ms.DTA')), ...
                'CIC workflow should list the loaded chrono fixture.');
            data = driver.tableData('results');
            testCase.verifyEqual(size(data), [1 8], ...
                'CIC workflow should populate one batch result row.');
            testCase.verifyTrue(isnumeric(data{1, 5}) && isfinite(data{1, 5}), ...
                'CIC workflow should compute a cathodic charge value.');
            testCase.verifyTrue(ischar(data{1, 8}) || isstring(data{1, 8}), ...
                'CIC workflow should populate the safety result column.');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.detect.valueHandle.Value), ...
                'metadata-current'), ...
                'CIC workflow should refresh the detection summary field.');
            testCase.verifyTrue(contains(string(ui.controls.qt.valueHandle.Value), 'C'), ...
                'CIC workflow should refresh computed total charge summary fields.');
            testCase.verifyTrue(strlength(string(ui.controls.safe.valueHandle.Value)) > 1, ...
                'CIC workflow should refresh the safety summary field.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.top.Children), 0, ...
                'CIC workflow should draw the top plot.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.bottom.Children), 0, ...
                'CIC workflow should draw the bottom plot.');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.definition.contractVersion, 2, ...
                'CIC workflow must execute through Runtime V2.');
            testCase.verifyFalse(isfield(runtime.state.project.inputs, 'items'), ...
                'CIC durable project must not own decoded DTA items.');
            testCase.verifyEqual(numel(runtime.state.session.cache.items), 1, ...
                'CIC decoded DTA items should live in the session cache.');
            topAxes = ui.controls.plotAxes.axesById.top;
            bottomAxes = ui.controls.plotAxes.axesById.bottom;
            assertExtremaLabelsAreReadable(topAxes);
            topAxes.XLim = [-1 0];
            topAxes.YLim = [-0.01 0.01];

            driver.chooseFiles('files', [string(secondFixture); thirdFixture]);
            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '3 file(s) loaded');
            testCase.verifyTrue(contains(driver.fileSelection('files'), ...
                'chrono_third_pulse.DTA'), ...
                'CIC batch append should select the last newly added chrono file.');
            assertCicFileSelection(testCase, driver, fig, ...
                'chrono_chronopot_current_pulse_0p2ms.DTA', 1);
            assertCicFileSelection(testCase, driver, fig, ...
                'chrono_chronopot_current_pulse_1ms.DTA', 2);
            assertCicFileSelection(testCase, driver, fig, ...
                'chrono_chronopot_current_pulse_0p2ms.DTA', 1);
            beforeAreaChange = driver.tableData('results');
            ui = driver.registry();
            ui.controls.area.valueHandle.Value = '2';
            h.invokeCallback(ui.controls.area.valueHandle, 'ValueChangedFcn');
            [updated, detail] = h.waitForCondition(fig, ...
                @() allRowsAreHalf(driver.tableData('results'), beforeAreaChange), 5);
            testCase.verifyTrue(updated, h.waitDiagnostic(detail, ...
                'operation', 'CIC whole-batch area recomputation'));
            afterAreaChange = driver.tableData('results');
            for row = 1:3
                testCase.verifyEqual(afterAreaChange{row, 7}, ...
                    0.5 * beforeAreaChange{row, 7}, 'RelTol', 1e-12, ...
                    'A shared CIC area change should recompute every loaded file.');
            end
            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() rmdir(outputFolder, 's'));
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            runtime.request.outputChooser = @(~, ~, ~) deal( ...
                'cic_results.csv', char(outputFolder));
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            driver.click('Export results CSV');
            testCase.verifyTrue(isfile(fullfile(outputFolder, 'cic_results.csv')));
            resultManifestPath = fullfile(outputFolder, ...
                'cic_results.labkit.json');
            testCase.verifyTrue(isfile(resultManifestPath), ...
                'CIC export should write a standard result manifest.');
            resultManifest = jsondecode(fileread(resultManifestPath));
            testCase.verifyEqual(string(resultManifest.format), "labkit.result");
            testCase.verifyEqual(string(resultManifest.outputs.status), "success");

            projectPath = fullfile(outputFolder, 'cic-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield( ...
                saved.labkitProject.payload.inputs, 'items'), ...
                'CIC project files must exclude decoded DTA items.');
            driver.click('Clear all');
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            testCase.verifyEqual(char(driver.fileStatus('files')), ...
                '3 file(s) loaded', ...
                'CIC project reopen should rebuild decoded sources.');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(numel(runtime.state.session.cache.items), 3);
            testCase.verifyFalse(isequal(topAxes.XLim, [-1 0]), ...
                'CIC append redraw should replace stale manual X limits.');
            testCase.verifyFalse(isequal(topAxes.YLim, [-0.01 0.01]), ...
                'CIC append redraw should replace stale manual Y limits.');

            driver.click('Clear all');
            testCase.verifyEqual(char(driver.fileStatus('files')), 'No files loaded');
            testCase.verifyEmpty(topAxes.Children, ...
                'CIC clear-all should remove stale plot markers and annotations.');
            testCase.verifyEmpty(bottomAxes.Children, ...
                'CIC clear-all should remove stale bottom plot markers and annotations.');
            testCase.verifyEqual(topAxes.XLimMode, 'auto', ...
                'CIC clear-all should restore automatic X limits.');
            testCase.verifyEqual(topAxes.YLimMode, 'auto', ...
                'CIC clear-all should restore automatic Y limits.');
            clear outputCleanup;
            clear thirdCleanup;
        end
    end
end

function tf = allRowsAreHalf(actual, previous)
    tf = size(actual, 1) == 3 && size(previous, 1) == 3;
    for row = 1:3
        tf = tf && abs(actual{row, 7} - 0.5 * previous{row, 7}) <= ...
            1e-12 * max(1, abs(previous{row, 7}));
    end
end

function assertCicFileSelection(testCase, driver, fig, fileName, index)
    driver.selectFile('files', fileName);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    testCase.verifyEqual(runtime.state.session.selection.currentIndex, index, ...
        'Selecting an imported CIC file should update canonical selection.');
    testCase.verifyTrue(contains(driver.fileSelection('files'), fileName), ...
        'CIC should preserve the selected file after presentation.');
end

function assertCicLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
        'Clear all', 'Export results CSV'});
    h.assertTextsAbsent(fig, {'Refresh plots', 'Swap top / bottom', ...
        'Reset axes'});
    h.assertCheckboxContract(fig, { ...
        'Show debug markers', 'Show window limits', 'Shade pulse windows', ...
        'Use measured Im integration for charge (recommended)'});
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    choices = cic.userInterface.analysisChoices();
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup(cellstr(choices.presets), 1), ...
        h.dropdownGroup(cellstr(choices.pulseModes), 1), ...
        h.dropdownGroup(cellstr(choices.cicModes), 1), ...
        h.dropdownGroup(cellstr(choices.cicUnits), 1), ...
        h.dropdownGroup(cellstr(choices.xAxes), 2), ...
        h.dropdownGroup(cellstr(choices.yAxes), 2)]);
    h.assertDropdownCallbacksPresent(fig);
    labels = string(get(findall(fig, '-property', 'Text'), 'Text'));
    testLabel = "Delay after pulse end (us):";
    assert(any(labels == testLabel), ...
        'CIC delay control should state that its value is measured in microseconds.');
end

function assertExtremaLabelsAreReadable(ax)
    texts = findall(ax, 'Type', 'text');
    labels = string(get(texts, 'String'));
    if isscalar(texts)
        labels = string(texts.String);
    end
    emc = texts(contains(labels, "Emc ="));
    ema = texts(contains(labels, "Ema ="));
    assert(~isempty(emc) && ~isempty(ema), ...
        'CIC VT plot should label Emc and Ema markers.');
    assert(isWhiteBackground(emc(1)) && isWhiteBackground(ema(1)), ...
        'CIC Emc/Ema labels should have a readable background.');
    assert(~strcmp(emc(1).HorizontalAlignment, ema(1).HorizontalAlignment), ...
        'CIC Emc/Ema labels should be staggered to reduce overlap.');
end

function tf = isWhiteBackground(textHandle)
    color = textHandle.BackgroundColor;
    if ischar(color) || isstring(color)
        tf = strcmp(char(color), 'w');
    else
        tf = isnumeric(color) && isequal(size(color), [1 3]) && ...
            all(abs(color - [1 1 1]) < 1e-12);
    end
end
