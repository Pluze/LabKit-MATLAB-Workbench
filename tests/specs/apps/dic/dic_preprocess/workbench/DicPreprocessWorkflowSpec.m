classdef DicPreprocessWorkflowSpec < matlab.unittest.TestCase
    %DICPREPROCESSWORKFLOWSPEC Specify DIC pair alignment, crop, and export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function alignsCropsExportsAndRestoresASyntheticPair(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            reference = fullfile(folder, "reference.png");
            moving = fullfile(folder, "moving.png");
            writePair(reference, moving);
            backend = struct( ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            definition = dic_preprocess.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("referenceFile", string(reference), 1);
            runtime.applyFileSelection("movingFile", string(moving), 1);
            runtime.invokeAction("autoAlign");
            runtime.invokeAction("startCropRoi");
            runtime.invokeAction("applyCropRoi");
            runtime.invokeAction("saveCurrentImages");

            cache = runtime.State.session.cache;
            testCase.verifyEqual(cache.currentReferenceImage, cache.currentMovingImage);
            testCase.verifyEqual(numel(runtime.State.project.annotations.editSteps), 2);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.reference").Children);
            testCase.verifyTrue(isfile(fullfile(folder, "current_reference.png")));
            testCase.verifyTrue(isfile(fullfile(folder, "current_moving.png")));
            testCase.verifyTrue(isfile(runtime.State.project.results.currentImagesManifestPath));
            saved = fullfile(folder, "dic-preprocess-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.invokeAction("resetToOriginals");
            runtime.restoreProject(saved);
            testCase.verifyEqual(numel(runtime.State.project.annotations.editSteps), 2);
            testCase.verifyEqual(runtime.State.session.cache.currentReferenceImage, ...
                runtime.State.session.cache.currentMovingImage);
            clear cleanup
        end
    end
end

function writePair(referencePath, movingPath)
reference = zeros(40, 48, "uint8");
reference(12:25, 20:33) = 255;
moving = zeros(size(reference), "uint8");
moving(14:27, 17:30) = 255;
imwrite(reference, referencePath);
imwrite(moving, movingPath);
end
