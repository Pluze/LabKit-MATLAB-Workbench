classdef GuiLayoutImageEnhanceTest < matlab.unittest.TestCase
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
            assertAnyTextAreaContains(h, fig, 'Debug sample generation enabled', ...
                'Image enhance debug launch should mirror trace lines into the visible Log tab.');
            driver = labkitWorkflowDriver(fig);
            testCase.verifyTrue(isfile(debug.manifestFile), ...
                'Image enhance debug launch should record a sample manifest.');
            testCase.verifyEqual(char(driver.fileStatus('sourceImages')), 'No images loaded', ...
                'Image enhance debug launch should not preload generated samples.');
            driver.chooseFiles('sourceImages', sourcePath);

            driver.click('Add images or folder');
            testCase.verifyTrue(driver.enabled('applyTool'), ...
                'Image enhance apply action should enable after image load.');
            testCase.verifyTrue(driver.enabled('exportImages'), ...
                'Image enhance export action should enable after image load.');
            testCase.verifyTrue(contains(driver.fileStatus('sourceImages'), '1'), ...
                'Image enhance file status should report the loaded image count.');

            driver.checkbox('Batch shared processing', false);
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
            testCase.verifyTrue(isfile(fullfile(outputFolder, ...
                'image_enhance.labkit.json')), ...
                'Image enhance export should add a standard result manifest.');
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
            driver.dropdown('Sharpen');
            driver.click('Apply tool');
            secondHistory = driver.tableData('historyTable');
            testCase.verifyTrue(contains(string(secondHistory{1, 2}), 'Sharpen'), ...
                'The second image should own its independently applied tool.');
            driver.selectFile('sourceImages', 'paper.png');
            firstHistory = driver.tableData('historyTable');
            testCase.verifyTrue(contains(string(firstHistory{1, 2}), 'Brightness'), ...
                'Selecting the first image should restore its real persisted history.');
            driver.selectFile('sourceImages', 'paper_second.png');
            secondHistory = driver.tableData('historyTable');
            testCase.verifyTrue(contains(string(secondHistory{1, 2}), 'Sharpen'), ...
                'Selecting the second image should restore its real persisted history.');

            projectPath = fullfile(folder, 'image-enhance-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'session'), ...
                'Image Enhance projects must exclude the rebuildable session.');
            testCase.verifyFalse(any(isfield( ...
                saved.labkitProject.payload.annotations.items, ...
                {'image', 'previewImage', 'whiteRoiHandle'})), ...
                'Image Enhance projects must exclude pixels and UI resources.');
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyNotEmpty(runtime.state.session.cache.item.image, ...
                'Project reopen should lazily rebuild the selected image cache.');
            testCase.verifyEqual(numel(runtime.state.project.inputs.sources), 2);
            reopenedHistory = driver.tableData('historyTable');
            testCase.verifyTrue(contains(string(reopenedHistory{1, 2}), 'Brightness'), ...
                'Project reopen should rebuild the first selection and its history.');
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

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
