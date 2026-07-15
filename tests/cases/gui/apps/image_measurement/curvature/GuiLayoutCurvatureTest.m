classdef GuiLayoutCurvatureTest < matlab.unittest.TestCase
    %GUILAYOUTCURVATURETEST Verify curvature measurement GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function curvature_workflow_fits_curve_and_measures_length(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            imagePath = fullfile(folder, 'curvature.png');
            imwrite(syntheticCurvatureImage(), imagePath);

            [fig, debug] = labkit_CurvatureMeasurement_app("debug");
            drawnow;
            assertCurvatureLayout(h, fig);
            assert(debug.enabled && debug.traceEnabled, ...
                'Curvature debug launch should return an enabled trace logger.');
            driver = labkitWorkflowDriver(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.definition.contractVersion, 2, ...
                'Curvature must execute through Runtime V2.');
            assertAnyTextAreaContains(h, fig, 'Debug sample generation enabled', ...
                'Runtime debug-sample lifecycle should be mirrored into the Log tab.');
            driver.chooseFiles('imageFile', imagePath);

            driver.click('Choose image');
            driver.click('Measure reference pixels');
            driver.setAnchorPoints('imageAxes', [25 90; 125 90]);
            driver.click('Finish reference edit');
            testCase.verifyTrue(driver.enabled('placeScaleBar'), ...
                'Scale-bar placement should enable after reference calibration.');
            driver.click('Place scale bar');
            driver.click('Start curve edit');
            driver.setAnchorPoints('imageAxes', [28 70; 48 42; 84 30; 120 42; 140 70]);

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.pointCount.valueHandle.Value), ...
                '5'), ...
                'Curvature workflow should show the injected curve point count.');
            testCase.verifyTrue(contains(string(driver.textAreaValue('detailsText')), ...
                'Curve edit active'), ...
                'Curvature workflow should show edit guidance while the anchor editor is active.');

            driver.click('Finish curve edit');
            testCase.verifyTrue(driver.enabled('fitCurvature'), ...
                'Curvature fit action should enable after at least three curve points.');
            testCase.verifyTrue(driver.enabled('measureCurveLength'), ...
                'Curve length action should enable after at least two curve points.');

            driver.click('Fit circle + curvature');
            fitTable = driver.tableData('resultTable');
            testCase.verifyTrue(any(strcmp(string(fitTable(:, 1)), 'Radius')), ...
                'Curvature workflow should write radius into the result table.');
            testCase.verifyTrue(any(strcmp(string(fitTable(:, 1)), 'Curvature')), ...
                'Curvature workflow should write curvature into the result table.');
            testCase.verifyTrue(any(contains(string(driver.textAreaValue('detailsText')), ...
                'Curve length')), ...
                'Curvature workflow should refresh details after the curvature fit.');
            testCase.verifyGreaterThan(driver.previewChildCount('imageAxes'), 0, ...
                'Curvature workflow should draw the image preview and overlays.');

            driver.click('Measure curve length');
            lengthTable = driver.tableData('resultTable');
            testCase.verifyTrue(any(strcmp(string(lengthTable(:, 1)), 'Curve length')), ...
                'Curvature workflow should keep curve length visible after measuring length.');

            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() removeTempFolder(outputFolder));
            outputs = ["curvature_result.csv", "curvature_overlay.png"];
            outputIndex = 0;
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            runtime.request.outputChooser = @chooseOutput;
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            driver.click('Export result CSV');
            driver.click('Export overlay PNG');
            for filepath = fullfile(outputFolder, outputs)
                testCase.verifyTrue(isfile(filepath));
            end
            testCase.verifyTrue(isfile(fullfile(outputFolder, ...
                'curvature_result.labkit.json')));
            testCase.verifyTrue(isfile(fullfile(outputFolder, ...
                'curvature_overlay.labkit.json')));

            projectPath = fullfile(outputFolder, 'curvature-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'image'));
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyNotEmpty(runtime.state.session.cache.image, ...
                'Project reopen should rebuild the decoded image cache.');
            testCase.verifyTrue(runtime.state.project.results.fit.ok, ...
                'Project reopen should retain the durable curvature fit.');
            clear outputCleanup;

            function [filename, folderPath] = chooseOutput(~, ~, ~)
                outputIndex = outputIndex + 1;
                filename = char(outputs(outputIndex));
                folderPath = char(outputFolder);
            end
        end
    end
end

function assertCurvatureLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Choose image', 'Start curve edit', ...
        'Undo last point', 'Clear curve', 'Measure reference pixels', ...
        'Place scale bar', 'Fit circle + curvature', ...
        'Measure curve length', 'Export result CSV', 'Export overlay PNG'});
    h.assertCheckboxContract(fig, {'Densify before circle fit', ...
        'Show dense fit points'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'m', 'cm', 'mm', 'um', 'nm'}, 1), ...
        h.dropdownGroup({'Bottom center', 'Bottom left', 'Bottom right', ...
        'Top center', 'Top left', 'Top right'}, 1), ...
        h.dropdownGroup({'Black', 'White'}, 1)]);
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
end

function img = syntheticCurvatureImage()
    [x, y] = meshgrid(1:168, 1:104);
    background = 0.30 + 0.20 .* sin(x ./ 11) + 0.15 .* cos(y ./ 9);
    curve = exp(-((sqrt((x - 84).^2 + (y - 88).^2) - 58).^2) ./ 12);
    img = uint8(255 .* min(max(background + 0.45 .* curve, 0), 1));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
