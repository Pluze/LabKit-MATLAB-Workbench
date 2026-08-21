classdef ImageMatchWorkflowSpec < matlab.unittest.TestCase
    %IMAGEMATCHWORKFLOWSPEC Specify reference matching through the workbench.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
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
            runtime.invokeAction("applyMatch");
            runtime.invokeAction("exportImages");

            testCase.verifyNumElements(runtime.State.project.annotations.steps, 1);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview.image").Children);
            payload = runtime.State.project.results.lastExport;
            testCase.verifyEqual(numel(payload.results), 1);
            testCase.verifyTrue(isfile(payload.results(1).outputPath));
            testCase.verifyTrue(isfile(payload.resultManifestPath));
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
