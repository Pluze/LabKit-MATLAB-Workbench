classdef VtResistanceWorkflowSpec < matlab.unittest.TestCase
    %VTRESISTANCEWORKFLOWSPEC Specify the bounded transient analysis workflow.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsRecomputesExportsAndRestoresAChronoFile(testCase)
            source = testfixtures.dta.file( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");
            unsupported = testfixtures.dta.file( ...
                "eis_potentiostatic_zcurve.DTA");
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            output = fullfile(folder, "resistance.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(output), ...
                "alert", @(~, ~) []);
            definition = vt_resistance.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            testCase.verifyEqual(string( ...
                findall(figureValue, "Tag", "files").Multiselect), "on");
            runtime.applyFileSelection("files", [source, unsupported], 1:2);
            results = findall(figureValue, "Tag", "results");
            top = findall(figureValue, "Tag", "plotAxes.top");
            [fitted, inspected] = inspectViewport(top);
            runtime.applyControlValue("topGrid", false);
            verifyViewport(testCase, top, inspected);
            runtime.applyControlValue("steadyWindow", ...
                vt_resistance.analysisRun.analysisChoices().steadyWindows(2));
            verifyViewport(testCase, top, fitted);
            runtime.invokeAction("exportResults");

            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyNumElements(runtime.State.project.inputs.sources, 1);
            testCase.verifyEqual(size(results.Data), [1 9]);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "plotAxes.top").Children);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "plotAxes.bottom").Children);
            testCase.verifyTrue(isfile(output));
            clear cleanup
        end
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
