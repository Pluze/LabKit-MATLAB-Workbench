classdef BatchCropWorkflowSpec < matlab.unittest.TestCase
    %BATCHCROPWORKFLOWSPEC Specify the complete image-to-manifest journey.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsEditsExportsAndRestoresRealPngSources(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourceFolder = fullfile(folder, "sources");
            outputFolder = fullfile(folder, "exports");
            mkdir(sourceFolder);
            first = fullfile(sourceFolder, "first.png");
            second = fullfile(sourceFolder, "second.png");
            imwrite(syntheticImage(48, 64, 0), first);
            imwrite(syntheticImage(52, 68, 17), second);
            manifestPath = fullfile(outputFolder, "batch_crop_manifest.csv");
            backend = struct( ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(outputFolder), ...
                "chooseInputFile", @(varargin) ...
                    labkit.app.dialog.Choice(manifestPath), ...
                "alert", @(message, title) unexpectedAlert(message, title));
            definition = batch_crop.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("images", [string(first), string(second)], 1:2);
            preview = findall(figureValue, "Tag", "preview.main");
            testCase.verifyFalse(runtime.StartupFailed);
            testCase.verifyNumElements(runtime.State.project.inputs.items, 2);
            testCase.verifyNotEmpty(preview.Children);
            testCase.verifyEqual(size(runtime.State.session.cache.images{1}), [48 64 3]);

            runtime.applyControlValue("cropWidth", 30);
            runtime.applyControlValue("cropHeight", 24);
            runtime.applyControlValue("rotation", 12);
            runtime.applyControlValue("paddingPercent", 15);
            runtime.applyControlValue("centerX", 30);
            runtime.applyControlValue("centerY", 22);
            runtime.applyInteraction("cropRoi", "backgroundPressed", [34 26]);
            currentCenter = runtime.State.project.inputs.items(1).centerXY;
            runtime.applyInteraction("cropRoi", "interactionChanged", [8 7 30 24]);
            testCase.verifyNotEqual( ...
                runtime.State.project.inputs.items(1).centerXY, currentCenter);
            runtime.invokeAction("useImageXCenter");
            runtime.invokeAction("useImageYCenter");
            runtime.invokeAction("useImageCenter");

            runtime.invokeAction("measureScaleReference");
            runtime.applyInteraction( ...
                "scaleReference", "interactionChanged", [10 10; 30 10]);
            runtime.applyControlValue("scaleReferencePixels", 20);
            runtime.applyControlValue("scaleReferenceLength", 5);
            runtime.applyControlValue("scaleCalibrationUnit", "mm");
            runtime.applyControlValue("scaleBarLength", 4);
            runtime.applyControlValue("scaleBarPosition", "Top right");
            runtime.applyControlValue("scaleBarColor", "White");
            runtime.invokeAction("placeScaleBar");
            testCase.verifyTrue(batch_crop.scaleCalibration.isSet( ...
                runtime.State.project.inputs.items(1).scaleCalibration));

            runtime.invokeAction("duplicateImage");
            runtime.invokeAction("previousImage");
            runtime.invokeAction("nextImage");
            testCase.verifyNumElements(runtime.State.project.inputs.items, 3);
            testCase.verifyEqual(runtime.State.session.selection.currentIndex, 2);
            runtime.invokeAction("useImageCenter");
            runtime.invokeAction("nextImage");
            runtime.invokeAction("useImageCenter");
            runtime.invokeAction("previousImage");
            runtime.applyControlValue("scaleMode", "Physical");
            runtime.applyControlValue("scaleUnit", "mm");
            runtime.applyControlValue("physicalWidth", 8);
            runtime.applyControlValue("physicalHeight", 6);
            runtime.applyControlValue("targetPixelsPerUnit", 4);
            runtime.applyControlValue("maxUpsamplePercent", 100);
            runtime.applyControlValue("scaleMode", "Pixels");
            runtime.applyControlValue("format", "PNG");
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportCrops");

            testCase.verifyTrue(isfile(manifestPath));
            testCase.verifyNumElements(dir(fullfile(outputFolder, "*_crop*.png")), 3);
            testCase.verifyEqual( ...
                runtime.State.project.results.resultManifestPath, ...
                string(manifestPath));
            runtime.invokeAction("restoreManifest");
            testCase.verifyNumElements(runtime.State.project.inputs.items, 3);
            testCase.verifyNotEmpty(preview.Children);
            testCase.verifyEqual(runtime.State.project.parameters.cropWidth, 30);
            clear cleanup
        end
    end
end

function imageData = syntheticImage(height, width, offset)
[x, y] = meshgrid(1:width, 1:height);
imageData = uint8(cat(3, ...
    mod(3 .* x + offset, 255), ...
    mod(5 .* y + offset, 255), ...
    mod(2 .* x + 3 .* y + offset, 255)));
end

function unexpectedAlert(message, title)
error("batch_crop:test:UnexpectedAlert", "%s: %s", title, message);
end
