classdef GuiLayoutFlirThermalTest < matlab.uitest.TestCase
    %GUILAYOUTFLIRTHERMALTEST Verify FLIR thermal GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function flir_thermal_load_keeps_scale_axis_full_height(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            folder = tempname;
            mkdir(folder);
            cleanupFolder = onCleanup(@() removeTempFolder(folder));
            cleanupFigure = onCleanup(@() h.closeAllFigures());
            sourcePath = fullfile(folder, "synthetic_flir.jpg");
            writeSyntheticFlirRjpegFixture(sourcePath);

            [fig, debug] = labkit_FLIRThermal_app("debug");
            drawnow;
            assertFlirLayout(h, fig);
            assert(debug.enabled && debug.traceEnabled, ...
                'FLIR Thermal debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'FLIR thermal debug trace enabled', ...
                'FLIR Thermal debug launch should mirror trace lines into the visible Log tab.');
            ui = getappdata(fig, 'labkitUiRegistry');
            testCase.verifyTrue(isfile(debug.manifestFile), ...
                'FLIR Thermal debug launch should record a sample manifest.');
            testCase.verifyEqual(char(labkit.ui.view.getValue(ui, 'fileStatus')), 'Files: 0', ...
                'FLIR Thermal debug launch should not preload generated samples.');
            testCase.verifyEqual(char(labkit.ui.view.getValue(ui, 'currentImage')), 'No FLIR image loaded', ...
                'FLIR Thermal debug launch should not preload generated samples.');

            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('thermalFiles', sourcePath);
            h.invokeButton(fig, 'Add FLIR files or folder');
            drawnow;

            ui = getappdata(fig, 'labkitUiRegistry');
            scaleAxes = ui.controls.preview.axesById.temperatureScale;
            labels = flir_thermal.view.rangeControlLabels();

            testCase.verifyEqual(string(labkit.ui.view.getValue(ui, 'rangePreset')), ...
                labels.defaultPreset);
            testCase.verifyTrue(isempty(ui.controls.thermalFiles.status));
            testCase.verifyTrue(driver.enabled('rangePreset'));
            testCase.verifyTrue(driver.enabled('temperatureMin'));
            testCase.verifyTrue(driver.enabled('temperatureMax'));
            testCase.verifyTrue(driver.enabled('autoRange'));
            testCase.verifyTrue(driver.enabled('groupRange'));
            testCase.verifyTrue(driver.enabled('perImageRange'));
            testCase.verifyFalse(driver.enabled('roundRange'));
            testCase.verifyEqual(scaleAxes.DataAspectRatioMode, 'auto');
            testCase.verifyEqual(scaleAxes.PlotBoxAspectRatioMode, 'auto');
            testCase.verifyEmpty(char(string(scaleAxes.Title.String)));
            testCase.verifyEqual(numel(scaleAxes.Children), 1);
        end

        function flir_shared_range_limits_manual_adjustment_to_shared_bounds(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            folder = tempname;
            mkdir(folder);
            cleanupFolder = onCleanup(@() removeTempFolder(folder));
            cleanupFigure = onCleanup(@() h.closeAllFigures());
            coolPath = fullfile(folder, "synthetic_flir_cool.jpg");
            warmPath = fullfile(folder, "synthetic_flir_warm.jpg");
            writeSyntheticFlirRjpegFixture(coolPath, struct("raw", uint16(18000 + [0 10; 20 30])));
            writeSyntheticFlirRjpegFixture(warmPath, struct("raw", uint16(18000 + [400 420; 450 470])));

            fig = h.launchFigure('labkit_FLIRThermal_app', ...
                'FLIR Thermal Postprocess');
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('thermalFiles', [string(coolPath); string(warmPath)]);
            h.invokeButton(fig, 'Add FLIR files or folder');
            labels = flir_thermal.view.rangeControlLabels();
            h.invokeButton(fig, char(labels.setSharedRange));
            drawnow;

            ui = getappdata(fig, 'labkitUiRegistry');
            minLimits = ui.controls.temperatureMin.slider.Limits;
            maxLimits = ui.controls.temperatureMax.slider.Limits;
            currentMin = labkit.ui.view.getValue(ui, 'temperatureMin');
            currentMax = labkit.ui.view.getValue(ui, 'temperatureMax');
            testCase.verifyLessThanOrEqual(max(abs(minLimits - [currentMin currentMax])), 0.05);
            testCase.verifyLessThanOrEqual(max(abs(maxLimits - [currentMin currentMax])), 0.05);
        end
    end
end

function assertFlirLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    labels = flir_thermal.view.rangeControlLabels();
    h.assertButtonContract(fig, {'Add FLIR files or folder', ...
        'Remove selected', 'Clear files', 'Previous image', ...
        'Next image', char(labels.setEachRange), ...
        char(labels.setSharedRange), char(labels.setCurrentRange), ...
        char(labels.roundSetRanges), ...
        char(labels.roiHotSpot), char(labels.roiColdSpot), ...
        char(labels.roiMean), ...
        'Choose folder', 'Export current', 'Export all'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'turbo', 'iron', 'hot', 'parula', 'gray'}, 1), ...
        h.dropdownGroup(flir_thermal.view.rangePresetItems(), 1), ...
        h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1)]);
    h.assertTabTitles(fig, {'Files + Display + Export', 'Details', 'Log'});
    h.assertAxesContract(fig, { ...
        h.axesSpec('Clean thermal image', '', ''), ...
        h.axesSpec('Scale', '', '')});
end

function assertAnyTextAreaContains(h, fig, needle, message)
    areas = h.findControlsByClass(fig, 'TextArea');
    values = strings(1, numel(areas));
    for k = 1:numel(areas)
        values(k) = strjoin(string(areas{k}.Value), newline);
    end
    assert(any(contains(values, needle)), message);
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
