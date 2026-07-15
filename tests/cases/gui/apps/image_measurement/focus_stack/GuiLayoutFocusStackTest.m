classdef GuiLayoutFocusStackTest < matlab.unittest.TestCase
    %GUILAYOUTFOCUSSTACKTEST Verify focus stack GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function focus_stack_workflow_loads_and_runs_synthetic_images(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            [nearImage, farImage] = syntheticFocusPair();
            nearPath = fullfile(folder, 'frame_near.png');
            farPath = fullfile(folder, 'frame_far.png');
            extraPath = fullfile(folder, 'frame_extra.png');
            folderStack = fullfile(folder, 'folder_stack');
            mkdir(folderStack);
            imwrite(uint8(255 .* nearImage), nearPath);
            imwrite(uint8(255 .* farImage), farPath);
            imwrite(uint8(255 .* flip(farImage, 2)), extraPath);
            imwrite(uint8(255 .* nearImage), fullfile(folderStack, 'slice_1.png'));
            imwrite(uint8(255 .* farImage), fullfile(folderStack, 'slice_2.png'));

            [fig, debug] = labkit_FocusStack_app("debug");
            drawnow;
            assertFocusStackLayout(h, fig);
            assert(debug.enabled && debug.traceEnabled, ...
                'Focus Stack debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Focus stack debug trace enabled', ...
                'Focus Stack debug launch should mirror trace lines into the visible Log tab.');
            h.invokeDropdownValue(fig, 'Crisp details');
            lines = string(debug.getLog());
            assert(any(contains(lines, 'BEGIN ValueChangedFcn')), ...
                'Focus Stack debug mode should instrument declarative control callbacks.');
            h.invokeDropdownValue(fig, 'Balanced');

            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('sourceImages', [string(nearPath); string(farPath)]);

            driver.click('Add images or folder');
            assert(driver.enabled('runFocusStack'), ...
                'Focus stack run action should enable after two source images load.');
            assert(contains(driver.fileStatus('sourceImages'), '2'), ...
                'Focus stack source file status should report the loaded image count.');
            assert(numel(driver.fileListItems('sourceImages')) == 2, ...
                'Focus stack source list should show both synthetic source images.');
            assert(any(contains(string(driver.textAreaValue('details')), 'Loaded images: 2')), ...
                'Focus stack details panel should describe the loaded source stack.');

            driver.click('Run focus stack');
            assert(driver.enabled('exportFused'), ...
                'Fused PNG export should enable after a successful workflow run.');
            assert(driver.enabled('exportFocusMap'), ...
                'Focus-map PNG export should enable after a successful workflow run.');
            assert(driver.enabled('exportSummary'), ...
                'Summary CSV export should enable after a successful workflow run.');
            data = driver.tableData('resultTable');
            assert(any(strcmp(string(data(:, 1)), 'Input images')), ...
                'Focus stack result table should include the input image count metric.');
            assert(any(contains(string(driver.textAreaValue('details')), 'Selected pixel coverage by source')), ...
                'Focus stack details panel should describe the completed fusion result.');

            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.definition.contractVersion, 2, ...
                'Focus Stack should run on the Runtime V2 state contract.');
            testCase.verifyEqual(numel(runtime.state.project.inputs.sources), 2);
            testCase.verifyFalse(isfield(runtime.state.project, 'images'), ...
                'Decoded focus images must not be persisted in the project.');
            testCase.verifyFalse(isfield(runtime.state.project.results.lastRun, 'fused'), ...
                'Durable Focus Stack results must exclude the fused image matrix.');
            testCase.verifyNotEmpty(runtime.state.session.cache.result.fused, ...
                'The fused image should remain an ephemeral session cache.');

            fusedPath = fullfile(folder, 'focus_stack_fused.png');
            runtime.request.outputFileChooser = @(~, ~, ~) deal( ...
                'focus_stack_fused.png', folder);
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            driver.click('Export fused PNG');
            testCase.verifyTrue(isfile(fusedPath));
            testCase.verifyTrue(isfile(fullfile(folder, ...
                'focus_stack.labkit.json')), ...
                sprintf('Focus Stack export should add a standard result manifest. Log: %s', ...
                strjoin(string(driver.textAreaValue('logPanel')), ' | ')));

            driver.chooseFiles('sourceImages', extraPath);
            driver.click('Add images or folder');
            assert(contains(driver.fileStatus('sourceImages'), '3'), ...
                'Focus stack append should preserve the existing source stack.');
            assert(numel(driver.fileListItems('sourceImages')) == 3, ...
                'Focus stack append should keep prior source images in the file list.');

            driver.click('Run focus stack');
            projectPath = fullfile(folder, 'focus-stack-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'session'), ...
                'Focus Stack projects must exclude decoded and result caches.');
            testCase.verifyTrue(saved.labkitProject.payload.results.lastRun.ok, ...
                'Focus Stack projects should preserve compact run results.');
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(numel(runtime.state.session.cache.images), 3, ...
                'Project reopen should rebuild the source-image cache.');
            testCase.verifyFalse(runtime.state.session.cache.result.ok, ...
                'Project reopen should not persist full result matrices.');
            testCase.verifyTrue(any(contains(string(driver.textAreaValue('details')), ...
                'Saved summary restored')), ...
                'Project reopen should present the durable summary and rerun requirement.');

            runtime.request.inputFolderChooser = @(~, ~) folderStack;
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            driver.click('Choose folder');
            testCase.verifyEqual(numel(driver.fileListItems('sourceImages')), 2, ...
                'The V2 input-folder service should register the selected image folder.');
        end
    end
end

function assertFocusStackLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add images or folder', ...
        'Remove selected', 'Clear images', 'Choose folder', ...
        'Run focus stack', 'Export fused PNG', 'Export focus map PNG', ...
        'Export summary CSV'});
    h.assertCheckboxContract(fig, {'Auto-register stack to middle image'});
    h.assertDropdownGroups(fig, h.dropdownGroup( ...
        cellstr(focus_stack.userInterface.fusionPresetItems()), 1));
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
end

function [nearImage, farImage] = syntheticFocusPair()
    heightPx = 72;
    widthPx = 104;
    [x, y] = meshgrid(1:widthPx, 1:heightPx);
    sharp = 0.5 + 0.25 .* sin(0.75 .* x) + 0.25 .* cos(0.65 .* y);
    sharp = min(max(sharp, 0), 1);
    blurred = boxBlur(sharp, 13);

    mid = floor(widthPx / 2);
    nearMask = false(heightPx, widthPx);
    nearMask(:, 1:mid) = true;

    nearGray = blurred;
    farGray = blurred;
    nearGray(nearMask) = sharp(nearMask);
    farGray(~nearMask) = sharp(~nearMask);

    nearImage = cat(3, nearGray, 0.85 .* nearGray, 0.65 .* nearGray);
    farImage = cat(3, farGray, 0.85 .* farGray, 0.65 .* farGray);
end

function out = boxBlur(in, windowSize)
    kernel = ones(windowSize, windowSize);
    out = conv2(in, kernel, 'same') ./ conv2(ones(size(in)), kernel, 'same');
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
