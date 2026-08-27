classdef ImageEnhanceWorkflowSpec < matlab.unittest.TestCase
    %IMAGEENHANCEWORKFLOWSPEC Specify the image-to-enhanced-export journey.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function importsEditsUndoesAndExportsProductionImages(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourceFolder = fullfile(folder, "source");
            outputFolder = fullfile(folder, "output");
            mkdir(sourceFolder);
            sourcePath = fullfile(sourceFolder, "paper.png");
            [x, y] = meshgrid(1:72, 1:54);
            sourceImage = uint8(cat(3, mod(3*x + y, 255), ...
                mod(x + 4*y, 255), mod(2*x + 2*y, 255)));
            imwrite(sourceImage, sourcePath);
            backend = struct( ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(outputFolder), ...
                "alert", @(message, title) unexpectedAlert(message, title));
            definition = image_enhance.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyFileSelection("sourceImages", string(sourcePath), 1);
            testCase.verifyFalse(runtime.StartupFailed);
            expectedSource = double(sourceImage) ./ 255;
            testCase.verifyEqual(runtime.State.session.cache.item.image, ...
                expectedSource, AbsTol=1/255);
            preview = findall(runtime.figureHandle(), "Tag", "preview.image");
            testCase.verifyNotEmpty(preview.Children);

            amountLabel = findall( ...
                runtime.figureHandle(), "Tag", "toolAmount.label");
            secondaryLabel = findall( ...
                runtime.figureHandle(), "Tag", "toolSecondary.label");
            toolKinds = image_enhance.enhancementPipeline.toolKinds();
            expectedAmountLabels = [ ...
                "Brightness (%):" "Clarity (%):" "Sharpen (%):" ...
                "Hue (deg):" "Strength (%):" "Strength (%):" ...
                "Strength (%):"];
            expectedSecondaryLabels = [ ...
                "Contrast (%):" "Radius (px):" "Radius (px):" ...
                "Saturation (%):" "Temp (%):" "White target (%):" ...
                "Background target (%):"];
            for index = 1:numel(toolKinds)
                runtime.applyControlValue("toolKind", toolKinds(index));
                testCase.verifyEqual( ...
                    string(amountLabel.Text), expectedAmountLabels(index));
                testCase.verifyEqual( ...
                    string(secondaryLabel.Text), ...
                    expectedSecondaryLabels(index));
            end

            runtime.applyControlValue("batchMode", false);
            runtime.applyControlValue("toolKind", "Brightness/contrast");
            runtime.applyControlValue("toolAmount", 18);
            runtime.applyControlValue("toolSecondary", 24);
            runtime.invokeAction("applyTool");
            testCase.verifyNumElements( ...
                runtime.State.project.annotations.items(1).steps, 1);
            changedPreview = runtime.State.session.cache.previewResult;
            testCase.verifyNotEqual(changedPreview, expectedSource);

            runtime.applyControlValue("toolKind", "White ROI calibration");
            runtime.invokeAction("setWhiteRoi");
            runtime.applyInteraction("whiteRoi", "interactionChanged", [3 4 18 16]);
            testCase.verifyEqual( ...
                runtime.State.project.annotations.items(1).whiteRoi, [3 4 18 16]);
            runtime.invokeAction("applyTool");
            testCase.verifyNumElements( ...
                runtime.State.project.annotations.items(1).steps, 2);
            runtime.invokeAction("undoHistory");
            testCase.verifyNumElements( ...
                runtime.State.project.annotations.items(1).steps, 1);
            runtime.applyControlValue("preview", "Before | After");
            testCase.verifyEqual(runtime.State.session.view.previewMode, ...
                "Before | After");

            runtime.applyControlValue("exportFormat", "PNG");
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportImages");
            testCase.verifyTrue(isfile(fullfile(outputFolder, "paper_enhanced.png")));
            testCase.verifyTrue(isfile(fullfile(outputFolder, ...
                "image_enhance_manifest.csv")));
            testCase.verifyNotEmpty( ...
                runtime.State.project.results.resultManifestPath);
            runtime.invokeAction("resetHistory");
            testCase.verifyEmpty( ...
                runtime.State.project.annotations.items(1).steps);
            clear cleanup
        end
    end
end

function unexpectedAlert(message, title)
error("image_enhance:test:UnexpectedAlert", "%s: %s", title, message);
end
