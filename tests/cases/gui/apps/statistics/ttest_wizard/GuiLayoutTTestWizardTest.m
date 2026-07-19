classdef GuiLayoutTTestWizardTest < matlab.unittest.TestCase
    %GUILAYOUTTTESTWIZARDTEST Verify multi-group selection, tests, plot, export.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function compares_three_groups_with_first_then_plots_and_exports(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanupFigures = onCleanup(@() h.closeAllFigures());
            folder = string(tempname);
            mkdir(folder);
            cleanupFolder = onCleanup(@() rmdir(folder, 's'));
            sourcePath = fullfile(folder, "synthetic_groups.csv");
            writecell({ ...
                'Reference', 'Treatment 1', 'Treatment 2'; ...
                1.2, 1.8, 1.1; ...
                1.4, 1.7, 1.2; ...
                1.3, 2.0, 1.4; ...
                1.5, 1.9, 1.3; ...
                '', 1.6, ''}, sourcePath);

            fig = h.launchFigure( ...
                'labkit_TTestWizard_app', 'T-Test Wizard');
            driver = labkitWorkflowDriver(fig);
            h.assertStandardWorkbenchLayout(fig);
            h.assertTabTitles(fig, { ...
                '1 Data', '2 Test & Plot', '3 Export', 'Log', ...
                'Data', 'Plot'});
            driver.chooseFiles('sourceFile', sourcePath);
            driver.click('Open table');

            ui = driver.registry();
            testCase.verifyEqual(numel(ui.rightGrid.RowHeight), 1);
            testCase.verifyEqual(numel(ui.rightGrid.ColumnWidth), 1);
            testCase.verifyEqual(ui.rightGrid.RowHeight, {'1x'});
            testCase.verifyEqual( ...
                ui.workspace.tabGroup.SelectedTab, ...
                ui.workspace.pages.dataPage.tab);
            testCase.verifyEqual( ...
                ui.workspace.pages.dataPage.grid.RowHeight, {'1x', '1x'});
            sourceTable = ui.controls.sourceGrid.table;
            testCase.verifyEmpty(sourceTable.CellSelectionCallback);
            testCase.verifyNotEmpty(sourceTable.SelectionChangedFcn);
            testCase.verifyEqual(string(sourceTable.ColumnName), ...
                ["A"; "B"; "C"]);

            selectCells(sourceTable, [2 1; 3 1; 4 1; 5 1]);
            h.waitForUiIdle(fig);
            driver.click('Add selected source cells');
            selectCells(sourceTable, [2 2; 3 2; 4 2; 5 2; 6 2]);
            h.waitForUiIdle(fig);
            driver.click('Add selected source cells');
            selectCells(sourceTable, [2 3; 3 3; 4 3; 5 3]);
            h.waitForUiIdle(fig);
            driver.click('Add selected source cells');

            runtime = getappdata(fig, 'labkitUiAppRuntime');
            groups = runtime.state.project.inputs.groups;
            testCase.verifyEqual(numel(groups), 3);
            testCase.verifyEqual(groups(1).values, ...
                [1.2; 1.4; 1.3; 1.5], 'AbsTol', 1e-12);
            testCase.verifyEqual(groups(2).values, ...
                [1.8; 1.7; 2.0; 1.9; 1.6], 'AbsTol', 1e-12);
            testCase.verifyEqual( ...
                string(ui.controls.captureTarget.valueHandle.Value), ...
                "(new group)", ...
                'Repeated captures should default to creating another group.');
            testCase.verifyTrue(all(ismember( ...
                ["Reference", "Treatment 1", "Treatment 2"], ...
                string(ui.controls.captureTarget.valueHandle.Items))));
            testCase.verifyTrue(driver.enabled('runComparisons'));
            analysisData = driver.tableData('dataTable');
            testCase.verifyEqual(analysisData(1:4, 1), ...
                repmat({'Reference'}, 4, 1));

            dataTable = ui.controls.dataTable.table;
            selectCells(dataTable, [1 1; 2 1]);
            h.waitForUiIdle(fig);
            testCase.verifyTrue(driver.enabled('deleteSelectedRows'));
            driver.click('Delete selected rows');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(arrayfun( ...
                @(group) numel(group.values), ...
                runtime.state.project.inputs.groups), [2; 5; 4]);

            selectCells(sourceTable, [2 1; 3 1]);
            h.waitForUiIdle(fig);
            setControlValue(ui.controls.captureTarget, 'Reference');
            h.waitForUiIdle(fig);
            driver.click('Add selected source cells');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(arrayfun( ...
                @(group) numel(group.values), ...
                runtime.state.project.inputs.groups), [4; 5; 4]);

            selectCells(dataTable, [1 1; 2 1]);
            h.waitForUiIdle(fig);
            setControlValue(ui.controls.batchGroupTarget, 'Treatment 1');
            h.waitForUiIdle(fig);
            driver.click('Change selected rows');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(arrayfun( ...
                @(group) numel(group.values), ...
                runtime.state.project.inputs.groups), [2; 7; 4]);

            selectCells(dataTable, [8 1; 9 1]);
            h.waitForUiIdle(fig);
            setControlValue(ui.controls.batchGroupTarget, 'Reference');
            h.waitForUiIdle(fig);
            driver.click('Change selected rows');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(arrayfun( ...
                @(group) numel(group.values), ...
                runtime.state.project.inputs.groups), [4; 5; 4]);

            driver.click('Run / refresh comparisons');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            completed = runtime.state.project.results.current;
            testCase.verifySize(completed, [2 1]);
            testCase.verifyTrue(all([completed.ok]));
            testCase.verifyEqual(completed(1).pValue, ...
                0.00222460334889963, 'RelTol', 1e-11);
            testCase.verifySize(driver.tableData('resultTable'), [2 5]);

            ui.workspace.tabGroup.SelectedTab = ...
                ui.workspace.pages.plotPage.tab;
            drawnow;
            testCase.verifyEqual( ...
                ui.workspace.tabGroup.SelectedTab, ...
                ui.workspace.pages.plotPage.tab);
            axesHandle = ui.controls.resultPlot.primaryAxes;
            testCase.verifyGreaterThan(numel(axesHandle.Children), 0);
            testCase.verifyEqual(string(axesHandle.Box), "on");
            testCase.verifyEqual(string(axesHandle.YGrid), "off");
            testCase.verifyEqual(axesHandle.YLim(1), 0);
            testCase.verifyGreaterThanOrEqual(numel(axesHandle.YTick), 3);
            testCase.verifyEqual(axesHandle.FontSize, 14);
            testCase.verifyEqual(string(axesHandle.XTickLabel), ...
                ["Reference"; "Treatment 1"; "Treatment 2"]);
            testCase.verifyTrue(contains( ...
                string(ui.controls.plotFreshness.valueHandle.Value), ...
                "Current"));

            choices = ttest_wizard.userInterface.plotChoices();
            setControlValue(ui.controls.plotType, choices.types(2));
            h.waitForUiIdle(fig);
            testCase.verifyTrue(any(contains( ...
                string(arrayfun(@class, axesHandle.Children, ...
                'UniformOutput', false)), "BoxChart")));

            testChoices = ttest_wizard.testRun.choices();
            setControlValue(ui.controls.testMethod, ...
                testChoices.methodLabels(2));
            h.waitForUiIdle(fig);
            resultStatus = string(driver.textAreaValue('resultStatus'));
            testCase.verifyTrue(any(contains( ...
                resultStatus, "Data or test settings changed")));
            testCase.verifyFalse(any(~cellfun(@isempty, regexp( ...
                cellstr(resultStatus), '^\d+Data', 'once'))));
            setControlValue(ui.controls.testMethod, ...
                testChoices.methodLabels(1));
            h.waitForUiIdle(fig);

            editedData = dataTable.Data;
            editedData{1, 2} = 1.25;
            dataTable.Data = editedData;
            editCallback = dataTable.CellEditCallback;
            editCallback(dataTable, struct( ...
                'Indices', [1 2], 'PreviousData', 1.2, ...
                'NewData', 1.25, 'EditData', 1.25));
            h.waitForUiIdle(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual( ...
                runtime.state.project.results.current(1).pValue, ...
                completed(1).pValue, 'AbsTol', 0, ...
                'Manual data edits must not mutate completed results.');
            testCase.verifyTrue(any(contains( ...
                string(ui.controls.plotFreshness.valueHandle.Value), ...
                "OUT OF DATE")));

            outputNames = ["ttest_group_data.csv", "ttest_results.csv"];
            outputIndex = 0;
            runtime.request.outputChooser = @chooseOutput;
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            driver.click('Export group data CSV');
            driver.click('Export comparison results CSV');
            savedData = readcell(fullfile(folder, outputNames(1)));
            savedResult = readcell(fullfile(folder, outputNames(2)));
            testCase.verifySize(savedData, [6 4]);
            testCase.verifyEqual(savedResult{1, 4}, 'Reference Group');
            testCase.verifyEqual(savedResult{3, 21}, 'ok');

            clear cleanupFolder cleanupFigures;

            function [filename, folderPath] = chooseOutput(~, ~, ~)
                outputIndex = outputIndex + 1;
                filename = char(outputNames(outputIndex));
                folderPath = char(folder);
            end
        end
    end
end

function selectCells(tableHandle, indices)
    if isprop(tableHandle, 'SelectionChangedFcn') && ...
            ~isempty(tableHandle.SelectionChangedFcn)
        callback = tableHandle.SelectionChangedFcn;
        callback(tableHandle, struct( ...
            'Selection', indices, 'SelectionType', 'cell'));
    else
        callback = tableHandle.CellSelectionCallback;
        callback(tableHandle, struct('Indices', indices));
    end
end

function setControlValue(control, value)
    handle = control.valueHandle;
    previous = handle.Value;
    handle.Value = char(string(value));
    handle.ValueChangedFcn(handle, struct( ...
        'Value', handle.Value, 'PreviousValue', previous));
end
