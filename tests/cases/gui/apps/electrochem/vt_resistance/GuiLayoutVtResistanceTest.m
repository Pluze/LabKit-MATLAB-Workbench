classdef GuiLayoutVtResistanceTest < matlab.unittest.TestCase
    % Verify VT Resistance through the explicit App SDK runtime.
    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutUsesSemanticTargets(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            cleanup = onCleanup(@() helpers.closeAllFigures());
            figure = labkit_VTResistance_app();

            testCase.verifyEqual(numel(findall(figure, "Tag", "files")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "exportResults")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "plotAxes.top")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "plotAxes.bottom")), 1);
            clear cleanup
        end

        function filesDriveAnalysisExportAndRestore(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            outputFolder = string(tempname);
            mkdir(outputFolder);
            folderCleanup = onCleanup(@() rmdir(outputFolder, "s"));
            csvPath = fullfile(outputFolder, ...
                "vt_steady_resistance_results.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(csvPath), ...
                "alert", @(~, ~) []);
            app = vt_resistance.definition();
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                app, [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();
            fixtures = [ ...
                string(dtaFixturePath( ...
                    "chrono_chronopot_current_pulse_0p2ms.DTA")); ...
                string(dtaFixturePath( ...
                    "chrono_chronopot_current_pulse_1ms.DTA"))];

            runtime.applyFileSelection("files", fixtures, 2);

            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 2);
            testCase.verifyEqual(numel( ...
                runtime.State.session.cache.items), 2);
            tableHandle = findall(figure, "Tag", "results");
            testCase.verifyEqual(size(tableHandle.Data), [2 9]);
            top = findall(figure, "Tag", "plotAxes.top");
            bottom = findall(figure, "Tag", "plotAxes.bottom");
            testCase.verifyNotEmpty(top.Children);
            testCase.verifyNotEmpty(bottom.Children);

            runtime.applyFilePanelSelection("files", 2);
            testCase.verifyEqual( ...
                runtime.State.session.selection.files.Indices, 2);
            choices = vt_resistance.analysisRun.analysisChoices();
            runtime.applyControlValue( ...
                "voltageMode", choices.voltageModes(2));
            analyses = [runtime.State.session.cache.items.analysis];
            testCase.verifyTrue(all(string({analyses.voltageMode}) == ...
                choices.voltageModes(2)));

            runtime.invokeAction("exportResults");
            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile(fullfile(outputFolder, ...
                "vt_steady_resistance_results.labkit.json")));

            projectPath = fullfile(outputFolder, "vt-project.mat");
            runtime.saveProject(runtime.State, projectPath);
            runtime.applyFileSelection("files", strings(1, 0), ...
                zeros(1, 0));
            testCase.verifyEmpty(runtime.State.session.cache.items);
            runtime.restoreProject(projectPath);
            testCase.verifyEqual(numel( ...
                runtime.State.session.cache.items), 2);
            clear runtimeCleanup folderCleanup
        end

        function plotRedrawRemovesHiddenAnnotations(testCase)
            figure = uifigure("Visible", "off");
            cleanup = onCleanup(@() delete(figure));
            axesHandle = uiaxes(figure);
            plot(axesHandle, 1:3, [1 4 2], "HandleVisibility", "off");
            hold(axesHandle, "on");
            xline(axesHandle, 2, ":", "marker");
            text(axesHandle, 2, 3, "annotation", ...
                "HandleVisibility", "off");
            labkit.app.plot.clearAxes(axesHandle, "ResetScale", true);
            testCase.verifyEmpty(axesHandle.Children);
            testCase.verifyEqual(axesHandle.XLimMode, 'auto');
            testCase.verifyEqual(axesHandle.YLimMode, 'auto');
            clear cleanup
        end
    end
end
