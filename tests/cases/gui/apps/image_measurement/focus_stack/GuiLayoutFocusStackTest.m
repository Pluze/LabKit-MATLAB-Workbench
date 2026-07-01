classdef GuiLayoutFocusStackTest < matlab.uitest.TestCase
    %GUILAYOUTFOCUSSTACKTEST Verify focus stack GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function focus_stack_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_FocusStack_app', ...
                'Microscope Focus Stack Fusion');
            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Add images or folder', ...
                'Remove selected', 'Clear images', 'Run focus stack', 'Export fused PNG', ...
                'Export focus map PNG', 'Export summary CSV'});
            h.assertCheckboxContract(fig, {'Auto-register stack to middle image'});
            h.assertDropdownGroups(fig, h.dropdownGroup({'Balanced', ...
                'Crisp details', 'Smooth transitions', 'Noisy images'}, 1));
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});

            h.closeAllFigures();
            [fig, debug] = labkit_FocusStack_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'Focus Stack debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Focus stack debug trace enabled', ...
                'Focus Stack debug launch should mirror trace lines into the visible Log tab.');

            h.invokeDropdownValue(fig, 'Crisp details');
            lines = string(debug.getLog());
            assert(any(contains(lines, 'BEGIN ValueChangedFcn')), ...
                'Focus Stack debug mode should instrument declarative control callbacks.');
            assertAnyTextAreaContains(h, fig, 'BEGIN ValueChangedFcn', ...
                'Focus Stack debug mode should mirror instrumented callback traces into the visible Log tab.');
        end
    end

    methods (Test, TestTags = {'GUI', 'Workflow'})
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
            imwrite(uint8(255 .* nearImage), nearPath);
            imwrite(uint8(255 .* farImage), farPath);

            fig = h.launchFigure('labkit_FocusStack_app', ...
                'Microscope Focus Stack Fusion');
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
        end
    end
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
