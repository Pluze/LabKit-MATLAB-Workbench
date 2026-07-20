classdef GuiLayoutFlirThermalTest < matlab.unittest.TestCase
    %GUILAYOUTFLIRTHERMALTEST Verify FLIR thermal GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function flir_thermal_restores_full_display_reading_and_export_workflow(testCase)
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
                'thermalFiles', [sourcePath secondSourcePath], 2);
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 2);
            testCase.verifyEqual( ...
                runtime.State.session.selection.currentIndex, 2);
            runtime.invokeAction("previousImage");
            testCase.verifyEqual( ...
                runtime.State.session.selection.currentIndex, 1);
            runtime.invokeAction("nextImage");
            testCase.verifyEqual( ...
                runtime.State.session.selection.currentIndex, 2);
            testCase.verifyFalse(isfield( ...
                runtime.State.project.annotations.items, 'raw'));
            testCase.verifyFalse(isfield( ...
                runtime.State.project.annotations.items, 'temperatureC'), ...
                'Durable FLIR annotations must not persist decoded thermal matrices.');
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.currentItem.temperatureC, ...
                'The selected FLIR decode should remain an ephemeral session cache.');
            thermalAxes = component(fig, "preview.thermalImage");
            scaleAxes = component(fig, "preview.temperatureScale");
            testCase.verifyNotEmpty(thermalAxes.Children);
            testCase.verifyNotEmpty(scaleAxes.Children);
            testCase.verifyLessThanOrEqual( ...
                abs(thermalAxes.Position(4) - scaleAxes.Position(4)), 2);

            runtime.applyControlValue("palette", "iron");
            runtime.applyControlValue("colorMapping", "Gamma");
            runtime.applyControlValue("gammaValue", 1.6);
            labels = ...
                flir_thermal.thermalPreview.presentationData.rangeControlLabels();
            runtime.applyControlValue("rangePreset", labels.estimatedPreset);
            presetRange = ...
                runtime.State.session.cache.currentItem.displayRange;
            crossedMinimum = presetRange(2) + 10;
            crossedMaximum = presetRange(2) - 10;
            runtime.applyControlValue("temperatureMin", crossedMinimum);
            runtime.applyControlValue("temperatureMax", crossedMaximum);
            testCase.verifyEqual( ...
                runtime.State.session.cache.currentItem.displayRange, ...
                [crossedMaximum presetRange(2)], AbsTol=1e-12);

            runtime.applyInteraction( ...
                'temperatureReading', 'backgroundPressed', [1 1]);
            runtime.invokeAction("roiHotMode");
            runtime.applyInteraction( ...
                'temperatureReading', 'interactionChanged', [1 1 1 1]);
            runtime.invokeAction("roiColdMode");
            runtime.applyInteraction( ...
                'temperatureReading', 'interactionChanged', [1 1 1 1]);
            runtime.invokeAction("roiMeanMode");
            runtime.applyInteraction( ...
                'temperatureReading', 'interactionChanged', [1 1 1 1]);
            item = runtime.State.session.cache.currentItem;
            testCase.verifyTrue(isfinite(item.manualPoint.temperatureC));
            testCase.verifyTrue(isfinite(item.roiHotSpot.temperatureC));
            testCase.verifyTrue(isfinite(item.roiColdSpot.temperatureC));
            testCase.verifyTrue(isfinite(item.roiMean.temperatureC));
            testCase.verifyGreaterThan( ...
                size(component(fig, "summaryTable").Data, 1), 4);
            testCase.verifyNotEmpty(component(fig, "details").Value);

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

            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportCurrent");
            testCase.verifyEqual(numel( ...
                runtime.State.project.results.lastExport.results), 1);
            runtime.invokeAction("exportAll");
            testCase.verifyNotEmpty( ...
                runtime.State.project.results.lastExport);
            testCase.verifyTrue(isfolder(outputFolder));
            testCase.verifyEqual(numel( ...
                runtime.State.project.results.lastExport.results), 2);
            testCase.verifyTrue(isfile( ...
                runtime.State.project.results.resultManifestPath));
            testCase.verifyTrue(isfile( ...
                fullfile(outputFolder, "flir_thermal_manifest.csv")));
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
                'thermalFiles', [coolPath warmPath], [1 2]);
            runtime.invokeAction('groupRange');

            items = runtime.State.project.annotations.items;
            testCase.verifyEqual(numel(items), 2);
            testCase.verifyEqual(items(1).displayRange, ...
                items(2).displayRange, AbsTol=0.05);
            testCase.verifyEqual(items(1).rangeControlBounds, ...
                items(1).displayRange, AbsTol=0.05);
            runtime.applyControlValue( ...
                'temperatureMin', items(1).displayRange(1));
            runtime.applyControlValue( ...
                'temperatureMax', items(1).displayRange(2));
            testCase.verifyEqual( ...
                runtime.State.session.cache.currentItem.displayRange, ...
                items(1).displayRange, AbsTol=0.05);
            clear runtimeCleanup
        end
    end
end

function assertFlirLayout(h, fig)
    h.assertStartupSucceeded(fig);
    ids = ["thermalFiles", "fileStatus", "previousImage", "nextImage", ...
        "currentImage", "palette", "colorMapping", "gammaValue", ...
        "rangePreset", "perImageRange", "groupRange", "autoRange", ...
        "roundRange", "temperatureMin", "temperatureMax", ...
        "outputFolder", "exportFormat", "chooseOutputFolder", ...
        "exportCurrent", "exportAll", "summaryTable", ...
        "roiHotMode", "roiColdMode", "roiMeanMode", "details", ...
        "logPanel", "preview.thermalImage", "preview.temperatureScale"];
    for id = ids
        assert(numel(findall(fig, "Tag", id)) == 1, ...
            "Missing FLIR Thermal semantic target: %s.", id);
    end
    tabs = findall(fig, "Type", "uitab");
    assert(isequal(sort(string({tabs.Title})), ...
        sort(["Files + Display + Export", "Details", "Log"])));
    assert(~isempty(findall(fig, "Title", "Thermal Preview")));
    assert(~isempty(findall(fig, "Title", "FLIR Images")));
    assert(~isempty(findall(fig, "Title", "Reading Tools")));
    h.assertAxesContract(fig, { ...
        h.axesSpec("Clean thermal image", "", ""), ...
        h.axesSpec("Scale", "", "")});
end

function value = component(figureHandle, tag)
    value = findall(figureHandle, "Tag", char(tag));
    assert(isscalar(value), "Expected one component with Tag %s.", tag);
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
