classdef GuiLayoutFocusStackTest < matlab.unittest.TestCase
    %GUILAYOUTFOCUSSTACKTEST Verify focus stack GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function focus_stack_workflow_loads_and_runs_synthetic_images(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            [nearImage, farImage] = syntheticFocusPair();
            nearPath = fullfile(folder, 'frame_near.png');
            farPath = fullfile(folder, 'frame_far.png');
            extraPath = fullfile(folder, 'frame_extra.png');
            imwrite(uint8(255 .* nearImage), nearPath);
            imwrite(uint8(255 .* farImage), farPath);
            imwrite(uint8(255 .* flip(farImage, 2)), extraPath);

            fusedPath = fullfile(folder, 'focus_stack_fused.png');
            focusMapPath = fullfile(folder, 'focus_stack_map.png');
            summaryPath = fullfile(folder, 'focus_stack_summary.csv');
            manifestPath = fullfile(folder, 'focus_stack.labkit.json');
            backend = struct( ...
                "chooseInputFolder", @(~) ...
                    labkit.app.dialog.Choice(folder), ...
                "chooseOutputFile", @(~, startPath) ...
                    labkit.app.dialog.Choice(startPath), ...
                "alert", @(~, ~) []);
            runtime = focus_stack.definition().createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertFocusStackLayout(h, fig);
            runtime.invokeAction("sourceFolderChosen");
            testCase.verifyEqual(numel( ...
                runtime.State.session.cache.images), 3);
            runtime.applyFileSelection( ...
                'sourceImages', [nearPath farPath], [1 2]);
            testCase.verifyEqual(numel( ...
                runtime.State.session.cache.images), 2);
            runtime.applyControlValue("fusionPreset", "Crisp");
            testCase.verifyEqual( ...
                runtime.State.project.parameters.fusionPreset, "Crisp");

            runtime.invokeAction('runFocusStack');
            testCase.verifyTrue(runtime.State.session.cache.result.ok);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.result.fused);
            testCase.verifyFalse(isfield( ...
                runtime.State.project.results.lastRun, 'fused'));
            fusedAxes = findall(fig, 'Tag', 'preview.fused');
            mapAxes = findall(fig, 'Tag', 'preview.focusMap');
            testCase.verifyNotEmpty(fusedAxes.Children);
            testCase.verifyNotEmpty(mapAxes.Children);

            runtime.invokeAction('exportFused');
            testCase.verifyTrue(isfile(fusedPath));
            testCase.verifyTrue(isfile(manifestPath));
            runtime.invokeAction('exportFocusMap');
            testCase.verifyTrue(isfile(focusMapPath));
            runtime.invokeAction('exportSummary');
            testCase.verifyTrue(isfile(summaryPath));
            testCase.verifyEqual( ...
                runtime.State.project.results.lastExport.kind, "summary");
            testCase.verifyEqual( ...
                runtime.State.project.results.resultManifestPath, ...
                string(manifestPath));

            runtime.applyFileSelection( ...
                'sourceImages', [nearPath farPath extraPath], [1 2 3]);
            testCase.verifyFalse( ...
                runtime.State.project.results.lastRun.ok);
            runtime.invokeAction('runFocusStack');
            projectPath = fullfile(folder, 'focus-stack-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'session'), ...
                'Focus Stack projects must exclude decoded and result caches.');
            testCase.verifyTrue(saved.labkitProject.payload.results.lastRun.ok, ...
                'Focus Stack projects should preserve compact run results.');
            runtime.applyFileSelection( ...
                'sourceImages', strings(1, 0), zeros(1, 0));
            runtime.restoreProject(projectPath);
            testCase.verifyEqual(numel(runtime.State.session.cache.images), 3, ...
                'Project reopen should rebuild the source-image cache.');
            testCase.verifyFalse(runtime.State.session.cache.result.ok, ...
                'Project reopen should not persist full result matrices.');
            clear runtimeCleanup
        end
    end
end

function assertFocusStackLayout(h, fig)
    h.assertStartupSucceeded(fig);
    ids = ["sourceLocation", "sourceImages", "sourceFolderChosen", ...
        "fusionPreset", "autoRegister", ...
        "focusWindow", "smoothRadius", "uncertainBlend", ...
        "runFocusStack", "exportFused", "exportFocusMap", ...
        "exportSummary", "resultTable", "details", ...
        "preview.fused", "preview.focusMap"];
    for id = ids
        assert(numel(findall(fig, "Tag", id)) == 1, ...
            "Missing Focus Stack semantic target: %s.", id);
    end
    tabs = findall(fig, "Type", "uitab");
    assert(isequal(sort(string({tabs.Title})), ...
        sort(["Files + Analysis", "Summary + Results", "Log"])));
    assert(numel(findall(fig, "Title", "Focus Stack Preview")) >= 2);
    assert(~isempty(findall(fig, "Title", "Workflow Notes")));
    resultTable = findall(fig, "Tag", "resultTable");
    assert(size(resultTable.Data, 1) == 7);
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
