classdef GuiLayoutImageMatchTest < matlab.unittest.TestCase
    %GUILAYOUTIMAGEMATCHTEST Verify image match GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function image_match_workflow_applies_reference_and_exports(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            referencePath = fullfile(folder, 'reference.png');
            sourcePath = fullfile(folder, 'source.png');
            secondSourcePath = fullfile(folder, 'source_second.png');
            imwrite(syntheticReferenceImage(), referencePath);
            imwrite(syntheticSourceImage(), sourcePath);
            imwrite(rot90(syntheticSourceImage()), secondSourcePath);

            outputFolder = fullfile(folder, 'image_match');
            mkdir(outputFolder);
            backend = struct( ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(outputFolder), ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                image_match.definition(), [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertImageMatchLayout(h, fig);
            runtime.applyFileSelection('referenceImage', referencePath, 1);
            runtime.applyFileSelection('sourceImages', sourcePath, 1);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.referenceItem.image);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.currentItem.image);

            runtime.applyControlValue('matchStrength', 85);
            testCase.verifyTrue( ...
                runtime.State.session.workflow.pendingDirty);
            runtime.invokeAction('applyMatch');
            steps = runtime.State.project.annotations.steps;
            testCase.verifyEqual(numel(steps), 1);
            testCase.verifyTrue(contains( ...
                string(steps(1).label), "Balanced reference"));
            previewAxes = findall(fig, 'Tag', 'preview.image');
            testCase.verifyNotEmpty(previewAxes.Children);

            runtime.applyControlValue('preview', 'Original');
            testCase.verifyEqual( ...
                runtime.State.session.view.previewMode, "Original");
            runtime.invokeAction('chooseOutputFolder');
            runtime.invokeAction('exportImages');
            testCase.verifyTrue(isfile(fullfile( ...
                outputFolder, 'source_matched.png')), ...
                'Image match workflow should write a matched PNG.');
            testCase.verifyFalse(isempty(dir(fullfile( ...
                outputFolder, 'image_match_manifest*.csv'))));
            testCase.verifyTrue(isfile(fullfile( ...
                outputFolder, 'image_match.labkit.json')));
            runtime.invokeAction('undoHistory');
            testCase.verifyEmpty( ...
                runtime.State.project.annotations.steps);
            runtime.invokeAction('applyMatch');
            runtime.invokeAction('resetHistory');
            testCase.verifyEmpty( ...
                runtime.State.project.annotations.steps);
            runtime.invokeAction('applyMatch');
            runtime.applyFileSelection( ...
                'sourceImages', [sourcePath secondSourcePath], [1 2]);
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 2);
            runtime.applyFilePanelSelection('sourceImages', 2);
            testCase.verifyEqual( ...
                runtime.State.session.cache.currentItem.name, ...
                "source_second.png");

            projectPath = fullfile(folder, 'image-match-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'session'), ...
                'Image Match projects must exclude rebuildable caches.');
            runtime.applyFileSelection( ...
                'sourceImages', strings(1, 0), zeros(1, 0));
            runtime.restoreProject(projectPath);
            testCase.verifyNotEmpty(runtime.State.session.cache.currentItem.image);
            testCase.verifyNotEmpty(runtime.State.session.cache.referenceItem.image);
            testCase.verifyEqual(numel( ...
                runtime.State.project.annotations.steps), 1);
            clear runtimeCleanup
        end
    end
end

function assertImageMatchLayout(h, fig)
    h.assertStartupSucceeded(fig);
    ids = ["referenceImage", "sourceImages", "imageStatus", ...
        "outputFolder", "exportFormat", "chooseOutputFolder", ...
        "exportImages", "exportDetails", "matchMethod", ...
        "matchStrength", "toneStrength", "colorStrength", ...
        "applyMatch", "matchFlow", "undoHistory", ...
        "resetHistory", "historyTable", "historyStatus", ...
        "metricsTable", "preview", "preview.image"];
    for id = ids
        assert(numel(findall(fig, "Tag", id)) == 1, ...
            "Missing Image Match semantic target: %s.", id);
    end
    tabs = findall(fig, "Type", "uitab");
    assert(isequal(sort(string({tabs.Title})), ...
        sort(["Library + Export", "Match + History", "Log"])));
    assert(numel(findall(fig, "Title", "Preview")) >= 2);
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
