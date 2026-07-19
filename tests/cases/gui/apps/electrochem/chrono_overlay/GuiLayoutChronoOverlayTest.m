classdef GuiLayoutChronoOverlayTest < matlab.unittest.TestCase
    % Verify Chrono Overlay through the explicit UI runtime and native adapter.
    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutUsesSemanticTargets(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            cleanup = onCleanup(@() helpers.closeAllFigures());
            figure = labkit_ChronoOverlay_app();

            testCase.verifyEqual(numel(findall(figure, "Tag", "files")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "exportCurves")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "overlayPlots.voltage")), 1);
            testCase.verifyEqual(numel(findall(figure, ...
                "Tag", "overlayPlots.current")), 1);
            clear cleanup
        end

        function standardFilesDrivePlotExportAndRestore(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            outputFolder = string(tempname);
            mkdir(outputFolder);
            folderCleanup = onCleanup(@() rmdir(outputFolder, "s"));
            csvPath = fullfile(outputFolder, "overlay.csv");
            backend = struct( ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.ui.DialogResult(csvPath), ...
                "alert", @(~, ~) []);
            app = chrono_overlay.definition();
            runtime = app.createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();
            fixtures = [ ...
                string(dtaFixturePath( ...
                    "chrono_chronopot_current_pulse_0p2ms.DTA")); ...
                string(dtaFixturePath( ...
                    "chrono_chronoamp_voltage_pulse_0p2ms.DTA"))];

            runtime.applyFileSelection("files", fixtures, 1:2);

            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 2);
            testCase.verifyEqual(numel( ...
                runtime.State.session.cache.items), 2);
            voltage = findall(figure, "Tag", "overlayPlots.voltage");
            current = findall(figure, "Tag", "overlayPlots.current");
            testCase.verifyNotEmpty(voltage.Children);
            testCase.verifyNotEmpty(current.Children);

            runtime.applyFilePanelSelection("files", 1);
            testCase.verifyEqual( ...
                runtime.State.session.selection.files.Indices, 1);
            runtime.invokeAction("exportCurves");
            testCase.verifyTrue(isfile(csvPath));
            testCase.verifyTrue(isfile( ...
                fullfile(outputFolder, "labkit_result.json")));

            projectPath = fullfile(outputFolder, "overlay-project.mat");
            runtime.saveProject(runtime.State, projectPath);
            runtime.applyFileSelection("files", strings(1, 0), ...
                zeros(1, 0));
            testCase.verifyEmpty(runtime.State.session.cache.items);
            runtime.restoreProject(projectPath);
            testCase.verifyEqual(numel( ...
                runtime.State.session.cache.items), 2);

            voltage.XLim = [-1 0];
            voltage.YLim = [-0.01 0.01];
            runtime.applyBinding("xAxis", "Time (ms)");
            testCase.verifyEqual(voltage.XLim, [-1 0]);
            testCase.verifyEqual(voltage.YLim, [-0.01 0.01]);
            testCase.verifyTrue(contains( ...
                string(voltage.XLabel.String), "Time (ms)"));
            clear runtimeCleanup folderCleanup
        end
    end
end
