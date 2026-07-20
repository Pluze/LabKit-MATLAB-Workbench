classdef GuiLayoutFlirThermalTest < matlab.unittest.TestCase
    %GUILAYOUTFLIRTHERMALTEST Verify FLIR thermal GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function flir_thermal_load_keeps_scale_axis_full_height(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            folder = string(tempname);
            mkdir(folder);
            cleanupFolder = onCleanup(@() removeTempFolder(folder));
            cleanupFigure = onCleanup(@() h.closeAllFigures());
            sourcePath = fullfile(folder, "synthetic_flir.jpg");
            secondSourcePath = fullfile(folder, "synthetic_flir_second.jpg");
            writeSyntheticFlirRjpegFixture(sourcePath);
            writeSyntheticFlirRjpegFixture(secondSourcePath, ...
                struct("raw", uint16(18000 + [50 60; 70 80])));

            outputFolder = fullfile(folder, "flir_thermal");
            backend = struct( ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(outputFolder), ...
                "alert", @(~, ~) []);
            runtime = flir_thermal.definition().createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertFlirLayout(h, fig);
            runtime.applyFileSelection( ...
                'thermalSources', [sourcePath secondSourcePath], 2);
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 2);
            testCase.verifyFalse(isfield( ...
                runtime.State.project.annotations.items, 'raw'));
            testCase.verifyFalse(isfield( ...
                runtime.State.project.annotations.items, 'temperatureC'), ...
                'Durable FLIR annotations must not persist decoded thermal matrices.');
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.currentItem.temperatureC, ...
                'The selected FLIR decode should remain an ephemeral session cache.');
            thermalAxes = findall(fig, 'Tag', 'thermalPreview.thermal');
            testCase.verifyNotEmpty(thermalAxes.Children);
            runtime.applyInteraction( ...
                'temperaturePoint', 'interactionChanged', [1 1]);
            runtime.applyInteraction( ...
                'temperatureRegion', 'interactionChanged', [1 1 1 1]);

            projectPath = fullfile(folder, 'flir-thermal-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'session'), ...
                'FLIR projects must exclude decoded caches and live interactions.');
            runtime.restoreProject(projectPath);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.currentItem.temperatureC, ...
                'Project reopen should lazily rebuild the selected FLIR cache.');

            runtime.invokeAction('exportImages');
            testCase.verifyNotEmpty( ...
                runtime.State.project.results.lastExport);
            testCase.verifyTrue(isfolder(outputFolder));
            clear runtimeCleanup
        end

        function flir_shared_range_limits_manual_adjustment_to_shared_bounds(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            folder = string(tempname);
            mkdir(folder);
            cleanupFolder = onCleanup(@() removeTempFolder(folder));
            cleanupFigure = onCleanup(@() h.closeAllFigures());
            coolPath = fullfile(folder, "synthetic_flir_cool.jpg");
            warmPath = fullfile(folder, "synthetic_flir_warm.jpg");
            writeSyntheticFlirRjpegFixture(coolPath, struct("raw", uint16(18000 + [0 10; 20 30])));
            writeSyntheticFlirRjpegFixture(warmPath, struct("raw", uint16(18000 + [400 420; 450 470])));

            runtime = flir_thermal.definition().createMatlabRuntime( ...
                [], struct("alert", @(~, ~) []));
            runtimeCleanup = onCleanup(@() runtime.close());
            runtime.applyFileSelection( ...
                'thermalSources', [coolPath warmPath], [1 2]);
            runtime.invokeAction('groupRange');

            items = runtime.State.project.annotations.items;
            testCase.verifyEqual(numel(items), 2);
            testCase.verifyEqual(items(1).displayRange, ...
                items(2).displayRange, AbsTol=0.05);
            testCase.verifyEqual(items(1).rangeControlBounds, ...
                items(1).displayRange, AbsTol=0.05);
            runtime.applyControlValue( ...
                'temperatureRange', items(1).displayRange);
            testCase.verifyEqual( ...
                runtime.State.session.cache.currentItem.displayRange, ...
                items(1).displayRange, AbsTol=0.05);
            clear runtimeCleanup
        end
    end
end

function assertFlirLayout(h, fig)
    h.assertStartupSucceeded(fig);
    ids = ["thermalSources", "palette", "colorMapping", ...
        "gammaValue", "autoRange", "roundRanges", "groupRange", ...
        "perImageRange", "rangePreset", "temperatureRange", ...
        "readingTable", "exportImages", "thermalPreview.thermal"];
    for id = ids
        assert(numel(findall(fig, "Tag", id)) == 1, ...
            "Missing FLIR Thermal semantic target: %s.", id);
    end
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
