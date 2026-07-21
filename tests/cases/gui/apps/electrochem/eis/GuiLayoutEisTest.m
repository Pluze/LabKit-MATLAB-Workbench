classdef GuiLayoutEisTest < matlab.unittest.TestCase
    %GUILAYOUTEISTEST Verify EIS GUI layout and workflow contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function eis_file_button_loads_selected_dta(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = string(dtaFixturePath( ...
                'eis_potentiostatic_zcurve.DTA'));
            secondFolder = string(tempname);
            mkdir(secondFolder);
            secondCleanup = onCleanup(@() rmdir(secondFolder, 's'));
            secondFixture = fullfile( ...
                secondFolder, 'eis_replicate_zcurve.DTA');
            copyfile(fixture, secondFixture);
            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() rmdir(outputFolder, 's'));
            exportPath = fullfile( ...
                outputFolder, 'gamry_eis_plot_export.csv');
            backend = struct( ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(exportPath), ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                eis.definition(), [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertEisLayout(h, fig);

            axisItems = eis.overlayPlot.axisItems();
            runtime.applyControlValue("xAxis", axisItems(1));
            runtime.applyControlValue("logX", true);
            runtime.applyFileSelection("files", fixture, 1);

            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 1);
            testCase.verifyFalse(isfield( ...
                runtime.State.project.inputs, 'items'), ...
                'EIS durable project must not own decoded DTA items.');
            testCase.verifyEqual(numel(runtime.State.session.cache.items), 1);
            summary = string(findall(fig, "Tag", "summary").Value);
            testCase.verifyTrue(any(summary ~= "No files loaded."));
            ax = findall(fig, "Tag", "plot.main");
            testCase.verifyNotEmpty(ax.Children);
            firstSourceId = string( ...
                runtime.State.project.inputs.sources(1).id);

            paths = [fixture, secondFixture];
            runtime.applyFileSelection("files", paths, 2);
            runtime.applyFilePanelSelection("files", 1);
            sourceIds = string( ...
                {runtime.State.project.inputs.sources.id});
            testCase.verifyEqual(sourceIds(1), firstSourceId);
            testCase.verifyEqual(numel(unique(sourceIds)), numel(sourceIds));
            testCase.verifyEqual( ...
                runtime.State.session.selection.files.Indices, 1);

            ax.XLim = [1e4 5e4];
            ax.YLim = [4e4 13e4];
            testCase.verifyWarningFree(@() runtime.applyControlValue( ...
                "xAxis", axisItems(2)));
            testCase.verifyWarningFree(@() runtime.applyControlValue( ...
                "logY", true));
            testCase.verifyNotEmpty(fig.WindowScrollWheelFcn, ...
                'Log-scale redraw must retain framework wheel navigation.');
            testCase.verifyEqual(ax.XLim, [1e4 5e4], ...
                'Managed EIS redraw should preserve the X viewport.');
            testCase.verifyEqual(ax.YLim, [4e4 13e4], ...
                'Managed EIS redraw should preserve the Y viewport.');

            runtime.applyControlValue("xAxis", axisItems(5));
            runtime.applyControlValue("yAxis", axisItems(7));
            runtime.applyControlValue("logX", false);
            runtime.applyControlValue("logY", false);
            runtime.invokeAction("fitAxes");
            testCase.verifyEqual(string(ax.DataAspectRatioMode), "auto", ...
                'Fitting X/Y limits must not retain an equal aspect ratio.');
            testCase.verifyNotEqual(ax.XLim, [1e4 5e4], ...
                'The explicit fit action must replace the saved X viewport.');
            testCase.verifyNotEqual(ax.YLim, [4e4 13e4], ...
                'The explicit fit action must replace the saved Y viewport.');
            runtime.invokeAction("equalAxes");
            drawnow
            plotPixels = getpixelposition(ax, true);
            testCase.verifyEqual(diff(ax.XLim) / plotPixels(3), ...
                diff(ax.YLim) / plotPixels(4), "AbsTol", 1e-8, ...
                'Equal X/Y scale must use equal data units.');

            runtime.invokeAction("exportPlot");
            testCase.verifyTrue(isfile(exportPath));
            manifestPath = string( ...
                runtime.State.project.results.lastExport.manifestPath);
            testCase.verifyTrue(isfile(manifestPath));
            manifest = jsondecode(fileread(manifestPath));
            testCase.verifyEqual(string(manifest.format), "labkit.result");

            projectPath = fullfile(outputFolder, 'eis-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield( ...
                saved.labkitProject.payload.inputs, 'items'));
            runtime.applyFileSelection( ...
                "files", strings(1, 0), zeros(1, 0));
            runtime.restoreProject(projectPath);
            testCase.verifyEqual(numel(runtime.State.session.cache.items), 2);
            testCase.verifyEqual(string( ...
                runtime.State.project.inputs.sources(1).id), firstSourceId);
            clear runtimeCleanup outputCleanup secondCleanup cleanup;
        end
    end
end

function assertEisLayout(h, fig)
h.assertStartupSucceeded(fig);
ids = ["files", "exportPlot", "xAxis", "yAxis", "lineWidth", ...
    "markerSize", "showMarkers", "logX", "logY", "showLegend", ...
    "showGrid", "fitAxes", "equalAxes", "summary", "plot.main"];
for id = ids
    assert(numel(findall(fig, "Tag", id)) == 1, ...
        "Missing EIS semantic target: %s.", id);
end
end
