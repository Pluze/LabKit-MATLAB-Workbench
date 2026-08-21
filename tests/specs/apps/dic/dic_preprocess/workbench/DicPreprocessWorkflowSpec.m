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
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("referenceFile", string(reference), 1);
            runtime.applyFileSelection("movingFile", string(moving), 1);
            runtime.invokeAction("startPointMatching");
            testCase.verifyEqual( ...
                runtime.State.project.parameters.previewMode, ...
                "Current pair");
            runtime.applyInteraction("matchPoints", ...
                "interactionChanged", ...
                {[20 15; 30 24], [17 17; 27 26]});
            referenceAxes = findall(figureValue, "Tag", "preview.reference");
            movingAxes = findall(figureValue, "Tag", "preview.moving");
            testCase.verifyFalse(hasVisibleConnectingLine(referenceAxes));
            testCase.verifyFalse(hasVisibleConnectingLine(movingAxes));
            runtime.invokeAction("autoAlign");
            events = runtime.diagnosticSnapshot().events;
            event = events(string({events.eventName}) == ...
                "dic_preprocess.analysisrun.runautomaticregistration.status");
            testCase.verifyNumElements(event, 1);
            testCase.verifyEqual(sort(string(fieldnames(event.attributes))), ...
                sort(["angleDegrees"; "overlapFraction"; "score"; ...
                "scoreMargin"; "translationPeakMargin"; ...
                "translationX"; "translationY"]));
            runtime.invokeAction("startCropRoi");
            overlayTag = "labkitDicPreprocessPreviewOverlay";
            testCase.verifyNotEmpty(findall(referenceAxes, "Tag", overlayTag));
            testCase.verifyNotEmpty(findall(movingAxes, "Tag", overlayTag));
            runtime.invokeAction("applyCropRoi");
            croppedSize = size(runtime.State.session.cache.currentReferenceImage);
            testCase.verifyEqual(referenceAxes.XLim, ...
                [.5 croppedSize(2) + .5], AbsTol=1e-12);
            testCase.verifyEqual(referenceAxes.YLim, ...
                [.5 croppedSize(1) + .5], AbsTol=1e-12);
            runtime.invokeAction("startMaskEdit");
            testCase.verifyEqual(runtime.State.session.workflow.mode, "mask");
            runtime.invokeAction("saveCurrentImages");

            cache = runtime.State.session.cache;
            testCase.verifyEqual(cache.currentReferenceImage, cache.currentMovingImage);
            testCase.verifyEqual(numel(runtime.State.project.annotations.editSteps), 2);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.reference").Children);
            testCase.verifyTrue(isfile(fullfile(folder, "current_reference.png")));
            testCase.verifyTrue(isfile(fullfile(folder, "current_moving.png")));
            testCase.verifyTrue(isfile(runtime.State.project.results.currentImagesOutputPath));
            clear cleanup
        end
    end
end

function tf = hasVisibleConnectingLine(ax)
lines = findall(ax, "Type", "line");
tf = false;
for index = 1:numel(lines)
    x = double(lines(index).XData);
    if string(lines(index).LineStyle) ~= "none" && ...
            nnz(isfinite(x)) >= 2
        tf = true;
        return;
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
