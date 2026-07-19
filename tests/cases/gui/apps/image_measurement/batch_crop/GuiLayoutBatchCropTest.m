classdef GuiLayoutBatchCropTest < matlab.unittest.TestCase
    % Verify Batch Crop through the explicit App SDK runtime.
    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutUsesSemanticTargets(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            backend = struct("alert", @(~, ~) []);
            runtime = batch_crop.definition().createMatlabRuntime([], backend);
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();
            ids = ["images", "duplicateImage", "removeCurrentTask", ...
                "cropWidth", "rotation", "centerX", ...
                "measureScaleReference", "scaleReferencePixels", ...
                "placeScaleBar", "exportCrops", "resultTable", ...
                "preview"];
            for id = ids
                testCase.verifyEqual(numel(findall( ...
                    figure, "Tag", id)), 1);
            end
            clear cleanup
        end

        function cropTasksCenterAndExportSyntheticImages(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            sourcePath = fullfile(folder, "source.png");
            imageData = syntheticCropImage();
            imwrite(imageData, sourcePath);
            backend = struct("alert", @(~, ~) []);
            runtime = batch_crop.definition().createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            runtime.applyFileSelection("images", sourcePath, 1);
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.items), 1);
            testCase.verifyTrue( ...
                batch_crop.sourceFiles.hasCurrentImage(runtime.State));
            runtime.applyBinding("cropWidth", 20);
            runtime.invokeAction("useImageCenter");
            runtime.invokeAction("duplicateImage");
            runtime.invokeAction("useImageCenter");

            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.items), 2);
            testCase.verifyTrue(all( ...
                [runtime.State.project.inputs.items.centerSet]));
            testCase.verifyEqual( ...
                runtime.State.project.parameters.cropWidth, 20);
            testCase.verifyNotEmpty(findall( ...
                figure, "Tag", "preview").Children);

            runtime.invokeAction("exportCrops");

            outputFolder = fullfile(folder, "batch_crop");
            testCase.verifyNotEmpty(dir(fullfile( ...
                outputFolder, "*_crop.png")));
            testCase.verifyNotEmpty(dir(fullfile( ...
                outputFolder, "*manifest*.csv")));
            testCase.verifyTrue(isfile(fullfile( ...
                outputFolder, "batch_crop_results.labkit.json")));
            testCase.verifyTrue(strlength( ...
                runtime.State.project.results.resultManifestPath) > 0);
            clear runtimeCleanup folderCleanup
        end
    end
end

function imageData = syntheticCropImage()
[x, y] = meshgrid(1:48, 1:36);
imageData = uint8(mod(x .* 5 + y .* 7, 256));
end

function removeTempFolder(folder)
if exist(folder, "dir") == 7
    rmdir(folder, "s");
end
end
