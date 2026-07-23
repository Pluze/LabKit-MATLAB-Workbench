classdef ImageMatchResultSpec < matlab.unittest.TestCase
    %IMAGEMATCHRESULTSPEC Specify reference-bound output and task identity.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function exportsOnlySourcesAndAvoidsAnExistingOutputName(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            sourcePath = fullfile(folder, "sample.png");
            referencePath = fullfile(folder, "reference.png");
            imwrite(uint8(120 .* ones(10, 12, 3)), sourcePath);
            imwrite(uint8(180 .* ones(10, 12, 3)), referencePath);
            imwrite(uint8(255 .* ones(5, 5, 3)), fullfile(folder, "sample_matched.png"));
            source = image_match.sourceFiles.readImages(string(sourcePath));
            reference = image_match.sourceFiles.readImages(string(referencePath));
            steps = image_match.analysisRun.makeStep("Balanced", 100, 100, 100);

            payload = image_match.resultFiles.writeOutputs(source, reference, steps, ...
                struct("outputFolder", folder, "format", "PNG"));

            testCase.verifyEqual(numel(payload.results), 1);
            testCase.verifyTrue(endsWith(payload.results.outputPath, "sample_matched_001.png"));
            testCase.verifySize(imread(payload.results.outputPath), [10 12 3]);
            testCase.verifyTrue(isfile(payload.manifestPath));
        end

        function fingerprintIncludesReferenceAndStepIdentity(testCase)
            source = item("source.png", .4);
            reference = item("reference.png", .7);
            step = image_match.analysisRun.makeStep("Balanced", 100, 100, 100);
            base = image_match.resultFiles.exportTask(source, reference, step, ...
                struct("outputFolder", "out", "format", "PNG"));
            changedReference = reference;
            changedReference.path = "reference-b.png";
            changed = image_match.resultFiles.exportTask(source, changedReference, step, ...
                struct("outputFolder", "out", "format", "PNG"));

            testCase.verifyNotEqual(base.fingerprint, changed.fingerprint);
        end
    end
end

function value = item(path, intensity)
value = image_match.sourceFiles.emptyItem();
value.path = path;
value.name = path;
value.image = intensity .* ones(12, 14, 3);
end
