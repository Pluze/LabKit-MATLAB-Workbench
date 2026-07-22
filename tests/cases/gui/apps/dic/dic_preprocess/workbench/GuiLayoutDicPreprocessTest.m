classdef GuiLayoutDicPreprocessTest < matlab.unittest.TestCase
    % Verify DIC Preprocess through the explicit App SDK runtime.
    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutUsesSemanticTargets(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            cleanup = onCleanup(@() helpers.closeAllFigures());
            figure = labkit_DICPreprocess_app();
            ids = ["referenceFile", "movingFile", "startPointMatching", ...
                "applyPointAlignment", "autoAlign", "startCropRoi", ...
                "applyCropRoi", "startMaskEdit", "saveCurrentImages", ...
                "saveMask", "preview.reference", "preview.moving"];
            for id = ids
                testCase.verifyEqual(numel(findall( ...
                    figure, "Tag", id)), 1);
            end
            clear cleanup
        end

        function pairDrivesAlignmentMatchingAndCrop(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            referencePath = fullfile(folder, "reference.png");
            movingPath = fullfile(folder, "moving.png");
            imageData = syntheticDicImage();
            imwrite(imageData, referencePath);
            imwrite(imageData, movingPath);
            backend = struct("alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                dic_preprocess.definition(), [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();

            runtime.applyFileSelection("referenceFile", referencePath, 1);
            runtime.applyFileSelection("movingFile", movingPath, 1);

            testCase.verifyTrue(dic_preprocess.sourceFiles.hasImagePair( ...
                runtime.State.session.cache));
            runtime.invokeAction("autoAlign");
            testCase.verifyEqual( ...
                runtime.State.project.parameters.previewMode, ...
                "False-color overlay");
            testCase.verifyEqual(numel( ...
                runtime.State.project.annotations.editSteps), 1);
            referenceAxes = findall(figure, "Tag", "preview.reference");
            movingAxes = findall(figure, "Tag", "preview.moving");
            testCase.verifyNotEmpty(referenceAxes.Children);
            testCase.verifyNotEmpty(movingAxes.Children);

            runtime.invokeAction("startPointMatching");
            points = {[20 20; 60 40], [20 20; 60 40]};
            runtime.applyInteraction( ...
                "matchPoints", "interactionChanged", points);
            runtime.invokeAction("applyPointAlignment");
            testCase.verifyEqual(numel( ...
                runtime.State.project.annotations.editSteps), 2);
            testCase.verifyEqual( ...
                runtime.State.session.workflow.mode, "idle");

            runtime.invokeAction("startCropRoi");
            runtime.applyInteraction("cropRectangle", ...
                "interactionChanged", [10 10 40 40]);
            runtime.invokeAction("applyCropRoi");
            testCase.verifyEqual(numel( ...
                runtime.State.project.annotations.editSteps), 3);
            testCase.verifyLessThan(size( ...
                runtime.State.session.cache.currentReferenceImage, 1), ...
                size(imageData, 1));
            clear runtimeCleanup folderCleanup
        end
    end
end

function imageData = syntheticDicImage()
[x, y] = meshgrid(1:96, 1:72);
base = 0.35 + 0.25 .* sin(x ./ 6) + 0.25 .* cos(y ./ 5);
dots = mod(round(x ./ 9) + round(y ./ 7), 2) .* 0.12;
imageData = uint8(255 .* min(max(base + dots, 0), 1));
end

function removeTempFolder(folder)
if exist(folder, "dir") == 7
    rmdir(folder, "s");
end
end
