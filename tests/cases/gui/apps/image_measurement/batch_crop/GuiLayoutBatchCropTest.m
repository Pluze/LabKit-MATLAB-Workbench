classdef GuiLayoutBatchCropTest < matlab.uitest.TestCase
    %GUILAYOUTBATCHCROPTEST Verify batch crop GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function batch_crop_workflow_exports_synthetic_crop(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            sourcePath = fullfile(folder, 'source.png');
            imwrite(syntheticCropImage(), sourcePath);

            [fig, debug] = labkit_BatchImageCrop_app("debug");
            drawnow;
            assertBatchCropLayout(h, fig);
            assert(debug.enabled && debug.traceEnabled, ...
                'Batch crop debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Batch image crop debug trace enabled', ...
                'Batch crop debug launch should mirror trace lines into the visible Log tab.');
            driver = labkitWorkflowDriver(fig);
            testCase.verifyTrue(isfile(debug.manifestFile), ...
                'Batch crop debug launch should record a sample manifest.');
            testCase.verifyEqual(char(driver.fileStatus('images')), 'No images loaded', ...
                'Batch crop debug launch should not preload generated samples.');

            driver.chooseFiles('images', sourcePath);

            driver.click('Add images or folder');
            assert(driver.enabled('useImageCenter') && ...
                driver.enabled('useImageXCenter') && driver.enabled('useImageYCenter'), ...
                'Center alignment buttons should enable after a source image loads.');
            assert(driver.enabled('exportCrops'), ...
                'Batch crop export should enable after a source image loads.');
            assert(contains(driver.fileStatus('images'), '1'), ...
                'Batch crop image file status should report the loaded image count.');
            assert(any(contains(driver.fileListItems('images'), 'source.png')), ...
                'Batch crop file list should show the synthetic source image.');
            ui = getappdata(fig, 'labkitUiRegistry');
            testCase.verifyEqual(string(ui.controls.rotation.slider.Enable), "on");
            testCase.verifyEqual(ui.controls.rotation.valueSpinner.Step, 0.1);
            testCase.verifyEqual(string(ui.controls.paddingPercent.slider.Enable), "on");
            testCase.verifyEqual(string(ui.controls.centerX.slider.Enable), "on");
            testCase.verifyEqual(string(ui.controls.centerY.slider.Enable), "on");
            testCase.verifyEqual(ui.controls.cropWidth.slider.Limits, [1 120]);
            testCase.verifyEqual(ui.controls.cropHeight.slider.Limits, [1 120]);
            labkit.ui.view.setValue(ui, 'cropWidth', 20);
            ui.controls.cropWidth.valueSpinner.ValueChangedFcn( ...
                ui.controls.cropWidth.valueSpinner, struct('PreviousValue', 34));
            h.waitForUiIdle(fig);
            testCase.verifyEqual(labkit.ui.view.getValue(ui, 'cropWidth'), 20, ...
                'User crop-size edits should survive the migrated runtime render pass.');
            labkit.ui.view.setValue(ui, 'scaleMode', 'Physical');
            ui.controls.scaleMode.valueHandle.ValueChangedFcn( ...
                ui.controls.scaleMode.valueHandle, struct());
            h.waitForUiIdle(fig);
            testCase.verifyEqual(string(ui.controls.physicalWidth.slider.Enable), "on");
            testCase.verifyEqual(string(ui.controls.physicalHeight.slider.Enable), "on");
            testCase.verifyEqual(string(ui.controls.targetPixelsPerUnit.slider.Enable), "on");
            testCase.verifyEqual(string(ui.controls.maxUpsamplePercent.slider.Enable), "on");
            labkit.ui.view.setValue(ui, 'scaleMode', 'Pixels');
            ui.controls.scaleMode.valueHandle.ValueChangedFcn( ...
                ui.controls.scaleMode.valueHandle, struct());
            h.waitForUiIdle(fig);

            driver.click('Use XY center');
            data = driver.tableData('resultTable');
            assert(any(strcmp(string(data(:, 1)), 'Confirmed centers') & ...
                strcmp(string(data(:, 2)), '1 / 1')), ...
                'Using the image center should confirm the current crop center.');

            driver.click('Export cropped images');
            outputFolder = fullfile(folder, 'batch_crop');
            manifestFiles = dir(fullfile(outputFolder, '*manifest*.csv'));
            cropFiles = dir(fullfile(outputFolder, '*_crop.png'));
            assert(~isempty(manifestFiles), ...
                'Batch crop workflow should write a manifest CSV.');
            assert(~isempty(cropFiles), ...
                'Batch crop workflow should write a cropped image.');
            assert(any(contains(string(driver.textAreaValue('details')), 'Last manifest')), ...
                'Batch crop details should show the last manifest after export.');
        end
    end
end

function assertBatchCropLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add images or folder', ...
        'Remove selected', 'Clear images', ...
        'Duplicate image', 'Previous image', 'Next image', 'Use XY center', ...
        'Use X center', 'Use Y center', ...
        'Choose export folder', 'Export cropped images', ...
        'Measure reference pixels', 'Place scale bar'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1), ...
        h.dropdownGroup({'Pixels', 'Physical'}, 1), ...
        h.dropdownGroup({'m', 'cm', 'mm', 'um', 'nm'}, 2), ...
        h.dropdownGroup({'Bottom center', 'Bottom left', 'Bottom right', ...
            'Top center', 'Top left', 'Top right'}, 1), ...
        h.dropdownGroup({'Black', 'White'}, 1)]);
    h.assertTabTitles(fig, {'Files + Analysis', 'Scale', 'Summary + Results', 'Log'});
end

function img = syntheticCropImage()
    [x, y] = meshgrid(1:48, 1:36);
    img = uint8(mod(x .* 5 + y .* 7, 256));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
