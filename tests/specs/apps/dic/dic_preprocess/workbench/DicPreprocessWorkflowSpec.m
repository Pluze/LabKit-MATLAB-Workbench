classdef DicPreprocessWorkflowSpec < matlab.unittest.TestCase
    %DICPREPROCESSWORKFLOWSPEC Specify DIC pair alignment, crop, and export.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function alignsCropsExportsAndRestoresASyntheticPair(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            reference = fullfile(folder, "reference.png");
            moving = fullfile(folder, "moving.png");
            maskPath = fullfile(folder, "roi-mask.png");
            writePair(reference, moving);
            backend = struct( ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(maskPath), ...
                "alert", @(~, ~) []);
            definition = dic_preprocess.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("referenceFile", string(reference), 1);
            runtime.applyFileSelection("movingFile", string(moving), 1);
            runtime.applyControlValue("previewMode", "Original pair");
            runtime.invokeAction("startPointMatching");
            testCase.verifyEqual( ...
                runtime.State.project.parameters.previewMode, ...
                "Current pair");
            runtime.applyInteraction("matchPoints", ...
                "interactionChanged", ...
                {[20 15; 30 24], [17 17; 27 26]});
            runtime.invokeAction("undoPointPair");
            testCase.verifyNumElements( ...
                runtime.State.project.annotations.matchReferencePoints(:, 1), 1);
            runtime.applyInteraction("matchPoints", ...
                "interactionChanged", ...
                {[20 15; 30 24], [17 17; 27 26]});
            runtime.invokeAction("cancelPointMatching");
            testCase.verifyEqual(runtime.State.session.workflow.mode, "idle");
            runtime.invokeAction("startPointMatching");
            runtime.applyInteraction("matchPoints", ...
                "interactionChanged", ...
                {[20 15; 30 24], [17 17; 27 26]});
            runtime.invokeAction("applyPointAlignment");
            referenceAxes = findall(figureValue, "Tag", "preview.reference");
            movingAxes = findall(figureValue, "Tag", "preview.moving");
            testCase.verifyFalse(hasVisibleConnectingLine(referenceAxes));
            testCase.verifyFalse(hasVisibleConnectingLine(movingAxes));
            runtime.invokeAction("autoAlign");
            events = runtime.diagnosticSnapshot().events;
            event = events(string({events.eventName}) == ...
                "dic_preprocess.analysisrun.runautomaticregistration.status");
            testCase.verifyNumElements(event, 1);
            testCase.verifyEmpty(fieldnames(event.attributes));
            runtime.invokeAction("startCropRoi");
            overlayTag = "labkitDicPreprocessPreviewOverlay";
            testCase.verifyNotEmpty(findall(referenceAxes, "Tag", overlayTag));
            testCase.verifyNotEmpty(findall(movingAxes, "Tag", overlayTag));
            runtime.applyInteraction("cropRectangle", ...
                "interactionChanged", [5 5 30 25]);
            runtime.invokeAction("cancelCropRoi");
            runtime.invokeAction("startCropRoi");
            runtime.applyInteraction("cropRectangle", ...
                "interactionChanged", [5 5 30 25]);
            runtime.invokeAction("applyCropRoi");
            runtime.invokeAction("undoEdit");
            runtime.invokeAction("startCropRoi");
            runtime.applyInteraction("cropRectangle", ...
                "interactionChanged", [5 5 30 25]);
            runtime.invokeAction("applyCropRoi");
            croppedSize = size(runtime.State.session.cache.currentReferenceImage);
            testCase.verifyEqual(referenceAxes.XLim, ...
                [.5 croppedSize(2) + .5], AbsTol=1e-12);
            testCase.verifyEqual(referenceAxes.YLim, ...
                [.5 croppedSize(1) + .5], AbsTol=1e-12);
            runtime.invokeAction("startMaskEdit");
            testCase.verifyEqual(runtime.State.session.workflow.mode, "mask");
            runtime.applyControlValue("boundaryStyle", "Straight lines");
            boundary = [4 4; 22 4; 22 18; 4 18];
            runtime.applyInteraction("maskPoints", ...
                "interactionChanged", boundary);
            runtime.invokeAction("undoMaskAnchor");
            runtime.applyInteraction("maskPoints", ...
                "interactionChanged", boundary);
            runtime.invokeAction("previewMaskRoi");
            runtime.invokeAction("addBoundaryToMask");
            runtime.applyInteraction("maskPoints", ...
                "interactionChanged", [8 8; 14 8; 14 14; 8 14]);
            runtime.invokeAction("subtractBoundaryFromMask");
            runtime.invokeAction("undoMaskEdit");
            runtime.invokeAction("clearMaskBoundary");
            runtime.invokeAction("clearMaskCanvas");
            runtime.applyInteraction("maskPoints", ...
                "interactionChanged", boundary);
            runtime.invokeAction("addBoundaryToMask");
            runtime.invokeAction("saveMask");
            runtime.invokeAction("saveCurrentImages");

            cache = runtime.State.session.cache;
            testCase.verifyEqual(cache.currentReferenceImage, cache.currentMovingImage);
            testCase.verifyEqual(numel(runtime.State.project.annotations.editSteps), 3);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.reference").Children);
            testCase.verifyTrue(isfile(fullfile(folder, "current_reference.png")));
            testCase.verifyTrue(isfile(fullfile(folder, "current_moving.png")));
            testCase.verifyTrue(isfile(maskPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.currentImagesOutputPath));
            runtime.invokeAction("resetToOriginals");
            testCase.verifyEmpty(runtime.State.project.annotations.editSteps);
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
