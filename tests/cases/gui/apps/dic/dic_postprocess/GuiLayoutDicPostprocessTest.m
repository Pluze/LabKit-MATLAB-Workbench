classdef GuiLayoutDicPostprocessTest < matlab.unittest.TestCase
    %GUILAYOUTDICPOSTPROCESSTEST Verify DIC postprocess GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function dic_postprocess_workflow_generates_overlays_and_summary(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            matPath = fullfile(folder, 'synthetic_dic.mat');
            referencePath = fullfile(folder, 'reference.png');
            maskPath = fullfile(folder, 'mask.png');
            writeSyntheticDicMat(matPath);
            imwrite(syntheticReferenceImage(), referencePath);
            imwrite(uint8(255 .* syntheticMask()), maskPath);

            summaryPath = fullfile(folder, ...
                'synthetic_dic_strain_summary.csv');
            backend = struct( ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(folder), ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(summaryPath), ...
                "alert", @(~, ~) []);
            runtime = dic_postprocess.definition().createMatlabRuntime( ...
                [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertDicPostprocessLayout(h, fig);
            runtime.applyFileSelection('matFile', matPath, 1);
            runtime.applyFileSelection('referenceFile', referencePath, 1);
            runtime.applyFileSelection('maskFile', maskPath, 1);
            runtime.invokeAction('generate');

            testCase.verifyGreaterThan(height( ...
                runtime.State.project.results.summaryTable), 0);
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayExx);
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayEyy);
            exxAxes = findall(fig, 'Tag', 'overlayAxes.exx');
            eyyAxes = findall(fig, 'Tag', 'overlayAxes.eyy');
            testCase.verifyNotEmpty(exxAxes.Children);
            testCase.verifyNotEmpty(eyyAxes.Children);
            runtime.applyControlValue("alpha", 0.45);
            runtime.applyControlValue("brightness", 0.1);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.alpha, 0.45);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.brightness, 0.1);
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayExx);

            runtime.invokeAction('saveOverlays');
            runtime.invokeAction('exportSummary');
            expectedOutputs = { ...
                'overlay_exx_unknown_mm.png', ...
                'overlay_eyy_unknown_mm.png', ...
                'dic_overlays_unknown_mm.labkit.json', ...
                'synthetic_dic_strain_summary.csv', ...
                'synthetic_dic_strain_summary.labkit.json'};
            for k = 1:numel(expectedOutputs)
                testCase.verifyTrue(isfile(fullfile(folder, expectedOutputs{k})), ...
                    ['DIC postprocess export is missing ' expectedOutputs{k}]);
            end
            overlayManifest = jsondecode(fileread(fullfile(folder, ...
                'dic_overlays_unknown_mm.labkit.json')));
            summaryManifest = jsondecode(fileread(fullfile(folder, ...
                'synthetic_dic_strain_summary.labkit.json')));
            testCase.verifyEqual(string(overlayManifest.format), "labkit.result");
            testCase.verifyEqual(numel(overlayManifest.outputs), 2);
            testCase.verifyTrue(all(string({overlayManifest.outputs.status}) == ...
                "success"));
            testCase.verifyEqual(string(summaryManifest.outputs.status), ...
                "success");

            projectPath = fullfile(folder, 'dic-postprocess-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(string(saved.labkitProject.format), ...
                "labkit.project");
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyEqual(fieldnames(saved.labkitProject.payload.inputs), ...
                {'sources'}, ...
                'Saved projects should rebuild decoded DIC inputs from sources.');
            runtime.applyFileSelection( ...
                'matFile', strings(1, 0), zeros(1, 0));
            runtime.restoreProject(projectPath);
            testCase.verifyGreaterThan(height( ...
                runtime.State.project.results.summaryTable), 0);
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayExx);
            testCase.verifyNotEmpty(runtime.State.session.cache.overlayEyy);
            clear runtimeCleanup
        end
    end
end

function assertDicPostprocessLayout(h, fig)
    h.assertStartupSucceeded(fig);
    ids = ["matFile", "referenceFile", "maskFile", "generate", ...
        "alpha", "colorMin", "colorMax", "oversample", ...
        "smoothSigma", "edgeTrim", "brightness", "contrast", ...
        "gamma", "saturation", "redGain", "greenGain", "blueGain", ...
        "saveOverlays", "exportSummary", "resultTable", ...
        "summaryText", "overlayAxes.exx", "overlayAxes.eyy"];
    for id = ids
        assert(numel(findall(fig, "Tag", id)) == 1, ...
            "Missing DIC postprocess semantic target: %s.", id);
    end
    tabs = findall(fig, "Type", "uitab");
    assert(isequal(sort(string({tabs.Title})), ...
        sort(["Files + Analysis", "Summary + Results", "Log"])));
    assert(numel(findall(fig, "Title", "Strain Overlays")) >= 2);
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
