classdef GuiLayoutBatchCropTest < matlab.uitest.TestCase
    %GUILAYOUTBATCHCROPTEST Verify batch crop GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function batch_crop_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_BatchImageCrop_app', ...
                'Microscope Batch Image Crop');
            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Add images or folder', ...
                'Remove selected', 'Clear images', ...
                'Duplicate image', 'Previous image', 'Next image', 'Use image center', ...
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

            h.closeAllFigures();
            [fig, debug] = labkit_BatchImageCrop_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'Batch crop debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Batch image crop debug trace enabled', ...
                'Batch crop debug launch should mirror trace lines into the visible Log tab.');
        end
    end

    methods (Test, TestTags = {'GUI', 'Workflow'})
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

            fig = h.launchFigure('labkit_BatchImageCrop_app', ...
                'Microscope Batch Image Crop');
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('images', sourcePath);

            driver.click('Add images or folder');
            assert(driver.enabled('useImageCenter'), ...
                'Use image center should enable after a source image loads.');
            assert(driver.enabled('exportCrops'), ...
                'Batch crop export should enable after a source image loads.');
            assert(contains(driver.fileStatus('images'), '1'), ...
                'Batch crop image file status should report the loaded image count.');
            assert(any(contains(driver.fileListItems('images'), 'source.png')), ...
                'Batch crop file list should show the synthetic source image.');

            driver.click('Use image center');
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

function img = syntheticCropImage()
    [x, y] = meshgrid(1:48, 1:36);
    img = uint8(mod(x .* 5 + y .* 7, 256));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
