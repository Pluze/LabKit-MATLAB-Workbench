classdef GuiLayoutCurvatureTest < matlab.uitest.TestCase
    %GUILAYOUTCURVATURETEST Verify curvature measurement GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function curvature_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_CurvatureMeasurement_app', ...
                'Image Curvature Measurement');
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
            assertScaleBarPanelSpansControlTab(fig);

            h.closeAllFigures();
            [fig, debug] = labkit_CurvatureMeasurement_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'Curvature debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, ...
                'Curvature measurement debug trace enabled', ...
                'Curvature debug launch should mirror trace lines into the visible Log tab.');

            h.invokeCheckbox(fig, 'Show dense fit points', false);
            lines = string(debug.getLog());
            assert(any(contains(lines, 'BEGIN ValueChangedFcn') & ...
                contains(lines, 'Show dense fit points')), ...
                'Curvature debug mode should instrument GUI callbacks with control labels.');
            assert(any(contains(lines, 'ValueChangedFcn') & ...
                contains(lines, 'refreshImageOverlay')), ...
                'Curvature debug mode should include the original callback function name.');
            assertAnyTextAreaContains(h, fig, 'BEGIN ValueChangedFcn', ...
                'Curvature debug mode should mirror instrumented callback traces into the visible Log tab.');
        end
    end

    methods (Test, TestTags = {'GUI', 'Workflow'})
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

            fig = h.launchFigure('labkit_CurvatureMeasurement_app', ...
                'Image Curvature Measurement');
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('imageFile', imagePath);

            driver.click('Choose image');
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
        end
    end
end

function assertScaleBarPanelSpansControlTab(fig)
    hosts = findall(fig, 'Type', 'uipanel', 'Tag', 'LabKitToolPanel_scaleBarHost');
    assert(numel(hosts) >= 1, 'Curvature app should include a scale-bar tool host.');
    hostLayout = hosts(1).Layout;
    assert(isprop(hostLayout, 'Column') && isequal(hostLayout.Column, [1 2]), ...
        'Scale-bar tool host should span the full two-column control section.');

    scalePanels = findall(fig, 'Type', 'uipanel', 'Title', 'Scale Bar');
    assert(numel(scalePanels) >= 1, 'Curvature app should include a Scale Bar panel.');
    for k = 1:numel(scalePanels)
        if scalePanels(k).Parent == hosts(1).Children(1)
            assert(scalePanels(k).Position(3) > 250, ...
                'Scale Bar panel width should not be clipped inside the tool host.');
            return;
        end
    end
    error('Scale Bar panel should be mounted inside the semantic tool host.');
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
