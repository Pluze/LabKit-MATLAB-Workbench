classdef GuiLayoutTTestWizardTest < matlab.unittest.TestCase
    % Verify typed table callbacks, comparisons, plot, and export end to end.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function comparesThreeGroupsWithFirstThenPlotsAndExports(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() rmdir(folder, "s"));
            sourcePath = fullfile(folder, "synthetic_groups.csv");
            writecell({ ...
                'Reference', 'Treatment 1', 'Treatment 2'; ...
                1.2, 1.8, 1.1; ...
                1.4, 1.7, 1.2; ...
                1.3, 2.0, 1.4; ...
                1.5, 1.9, 1.3; ...
                '', 1.6, ''}, sourcePath);
            outputNames = ["ttest_group_data.csv", "ttest_results.csv"];
            outputIndex = 0;
            backend = struct( ...
                "chooseOutputFile", @chooseOutput, ...
                "alert", @(~, ~) []);
            runtime = ttest_wizard.definition().createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();
            drawnow;

            testCase.verifyEqual(numel(component(figure, "sourceFile")), 1);
            testCase.verifyEqual(numel(component(figure, "sourceGrid")), 1);
            testCase.verifyEqual(numel(component(figure, "dataTable")), 1);
            testCase.verifyEqual(numel(component(figure, "resultPlot.main")), 1);
            for title = [ ...
                    "Data and Plot", ...
                    "Opened table — select numeric cells here", ...
                    "Analysis data — type or paste Group and Value", ...
                    "Statistical comparison plot", ...
                    "What will run", ...
                    "Result family", ...
                    "Each group versus reference", ...
                    "Fast workflow"]
                testCase.verifyEqual(numel(findall( ...
                    figure, "Title", title)), 1, ...
                    "Missing T-Test Wizard title: " + title);
            end
            for label = [ ...
                    "Table", "Selected cells", "Plot status", ...
                    "Last data export", "Last result export"]
                testCase.verifyEqual(numel(findall( ...
                    figure, "Text", label)), 1, ...
                    "Missing T-Test Wizard label: " + label);
            end
            testCase.verifyEmpty(findall(figure, "Title", "Data tables"));
            controlPanel = findall(figure, "Title", "Controls");
            workspacePanel = findall(figure, "Title", "Data and Plot");
            testCase.verifyNumElements(controlPanel, 1);
            testCase.verifyNumElements(workspacePanel, 1);
            testCase.verifyLessThan( ...
                controlPanel.Layout.Column, ...
                workspacePanel.Layout.Column);
            buttonPosition = getpixelposition( ...
                component(figure, "captureGroup"), true);
            testCase.verifyGreaterThan(buttonPosition(4), 20);
            runtime.applyFileSelection("sourceFile", sourcePath, 1);

            sourceTable = component(figure, "sourceGrid");
            testCase.verifyEqual(string(sourceTable.ColumnName), ...
                ["A"; "B"; "C"]);
            selectCells(sourceTable, [2 1; 3 1; 4 1; 5 1]);
            click(figure, "captureGroup");
            selectCells(sourceTable, [2 2; 3 2; 4 2; 5 2; 6 2]);
            click(figure, "captureGroup");
            selectCells(sourceTable, [2 3; 3 3; 4 3; 5 3]);
            click(figure, "captureGroup");

            groups = runtime.State.project.inputs.groups;
            testCase.verifyEqual(numel(groups), 3);
            testCase.verifyEqual(groups(1).values, ...
                [1.2; 1.4; 1.3; 1.5], AbsTol=1e-12);
            testCase.verifyEqual(groups(2).values, ...
                [1.8; 1.7; 2.0; 1.9; 1.6], AbsTol=1e-12);
            testCase.verifyTrue(all(ismember( ...
                ["Reference", "Treatment 1", "Treatment 2"], ...
                string(component(figure, "captureTarget").Items))));
            testCase.verifyEqual(string( ...
                component(figure, "runComparisons").Enable), "on");

            analysisTable = component(figure, "dataTable");
            selectCells(analysisTable, [1 1; 2 1]);
            testCase.verifyEqual(string( ...
                component(figure, "deleteSelectedRows").Enable), "on");
            click(figure, "deleteSelectedRows");
            testCase.verifyEqual(arrayfun( ...
                @(group) numel(group.values), ...
                runtime.State.project.inputs.groups), [2; 5; 4]);

            selectCells(sourceTable, [2 1; 3 1]);
            changeValue(figure, "captureTarget", "Reference");
            click(figure, "captureGroup");
            testCase.verifyEqual(arrayfun( ...
                @(group) numel(group.values), ...
                runtime.State.project.inputs.groups), [4; 5; 4]);

            click(figure, "runComparisons");
            completed = runtime.State.project.results.current;
            testCase.verifySize(completed, [2 1]);
            testCase.verifyTrue(all([completed.ok]));
            testCase.verifyEqual(completed(1).pValue, ...
                0.00222460334889963, RelTol=1e-11);
            testCase.verifySize(component(figure, "resultTable").Data, [2 5]);

            axesHandle = component(figure, "resultPlot.main");
            testCase.verifyGreaterThan(numel(axesHandle.Children), 0);
            testCase.verifyEqual(string(axesHandle.Box), "on");
            testCase.verifyEqual(axesHandle.YLim(1), 0);
            testCase.verifyEqual(string(axesHandle.XTickLabel), ...
                ["Reference"; "Treatment 1"; "Treatment 2"]);
            testCase.verifyTrue(contains(string( ...
                component(figure, "plotFreshness").Value), "Current"));

            testChoices = ttest_wizard.testRun.choices();
            changeValue(figure, "testMethod", testChoices.methodLabels(2));
            testCase.verifyTrue(any(contains(string( ...
                component(figure, "resultStatus").Value), ...
                "Data or test settings changed")));
            changeValue(figure, "testMethod", testChoices.methodLabels(1));

            editedData = analysisTable.Data;
            editedData{1, 2} = 1.25;
            analysisTable.Data = editedData;
            analysisTable.CellEditCallback(analysisTable, struct( ...
                "Indices", [1 2], "PreviousData", 1.2, ...
                "NewData", 1.25));
            testCase.verifyEqual( ...
                runtime.State.project.results.current(1).pValue, ...
                completed(1).pValue, AbsTol=0);
            testCase.verifyTrue(contains(string( ...
                component(figure, "plotFreshness").Value), "OUT OF DATE"));

            click(figure, "exportData");
            click(figure, "exportResult");
            savedData = readcell(fullfile(folder, outputNames(1)));
            savedResult = readcell(fullfile(folder, outputNames(2)));
            testCase.verifySize(savedData, [6 4]);
            testCase.verifyEqual(savedResult{1, 4}, 'Reference Group');
            testCase.verifyEqual(savedResult{3, 21}, 'ok');
            clear runtimeCleanup folderCleanup

            function choice = chooseOutput(~, ~)
                outputIndex = outputIndex + 1;
                choice = labkit.app.dialog.Choice( ...
                    fullfile(folder, outputNames(outputIndex)));
            end
        end
    end
end

function handle = component(figure, id)
handle = findall(figure, "Tag", id);
assert(numel(handle) == 1, "Expected one component tagged %s.", id);
end

function click(figure, id)
button = component(figure, id);
button.ButtonPushedFcn(button, struct());
drawnow;
end

function changeValue(figure, id, value)
control = component(figure, id);
control.Value = string(value);
control.ValueChangedFcn(control, struct());
drawnow;
end

function selectCells(tableHandle, indices)
if isprop(tableHandle, "SelectionChangedFcn") && ...
        ~isempty(tableHandle.SelectionChangedFcn)
    tableHandle.SelectionChangedFcn(tableHandle, struct( ...
        "Selection", indices, "SelectionType", "cell"));
else
    tableHandle.CellSelectionCallback(tableHandle, ...
        struct("Indices", indices));
end
drawnow;
end
