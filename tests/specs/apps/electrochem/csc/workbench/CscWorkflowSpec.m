classdef CscWorkflowSpec < matlab.unittest.TestCase
    %CSCWORKFLOWSPEC Specify selected-cycle comparison and plot materialization.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsACvCtFileAndUpdatesComparisonPlots(testCase)
            source = testfixtures.dta.file( ...
                "cv_cyclic_voltammetry_pt_reference.DTA");
            unsupported = testfixtures.dta.file( ...
                "eis_potentiostatic_zcurve.DTA");
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            resultPath = fullfile(folder, "all-cycles.csv");
            cvPath = fullfile(folder, "cv-data.csv");
            definition = csc.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], struct( ...
                "chooseOutputFile", @(~, defaultPath) labkit.app.dialog.Choice( ...
                    outputPath(defaultPath, resultPath, cvPath)), ...
                "alert", @(message, title) verifyAlert(message, title)), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            testCase.verifyEqual(string( ...
                findall(figureValue, "Tag", "files").Multiselect), "on");
            runtime.applyFileSelection("files", [source, unsupported], 1:2);
            tableValue = findall(figureValue, "Tag", "cycleResults");
            top = findall(figureValue, "Tag", "plotAxes.top");
            bottom = findall(figureValue, "Tag", "plotAxes.bottom");
            [~, inspected] = inspectViewport(top);
            runtime.applyControlValue("topGrid", false);
            verifyViewport(testCase, top, inspected);
            topX = findall(figureValue, "Tag", "topX");
            alternatives = string(topX.Items);
            alternatives = alternatives(alternatives ~= string(topX.Value));
            testCase.assertNotEmpty(alternatives);
            runtime.applyControlValue("topX", alternatives(1));
            testCase.verifyNotEqual([top.XLim, top.YLim], inspected, ...
                "Changing the plotted coordinate must accept fitted limits.");
            runtime.applyControlValue("mode", ...
                csc.analysisRun.analysisChoices().modes(2));
            runtime.invokeAction("reloadSelected");
            runtime.invokeAction("exportResults");
            runtime.invokeAction("exportVoltageCurrent");

            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyNumElements(runtime.State.project.inputs.sources, 1);
            testCase.verifyGreaterThan(size(tableValue.Data, 1), 0);
            testCase.verifyNotEmpty(top.Children);
            testCase.verifyNotEmpty(bottom.Children);
            testCase.verifyEqual(runtime.State.project.parameters.mode, ...
                csc.analysisRun.analysisChoices().modes(2));
            testCase.verifyNotEmpty(string(findall(figureValue, "Tag", "qct").Value));
            testCase.verifyTrue(isfile(resultPath));
            testCase.verifyEqual( ...
                runtime.State.project.results.lastResultsExport.outputPath, ...
                string(resultPath));
            voltageCurrentPath = runtime.State.project.results. ...
                lastVoltageCurrentExport.outputPath;
            testCase.verifyTrue(isfile(voltageCurrentPath));
            testCase.verifyTrue(startsWith(voltageCurrentPath, ...
                string(erase(cvPath, ".csv")) + "_"));
            clear cleanup
        end
    end
end

function path = outputPath(defaultPath, resultPath, cvPath)
if contains(string(defaultPath), "cv_data")
    path = cvPath;
else
    path = resultPath;
end
end

function verifyAlert(message, title)
if string(title) ~= "Unsupported files filtered"
    error("csc:test:UnexpectedAlert", "%s: %s", title, message);
end
end

function [fitted, inspected] = inspectViewport(ax)
fitted = [ax.XLim, ax.YLim];
inspected = [innerLimits(fitted(1:2)), innerLimits(fitted(3:4))];
ax.XLim = inspected(1:2);
ax.YLim = inspected(3:4);
end

function limits = innerLimits(limits)
limits = limits + [0.2, -0.2] .* diff(limits);
end

function verifyViewport(testCase, ax, expected)
actual = [ax.XLim, ax.YLim];
tolerance = max(1, max(abs(expected))) * 1e-10;
testCase.verifyEqual(actual, expected, AbsTol=tolerance);
end
