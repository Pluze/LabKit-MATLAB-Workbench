classdef GuiLayoutDicPreprocessTest < matlab.unittest.TestCase
    %GUILAYOUTDICPREPROCESSTEST Verify DIC preprocess GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function dic_preprocess_workflow_loads_and_auto_aligns_pair(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            referencePath = fullfile(folder, 'reference.png');
            movingPath = fullfile(folder, 'moving.png');
            reference = syntheticDicImage();
            imwrite(reference, referencePath);
            imwrite(reference, movingPath);

            fig = h.launchFigure('labkit_DICPreprocess_app', ...
                'DIC Image Preprocess');
            assertDicPreprocessLayout(h, fig);
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('referenceFile', referencePath);
            driver.chooseFiles('movingFile', movingPath);

            driver.click('Choose reference');
            driver.click('Choose moving');
            driver.click('Auto align current pair');
            [aligned, waitInfo] = h.waitForCondition(fig, ...
                @() dicPreprocessAlignmentReady(driver), 15);

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.referenceFile.status.Value), ...
                'reference.png'), ...
                'DIC preprocess workflow should show the loaded reference image.');
            testCase.verifyTrue(contains(string(ui.controls.movingFile.status.Value), ...
                'moving.png'), ...
                'DIC preprocess workflow should show the loaded moving image.');
            testCase.verifyEqual(string(ui.controls.previewMode.valueHandle.Value), ...
                "False-color overlay", ...
                'DIC preprocess workflow should switch to false-color overlay after auto align.');
            testCase.verifyTrue(any(contains(string(driver.textAreaValue('summaryText')), ...
                'Reference')), ...
                'DIC preprocess workflow should refresh the summary after loading images.');
            testCase.verifyTrue(aligned, sprintf(['DIC preprocess workflow should ' ...
                'refresh alignment details after auto align. %s'], ...
                h.waitDiagnostic(waitInfo, 'appLog', appLog(driver))));
            testCase.verifyGreaterThan(numel(ui.controls.previewAxes.axesById.reference.Children), 0, ...
                'DIC preprocess workflow should draw the reference preview.');
            testCase.verifyGreaterThan(numel(ui.controls.previewAxes.axesById.current.Children), 0, ...
                'DIC preprocess workflow should draw the current preview.');
        end

        function pointMatchingStaysInMainWorkbench(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            referencePath = fullfile(folder, 'reference.png');
            movingPath = fullfile(folder, 'moving.png');
            imageData = syntheticDicImage();
            imwrite(imageData, referencePath);
            imwrite(imageData, movingPath);

            fig = h.launchFigure('labkit_DICPreprocess_app', ...
                'DIC Image Preprocess');
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('referenceFile', referencePath);
            driver.chooseFiles('movingFile', movingPath);
            driver.click('Choose reference');
            driver.click('Choose moving');
            labels = dic_preprocess.userInterface.registrationLabels();
            driver.click(labels.startPointMatching);

            ui = driver.registry();
            testCase.verifyEmpty(findall(groot, 'Type', 'figure', ...
                'Name', 'DIC Manual Alignment'), ...
                'Point matching should remain inside the main DIC workbench.');
            testCase.verifyEqual(string( ...
                ui.controls.applyPointAlignment.button.Enable), ...
                "off", 'Alignment should wait for at least two complete pairs.');
            testCase.verifyEqual(string( ...
                ui.controls.cancelPointMatching.button.Enable), ...
                "on", 'The active in-place point matcher should be cancellable.');
            driver.click(labels.cancelPointMatching);
            testCase.verifyEqual(string( ...
                ui.controls.startPointMatching.button.Enable), ...
                "on", 'Cancelling should restore the point-matching start action.');
            clear folderCleanup cleanup
        end
    end
end

function tf = dicPreprocessAlignmentReady(driver)
    details = lower(string(driver.textAreaValue('detailsText')));
    tf = any(contains(details, 'transform matrix'));
end

function text = appLog(driver)
    text = strjoin(string(driver.logValue('appLog')), ' | ');
end

function assertDicPreprocessLayout(h, fig)
    labels = dic_preprocess.userInterface.registrationLabels();
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Choose reference', 'Choose moving', ...
        labels.startPointMatching, labels.applyPointAlignment, ...
        labels.cancelPointMatching, labels.undoPointPair, labels.autoAlign, ...
        'Start/reset crop ROI', 'Apply ROI crop', 'Cancel ROI', ...
        'Undo align/crop', 'Save current images', 'Reset to originals', ...
        'Start ROI edit', 'Preview ROI mask', 'Add to mask', ...
        'Subtract from mask', 'Undo point', 'Undo mask edit', ...
        'Clear boundary', 'Clear mask', 'Save ROI mask'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Current pair', 'Current moving image', ...
        'False-color overlay', 'Original pair', 'ROI mask'}, 1), ...
        h.dropdownGroup({'Curve', 'Straight lines'}, 1)]);
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertDropdownCallbacksPresent(fig);
    assert(~isempty(fig.WindowScrollWheelFcn), ...
        'DIC preprocess should install a preview scroll-wheel zoom callback.');
end

function img = syntheticDicImage()
    [x, y] = meshgrid(1:96, 1:72);
    base = 0.35 + 0.25 .* sin(x ./ 6) + 0.25 .* cos(y ./ 5);
    dots = mod(round(x ./ 9) + round(y ./ 7), 2) .* 0.12;
    img = uint8(255 .* min(max(base + dots, 0), 1));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
