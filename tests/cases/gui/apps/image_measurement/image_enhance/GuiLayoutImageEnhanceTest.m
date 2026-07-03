classdef GuiLayoutImageEnhanceTest < matlab.uitest.TestCase
    %GUILAYOUTIMAGEENHANCETEST Verify image enhance GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function image_enhance_workflow_applies_tool_and_exports(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            sourcePath = fullfile(folder, 'paper.png');
            secondSourcePath = fullfile(folder, 'paper_second.png');
            imwrite(syntheticPaperImage(), sourcePath);
            imwrite(rot90(syntheticPaperImage()), secondSourcePath);

            [fig, debug] = labkit_ImageEnhance_app("debug");
            drawnow;
            assertImageEnhanceLayout(h, fig);
            assert(debug.enabled && debug.traceEnabled, ...
                'Image enhance debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Image enhance debug trace enabled', ...
                'Image enhance debug launch should mirror trace lines into the visible Log tab.');
            driver = labkitWorkflowDriver(fig);
            testCase.verifyTrue(isfile(debug.manifestFile), ...
                'Image enhance debug launch should record a sample manifest.');
            testCase.verifyEqual(char(driver.fileStatus('sourceImages')), 'No images loaded', ...
                'Image enhance debug launch should not preload generated samples.');
            verifyPerImageHistoryRefresh(fig);
            driver.chooseFiles('sourceImages', sourcePath);

            driver.click('Add images or folder');
            testCase.verifyTrue(driver.enabled('applyTool'), ...
                'Image enhance apply action should enable after image load.');
            testCase.verifyTrue(driver.enabled('exportImages'), ...
                'Image enhance export action should enable after image load.');
            testCase.verifyTrue(contains(driver.fileStatus('sourceImages'), '1'), ...
                'Image enhance file status should report the loaded image count.');

            driver.click('Apply tool');
            history = driver.tableData('historyTable');
            testCase.verifyEqual(size(history, 1), 1, ...
                'Image enhance workflow should add one history step.');
            testCase.verifyTrue(contains(string(history{1, 2}), 'Brightness'), ...
                'Image enhance default tool should be recorded in history.');

            driver.click('Export enhanced images');
            outputFolder = fullfile(folder, 'image_enhance');
            manifestFiles = dir(fullfile(outputFolder, '*manifest*.csv'));
            outputFiles = dir(fullfile(outputFolder, '*_enhanced.png'));
            testCase.verifyFalse(isempty(manifestFiles), ...
                'Image enhance workflow should write a manifest CSV.');
            testCase.verifyFalse(isempty(outputFiles), ...
                'Image enhance workflow should write an enhanced PNG.');
            testCase.verifyTrue(any(contains(string(driver.textAreaValue('exportDetails')), ...
                'Last manifest')), ...
                'Image enhance details should show the last manifest after export.');

            driver.chooseFiles('sourceImages', secondSourcePath);
            driver.click('Add images or folder');
            testCase.verifyTrue(contains(driver.fileStatus('sourceImages'), '2'), ...
                'Image enhance append should preserve the existing source image.');
            testCase.verifyTrue(contains(driver.fileSelection('sourceImages'), ...
                'paper_second.png'), ...
                'Image enhance append should select the newly added source image.');
        end
    end
end

function assertImageEnhanceLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add images or folder', ...
        'Remove selected', 'Clear images', ...
        'Set white ROI', 'Apply tool', 'Undo history', 'Reset history', ...
        'Choose folder', 'Export enhanced images'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Enhanced', 'Original', 'Before | After'}, 1), ...
        h.dropdownGroup({'Brightness/contrast', 'Local contrast', ...
        'Sharpen', 'Hue/saturation', 'White balance', ...
        'White ROI calibration', 'Subject-preserving enhance'}, 1), ...
        h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1)]);
    h.assertCheckboxContract(fig, {'Batch shared processing'});
    h.assertTabTitles(fig, {'Library + Export', 'Tools + History', 'Log'});
end

function img = syntheticPaperImage()
    [x, y] = meshgrid(1:64, 1:48);
    base = 0.45 + 0.25 .* sin(x ./ 7) + 0.20 .* cos(y ./ 5);
    img = uint8(255 .* min(max(base, 0), 1));
end

function verifyPerImageHistoryRefresh(fig)
    ui = getappdata(fig, 'labkitUiRegistry');
    item = image_enhance.appState.emptyItem();
    item.path = "first.png";
    item.name = "first.png";
    item.image = ones(8, 8, 3) .* 0.5;
    item.steps = image_enhance.analysisRun.makeStep('Brightness/contrast', 10, 0, 0);
    second = item;
    second.path = "second.png";
    second.name = "second.png";
    second.steps = image_enhance.analysisRun.makeStep('Sharpen', 20, 1, 0);
    S = struct('items', [item; second], 'currentIndex', 1, ...
        'steps', repmat(image_enhance.appState.emptyStep(), 0, 1), ...
        'batchMode', false, 'pendingDirty', false);

    ui.controls.historyTable.table.Data = image_enhance.userInterface.historyTableData( ...
        image_enhance.appState.activeSteps(S));
    firstData = ui.controls.historyTable.table.Data;
    S.currentIndex = 2;
    ui.controls.historyTable.table.Data = image_enhance.userInterface.historyTableData( ...
        image_enhance.appState.activeSteps(S));
    secondData = ui.controls.historyTable.table.Data;

    assert(contains(string(firstData{1, 2}), "Brightness"), ...
        'Per-image mode should show the first image history while first is selected.');
    assert(contains(string(secondData{1, 2}), "Sharpen"), ...
        'Per-image mode should refresh history when the selected image changes.');
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
