classdef GuiLayoutImageEnhanceTest < matlab.unittest.TestCase
    %GUILAYOUTIMAGEENHANCETEST Verify image enhance GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function image_enhance_workflow_applies_tool_and_exports(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            sourcePath = fullfile(folder, 'paper.png');
            secondSourcePath = fullfile(folder, 'paper_second.png');
            imwrite(syntheticPaperImage(), sourcePath);
            imwrite(rot90(syntheticPaperImage()), secondSourcePath);

            outputFolder = fullfile(folder, 'image_enhance');
            backend = struct( ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(outputFolder), ...
                "alert", @(~, ~) []);
            runtime = image_enhance.definition().createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertImageEnhanceLayout(h, fig);
            runtime.applyFileSelection('sourceImages', sourcePath, 1);
            runtime.applyControlValue('batchMode', false);
            runtime.invokeAction('applyTool');
            testCase.verifyEqual(numel( ...
                runtime.State.project.annotations.items), 1);
            testCase.verifyEqual(numel( ...
                runtime.State.project.annotations.items(1).steps), 1);

            runtime.invokeAction('exportImages');
            manifestFiles = dir(fullfile(outputFolder, '*manifest*.csv'));
            outputFiles = dir(fullfile(outputFolder, '*_enhanced.png'));
            testCase.verifyFalse(isempty(manifestFiles), ...
                'Image enhance workflow should write a manifest CSV.');
            testCase.verifyFalse(isempty(outputFiles), ...
                'Image enhance workflow should write an enhanced PNG.');
            runtime.applyFileSelection( ...
                'sourceImages', [sourcePath secondSourcePath], 2);
            runtime.applyControlValue('toolKind', 'Sharpen');
            runtime.invokeAction('applyTool');
            testCase.verifyEqual(numel( ...
                runtime.State.project.annotations.items), 2);
            second = image_enhance.sourceLibrary.annotationForSource( ...
                runtime.State.project.annotations.items, ...
                runtime.State.project.inputs.sources(2).id);
            testCase.verifyTrue(contains( ...
                string(second.steps(1).label), 'Sharpen'));
            runtime.applyFilePanelSelection('sourceImages', 1);
            first = image_enhance.sourceLibrary.annotationForSource( ...
                runtime.State.project.annotations.items, ...
                runtime.State.project.inputs.sources(1).id);
            testCase.verifyTrue(contains( ...
                string(first.steps(1).label), 'Brightness'));

            projectPath = fullfile(folder, 'image-enhance-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'session'), ...
                'Image Enhance projects must exclude the rebuildable session.');
            testCase.verifyFalse(any(isfield( ...
                saved.labkitProject.payload.annotations.items, ...
                {'image', 'previewImage', 'whiteRoiHandle'})), ...
                'Image Enhance projects must exclude pixels and UI resources.');
            runtime.restoreProject(projectPath);
            testCase.verifyNotEmpty(runtime.State.session.cache.item.image, ...
                'Project reopen should lazily rebuild the selected image cache.');
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 2);
            testCase.verifyEqual(numel( ...
                runtime.State.project.annotations.items), 2);
            clear runtimeCleanup
        end
    end
end

function assertImageEnhanceLayout(h, fig)
    h.assertStartupSucceeded(fig);
    ids = ["sourceImages", "exportFormat", "exportImages", ...
        "batchMode", "toolKind", "toolAmount", "toolSecondary", ...
        "applyTool", "undoHistory", "resetHistory", "resultTable", ...
        "details", "preview.image"];
    for id = ids
        assert(numel(findall(fig, "Tag", id)) == 1, ...
            "Missing Image Enhance semantic target: %s.", id);
    end
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
