classdef GuiLayoutImageMatchTest < matlab.uitest.TestCase
    %GUILAYOUTIMAGEMATCHTEST Verify image match GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function image_match_workflow_applies_reference_and_exports(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            referencePath = fullfile(folder, 'reference.png');
            sourcePath = fullfile(folder, 'source.png');
            imwrite(syntheticReferenceImage(), referencePath);
            imwrite(syntheticSourceImage(), sourcePath);

            fig = h.launchFigure('labkit_ImageMatch_app', 'Paper Image Match');
            assertImageMatchLayout(h, fig);
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('referenceImage', referencePath);
            driver.chooseFiles('sourceImages', sourcePath);

            driver.click('Choose reference');
            driver.click('Add images or folder');
            testCase.verifyTrue(driver.enabled('applyMatch'), ...
                'Image match apply action should enable after source and reference images load.');
            testCase.verifyTrue(driver.enabled('exportImages'), ...
                'Image match export action should enable after source and reference images load.');
            testCase.verifyTrue(contains(driver.fileStatus('sourceImages'), '1'), ...
                'Image match source file status should report the loaded image count.');
            testCase.verifyTrue(any(contains(driver.fileListItems('sourceImages'), 'source.png')), ...
                'Image match file list should show the synthetic source image.');

            driver.click('Apply match');
            history = driver.tableData('historyTable');
            testCase.verifyEqual(size(history, 1), 1, ...
                'Image match workflow should add one history step.');
            testCase.verifyEqual(string(history{1, 2}), "Reference match", ...
                'Image match history should record a reference-match step.');
            testCase.verifyTrue(contains(string(history{1, 3}), 'Balanced reference'), ...
                'Image match default method should be recorded in history details.');
            testCase.verifyGreaterThan(driver.previewChildCount('preview'), 0, ...
                'Image match preview should render the matched image.');

            driver.click('Export matched images');
            outputFolder = fullfile(folder, 'image_match');
            manifestFiles = dir(fullfile(outputFolder, '*manifest*.csv'));
            outputFiles = dir(fullfile(outputFolder, '*_matched.png'));
            testCase.verifyFalse(isempty(manifestFiles), ...
                'Image match workflow should write a manifest CSV.');
            testCase.verifyFalse(isempty(outputFiles), ...
                'Image match workflow should write a matched PNG.');
            testCase.verifyTrue(any(contains(string(driver.textAreaValue('exportDetails')), ...
                'Last manifest')), ...
                'Image match details should show the last manifest after export.');
        end
    end
end

function assertImageMatchLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Choose reference', ...
        'Add images or folder', 'Remove selected', ...
        'Clear images', 'Apply match', ...
        'Undo history', 'Reset history', ...
        'Choose folder', 'Export matched images'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Matched', 'Original', 'Before | After'}, 1), ...
        h.dropdownGroup({'Balanced', 'White balance', 'Tone only', ...
        'Protected tone', 'Lab style', 'Histogram'}, 1), ...
        h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1)]);
    h.assertTabTitles(fig, {'Library + Export', 'Match + History', 'Log'});
end

function img = syntheticReferenceImage()
    [x, y] = meshgrid(1:72, 1:56);
    red = 0.55 + 0.25 .* sin(x ./ 8);
    green = 0.45 + 0.25 .* cos(y ./ 7);
    blue = 0.35 + 0.20 .* sin((x + y) ./ 11);
    img = uint8(255 .* min(max(cat(3, red, green, blue), 0), 1));
end

function img = syntheticSourceImage()
    [x, y] = meshgrid(1:72, 1:56);
    red = 0.35 + 0.22 .* cos(x ./ 9);
    green = 0.50 + 0.22 .* sin(y ./ 6);
    blue = 0.60 + 0.18 .* cos((x - y) ./ 10);
    img = uint8(255 .* min(max(cat(3, red, green, blue), 0), 1));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
