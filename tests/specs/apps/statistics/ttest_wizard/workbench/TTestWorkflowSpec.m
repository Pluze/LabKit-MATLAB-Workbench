classdef TTestWorkflowSpec < matlab.unittest.TestCase
    %TTESTWORKFLOWSPEC Specify the table-to-comparison-export journey.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function importsGroupsComparesPlotsAndExports(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "observations.xlsx");
            dataPath = fullfile(folder, "groups.csv");
            resultPath = fullfile(folder, "comparisons.csv");
            observations = {'Reference', 'Treatment'; 1.2, 1.8; 1.4, 1.7; ...
                1.3, 2.0; 1.5, 1.9; NaN, 1.6};
            writecell(observations, sourcePath, Sheet="Primary");
            writecell(observations, sourcePath, Sheet="Alternate");
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, dataPath, resultPath), ...
                "alert", @(message, title) unexpectedAlert(message, title));
            definition = ttest_wizard.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyFileSelection("sourceFile", string(sourcePath), 1);
            testCase.verifyFalse(runtime.StartupFailed);
            testCase.verifyTrue(runtime.State.session.cache.source.ok);
            testCase.verifySize(runtime.State.session.cache.source.cells, [6 2]);
            runtime.applyControlValue("sourceSheet", "Alternate");
            testCase.verifyEqual(runtime.State.project.inputs.sourceSheet, "Alternate");

            runtime.applyTableSelection("sourceGrid", [2 1; 3 1; 4 1; 5 1]);
            runtime.invokeAction("captureGroup");
            runtime.applyTableSelection("sourceGrid", [2 2; 3 2; 4 2; 5 2; 6 2]);
            runtime.invokeAction("captureGroup");
            testCase.verifyNumElements(runtime.State.project.inputs.groups, 2);
            testCase.verifyEqual( ...
                string({runtime.State.project.inputs.groups.label}), ...
                ["Reference", "Treatment"]);
            dataTable = findall(runtime.figureHandle(), "Tag", "dataTable");
            tableData = dataTable.Data;
            previousValue = tableData{1, 2};
            tableData{1, 2} = 1.25;
            runtime.applyTableEdit("dataTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=2, ...
                    PreviousValue=previousValue, NewValue=1.25, ...
                    Data=tableData));
            testCase.verifyEqual( ...
                runtime.State.project.inputs.groups(1).values(1), 1.25);

            runtime.applyControlValue("testMethod", "Independent t-test - Welch");
            runtime.applyControlValue("alternative", "Different (two-sided)");
            runtime.applyControlValue("alpha", 0.05);
            runtime.invokeAction("runComparisons");
            testCase.verifyNumElements(runtime.State.project.results.current, 1);
            result = runtime.State.project.results.current(1);
            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(result.meanDifference, -0.4375, AbsTol=1e-14);

            runtime.applyControlValue("plotType", "Box plot");
            runtime.applyControlValue("showPoints", true);
            runtime.applyControlValue("showSummary", true);
            runtime.applyControlValue("showPValue", true);
            runtime.applyControlValue("plotTitle", "Reference comparison");
            runtime.applyControlValue("yLabel", "Response");
            runtime.invokeAction("resetPlotView");
            plotAxes = findall(runtime.figureHandle(), "Tag", "resultPlot.main");
            testCase.verifyNotEmpty(plotAxes.Children);

            runtime.invokeAction("exportData");
            runtime.invokeAction("exportResult");
            testCase.verifyTrue(isfile(dataPath));
            testCase.verifyTrue(isfile(resultPath));
            exported = readtable(resultPath, TextType="string");
            testCase.verifyEqual(height(exported), 1);
            testCase.verifyNotEmpty(runtime.State.project.results.lastResultExport);

            runtime.applyTableSelection("dataTable", [1 1]);
            runtime.applyControlValue("batchGroupTarget", "Treatment");
            runtime.invokeAction("assignRowsToGroup");
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.groups(1).values), 3);
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.groups(2).values), 6);
            runtime.applyTableSelection("dataTable", [1 1]);
            runtime.invokeAction("deleteSelectedRows");
            testCase.verifyEqual(sum(arrayfun(@(group) numel(group.values), ...
                runtime.State.project.inputs.groups)), 8);
            runtime.invokeAction("clearGroups");
            testCase.verifyEmpty(runtime.State.project.inputs.groups);
            testCase.verifyEqual( ...
                runtime.State.session.selection.batchGroupTarget, ...
                "(select group)");
            clear cleanup
        end
    end
end

function choice = chooseOutput(defaultPath, dataPath, resultPath)
if contains(string(defaultPath), "group_data")
    choice = labkit.app.dialog.Choice(dataPath);
else
    choice = labkit.app.dialog.Choice(resultPath);
end
end

function unexpectedAlert(message, title)
error("ttest_wizard:test:UnexpectedAlert", "%s: %s", title, message);
end
