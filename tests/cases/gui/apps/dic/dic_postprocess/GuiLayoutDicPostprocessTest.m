classdef GuiLayoutDicPostprocessTest < matlab.uitest.TestCase
    %GUILAYOUTDICPOSTPROCESSTEST Verify DIC postprocess GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function dic_postprocess_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_DICPostprocess_app', 'DIC Strain Postprocess');
            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Choose DIC MAT', ...
                'Choose reference', 'Choose mask', ...
                'Generate overlays + summary', ...
                'Save overlay PNGs', 'Export summary CSV'});
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            assertFilesAnalysisSectionsFit(fig);
        end
    end

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function dic_postprocess_workflow_generates_overlays_and_summary(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            matPath = fullfile(folder, 'synthetic_dic.mat');
            referencePath = fullfile(folder, 'reference.png');
            maskPath = fullfile(folder, 'mask.png');
            writeSyntheticDicMat(matPath);
            imwrite(syntheticReferenceImage(), referencePath);
            imwrite(uint8(255 .* syntheticMask()), maskPath);

            fig = h.launchFigure('labkit_DICPostprocess_app', ...
                'DIC Strain Postprocess');
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('matFile', matPath);
            driver.chooseFiles('referenceFile', referencePath);
            driver.chooseFiles('maskFile', maskPath);

            driver.click('Choose DIC MAT');
            driver.click('Choose reference');
            driver.click('Choose mask');
            driver.click('Generate overlays + summary');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.matFile.status.Value), ...
                'synthetic_dic.mat'), ...
                'DIC postprocess workflow should show the loaded MAT file.');
            testCase.verifyTrue(contains(string(ui.controls.referenceFile.status.Value), ...
                'reference.png'), ...
                'DIC postprocess workflow should show the loaded reference image.');
            testCase.verifyTrue(contains(string(ui.controls.maskFile.status.Value), ...
                'mask.png'), ...
                'DIC postprocess workflow should show the loaded mask image.');
            data = driver.tableData('resultTable');
            testCase.verifyGreaterThan(size(data, 1), 0, ...
                'DIC postprocess workflow should populate the strain summary table.');
            testCase.verifyTrue(any(contains(string(driver.textAreaValue('summaryText')), ...
                'Overlays: available')), ...
                'DIC postprocess workflow should report generated overlays.');
            testCase.verifyGreaterThan(numel(ui.controls.overlayAxes.axesById.exx.Children), 0, ...
                'DIC postprocess workflow should draw the EXX overlay.');
            testCase.verifyGreaterThan(numel(ui.controls.overlayAxes.axesById.eyy.Children), 0, ...
                'DIC postprocess workflow should draw the EYY overlay.');
        end
    end
end

function assertFilesAnalysisSectionsFit(fig)
    ui = getappdata(fig, 'labkitUiRegistry');
    sectionIds = {'inputsSection', 'overlayOptions', 'imageOptions', ...
        'exportsSection'};
    layoutProps = {'height', 'minRows', 'minHeight', 'maxColumns', ...
        'rowSpacing', 'columnSpacing', 'padding', 'chrome', ...
        'columnWidth', 'rowHeight', 'position', 'leftWidth'};
    for k = 1:numel(sectionIds)
        props = ui.sections.(sectionIds{k}).spec.props;
        for iProp = 1:numel(layoutProps)
            assert(~isfield(props, layoutProps{iProp}), ...
                'DIC postprocess sections should use framework-owned layout.');
        end
    end
end

function writeSyntheticDicMat(filepath)
    [x, y] = meshgrid(linspace(-1, 1, 48), linspace(-1, 1, 36));
    data_dic_save = struct();
    data_dic_save.strains = struct();
    data_dic_save.strains.plot_exx_ref_formatted = 0.05 .* x + 0.01 .* y;
    data_dic_save.strains.plot_eyy_ref_formatted = -0.04 .* y + 0.01 .* x;
    data_dic_save.strains.roi_ref_formatted = struct('mask', syntheticMask());
    save(filepath, 'data_dic_save');
end

function img = syntheticReferenceImage()
    [x, y] = meshgrid(1:48, 1:36);
    img = uint8(mod(x .* 4 + y .* 7, 256));
end

function mask = syntheticMask()
    [x, y] = meshgrid(1:48, 1:36);
    mask = ((x - 24).^2 ./ 16^2 + (y - 18).^2 ./ 12^2) <= 1;
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
