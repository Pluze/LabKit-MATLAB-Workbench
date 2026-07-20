classdef GuiLayoutBatchCropTest < matlab.unittest.TestCase
    % Verify Batch Crop through the explicit App SDK runtime.
    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutUsesSemanticTargets(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            backend = struct("alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                batch_crop.definition(), [], backend);
            cleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();
            ids = ["images", "duplicateImage", ...
                "cropWidth", "rotation", "centerX", ...
                "measureScaleReference", "scaleReferencePixels", ...
                "placeScaleBar", "exportCrops", "resultTable", ...
                "preview"];
            for id = ids
                testCase.verifyEqual(numel(findall( ...
                    figure, "Tag", id)), 1);
            end
            tabs = findall(figure, "Type", "uitab");
            testCase.verifyEqual(sort(string({tabs.Title})), ...
                sort(["Files + Analysis", "Scale", ...
                      "Summary + Results", "Log"]));
            for id = ["cropWidth", "cropHeight", "rotation", ...
                    "paddingPercent", "centerX", "centerY", ...
                    "physicalWidth", "physicalHeight", ...
                    "targetPixelsPerUnit", "maxUpsamplePercent", ...
                    "scaleReferencePixels", "scaleReferenceLength", ...
                    "scaleBarLength"]
                testCase.verifyEqual(numel(findall( ...
                    figure, "Tag", id + ".slider")), 1);
            end
            testCase.verifyEqual(string(component( ...
                figure, "images.choose").Text), "Add images or folder");
            testCase.verifyEqual(string(component( ...
                figure, "images.folder").Text), "Add folder");
            testCase.verifyEqual(string(component( ...
                figure, "images.recursiveFolder").Text), "Add folder tree");
            testCase.verifyEqual(string(component( ...
                figure, "images.remove").Text), "Remove selected");
            testCase.verifyEqual(string(component( ...
                figure, "images.clear").Text), "Clear images");
            panelTitles = string({findall(figure, "Type", "uipanel").Title});
            testCase.verifyTrue(all(ismember( ...
                ["Crop images", "Scale Mode", "Current Image Scale", ...
                 "Summary", "Batch Results", "Details", "Crop Preview", ...
                 "Padded rotation preview + fixed crop"], panelTitles)));
            testCase.verifyClass(component(figure, "imageSource"), ...
                "matlab.ui.control.TextArea");
            testCase.verifyEqual(string( ...
                component(figure, "imageSource").Editable), "off");
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
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                batch_crop.definition(), [], backend);
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
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 2);
            testCase.verifyNotEqual(string( ...
                runtime.State.project.inputs.sources(1).id), string( ...
                runtime.State.project.inputs.sources(2).id));
            labels = string(component(figure, "images").Items);
            testCase.verifyEqual(numel(labels), 2);
            testCase.verifyTrue(startsWith(labels(1), "01 source.png"));
            testCase.verifyTrue(endsWith(labels(1), "[ready]"));
            testCase.verifyTrue(startsWith(labels(2), "02 source.png"));
            testCase.verifyTrue(endsWith(labels(2), "[needs center]"));
            testCase.verifyEqual( ...
                runtime.State.session.selection.currentIndex, 2);
            runtime.invokeAction("previousImage");
            testCase.verifyEqual( ...
                runtime.State.session.selection.currentIndex, 1);
            testCase.verifyEqual(string(component(figure, "images").Value), ...
                string(component(figure, "images").Items(1)));
            runtime.invokeAction("nextImage");
            remove = component(figure, "images.remove");
            remove.ButtonPushedFcn(remove, struct());
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.items), 1);
            testCase.verifyEqual(numel( ...
                runtime.State.project.inputs.sources), 1);
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

            runtime.applyControlValue("scaleMode", "Physical");
            testCase.verifyEqual(string(component( ...
                figure, "physicalWidth").Enable), "on");
            runtime.invokeAction("measureScaleReference");
            testCase.verifyEqual(string(component( ...
                figure, "measureScaleReference").Text), ...
                "Finish reference edit");
            runtime.invokeAction("measureScaleReference");
            runtime.applyControlValue("scaleReferencePixels", 20);
            runtime.applyControlValue("scaleReferenceLength", 10);
            testCase.verifyTrue(runtime.State.project.inputs.items(2) ...
                .scaleCalibration.isCalibrated);
            testCase.verifyTrue(endsWith(string(component( ...
                figure, "images").Items(2)), "[ready]"));
            runtime.applyControlValue("scaleMode", "Pixels");

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

function value = component(figure, id)
matches = findall(figure, "Tag", id);
assert(numel(matches) == 1, ...
    'Expected one component with tag %s.', id);
value = matches(1);
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
