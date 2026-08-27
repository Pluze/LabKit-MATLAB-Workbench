classdef EisWorkflowSpec < matlab.unittest.TestCase
    %EISWORKFLOWSPEC Specify EIS file loading, plot materialization, and export.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsPlotsExportsAndRestoresAnEisFile(testCase)
            source = testfixtures.dta.file("eis_potentiostatic_zcurve.DTA");
            unsupported = testfixtures.dta.file( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            output = fullfile(folder, "eis.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(output), ...
                "alert", @(~, ~) []);
            definition = eis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("files", [source, unsupported], 1:2);
            axesValue = findall(figureValue, "Tag", "plot.main");
            units = eis.impedanceDisplay.catalog();
            [fitted, inspected] = inspectViewport(axesValue);
            runtime.applyControlValue("showMarkers", false);
            verifyViewport(testCase, axesValue, inspected);
            runtime.invokeAction("fitAxes");
            verifyViewport(testCase, axesValue, fitted);
            runtime.invokeAction("equalAxes");
            testCase.verifyEqual(axesValue.DataAspectRatio(1), ...
                axesValue.DataAspectRatio(2), AbsTol=1e-12);
            runtime.applyControlValue("impedanceUnit", units.choices(4));
            expected = fitted ./ 1000;
            verifyViewport(testCase, axesValue, expected);
            runtime.invokeAction("exportPlot");

            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyNumElements(runtime.State.project.inputs.sources, 1);
            testCase.verifyNotEmpty(axesValue.Children);
            testCase.verifySubstring(string(axesValue.XLabel.String), ...
                units.choices(4));
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
tolerance = max(1, max(abs(expected))) * 1e-9;
testCase.verifyEqual(actual, expected, AbsTol=tolerance);
end
