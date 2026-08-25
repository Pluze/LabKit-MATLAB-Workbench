classdef ChronoOverlayWorkflowSpec < matlab.unittest.TestCase
    %CHRONOOVERLAYWORKFLOWSPEC Specify loading, plot materialization, and export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsAlignsExportsAndRestoresAChronoTrace(testCase)
            source = testfixtures.dta.file( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");
            unsupported = testfixtures.dta.file( ...
                "eis_potentiostatic_zcurve.DTA");
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            output = fullfile(folder, "overlay.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, ~) labkit.app.dialog.Choice(output), ...
                "alert", @(~, ~) []);
            definition = chrono_overlay.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("files", [source, unsupported], 1:2);
            voltage = findall(figureValue, "Tag", "overlayPlots.voltage");
            current = findall(figureValue, "Tag", "overlayPlots.current");
            testCase.verifyNumElements(runtime.State.session.cache.items, 1);
            testCase.verifyNumElements(runtime.State.project.inputs.sources, 1);
            testCase.verifyNotEmpty(voltage.Children);
            testCase.verifyNotEmpty(current.Children);
            [fitted, inspected] = inspectViewport(voltage);
            runtime.applyControlValue("showGrid", false);
            verifyViewport(testCase, voltage, inspected);
            runtime.applyControlValue("xAxis", "Time (ms)");
            expected = fitted;
            expected(1:2) = 1000 .* expected(1:2);
            verifyViewport(testCase, voltage, expected);
            runtime.invokeAction("exportCurves");
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
