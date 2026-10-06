classdef ImageMatchWorkflowSpec < matlab.unittest.TestCase
    %IMAGEMATCHWORKFLOWSPEC Specify reference matching through the workbench.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function loadsMatchesExportsAndRestoresSyntheticImages(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            reference = fullfile(folder, "reference.png");
            source = fullfile(folder, "source.png");
            writeImages(reference, source);
            backend = struct( ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            definition = image_match.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("referenceImage", string(reference), 1);
            runtime.applyFileSelection("sourceImages", string(source), 1);
            % Oracle: the documented scientific modes must survive the native
            % selector and history commit; silently replacing them fails here.
            methods = ["Balanced", "White balance", "Tone only", ...
                "Protected tone", "Lab style", "Histogram"];
            selector = findall(figureValue, "Tag", "matchMethod");
            testCase.verifyEqual(string(selector.Items), methods);
            for method = methods
                runtime.applyControlValue("matchMethod", method);
                runtime.invokeAction("applyMatch");
                testCase.verifyEqual( ...
                    runtime.State.project.annotations.steps(end).matchMethod, method);
                runtime.invokeAction("undoHistory");
            end
            runtime.applyControlValue("matchMethod", "Tone only");
            runtime.applyControlValue("matchStrength", 80);
            runtime.applyControlValue("toneStrength", 70);
            runtime.applyControlValue("colorStrength", 60);
            runtime.invokeAction("applyMatch");
            runtime.invokeAction("undoHistory");
            testCase.verifyEmpty(runtime.State.project.annotations.steps);
            runtime.invokeAction("applyMatch");
            runtime.applyControlValue("preview", "Before | After");
            runtime.applyControlValue("exportFormat", "JPEG");
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportImages");

            testCase.verifyNumElements(runtime.State.project.annotations.steps, 1);
            testCase.verifyEqual(runtime.State.session.view.previewMode, ...
                "Before | After");
            testCase.verifyEqual(runtime.State.project.parameters.exportFormat, ...
                "JPEG");
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.image").Children);
            manifestPath = fullfile(folder, "image_match_manifest.csv");
            manifest = readtable(manifestPath, TextType="string", Delimiter=",", ReadVariableNames=true);
            testCase.verifyEqual(height(manifest), 1);
            firstExport = manifest.OutputImage(1);
            firstPixels = imread(firstExport);
            runtime.applyFilePanelSelection("sourceImages", 1);
            testCase.verifyEqual(runtime.State.project.results.resultManifestPath, string(manifestPath));
            imwrite(zeros(32, 48, 3, "uint8"), reference);
            runtime.invokeAction("exportImages");
            manifest = readtable(fullfile(folder, "image_match_manifest_001.csv"), TextType="string", Delimiter=",", ReadVariableNames=true);
            secondExport = manifest.OutputImage(1);
            testCase.verifyNotEqual(imread(secondExport), firstPixels);
            delete(secondExport);
            runtime.invokeAction("exportImages");
            testCase.verifyTrue(isfile(secondExport));
            runtime.applyFileSelection("referenceImage", string(source), 1);
            testCase.verifyEqual(runtime.State.project.results.resultManifestPath, "");
            runtime.invokeAction("resetHistory");
            testCase.verifyEmpty(runtime.State.project.annotations.steps);
            clear cleanup
        end
    end
end

function writeImages(referencePath, sourcePath)
[x, y] = meshgrid(linspace(0, 1, 48), linspace(0, 1, 32));
reference = uint8(255 .* cat(3, x, .4 + .6 .* y, .2 + .8 .* (1 - x)));
source = uint8(255 .* cat(3, .3 + .7 .* x, y, .7 .* (1 - x)));
imwrite(reference, referencePath);
imwrite(source, sourcePath);
end
