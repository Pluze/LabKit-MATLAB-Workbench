classdef ImageEnhanceResultSpec < matlab.unittest.TestCase
    %IMAGEENHANCERESULTSPEC Specify enhanced output and task identity.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function avoidsOverwritingAndKeepsTheFullResolutionOutput(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            path = fullfile(folder, "sample.png");
            imwrite(uint8(120 .* ones(10, 12, 3)), path);
            imwrite(uint8(255 .* ones(5, 5, 3)), fullfile(folder, "sample_enhanced.png"));
            item = image_enhance.sourceFiles.readImages(string(path));
            steps = image_enhance.analysisRun.makeStep("Brightness/contrast", 5, 0, 0);

            payload = image_enhance.resultFiles.writeOutputs(item, steps, struct( ...
                "outputFolder", folder, "format", "PNG"));

            testCase.verifyTrue(endsWith(payload.results(1).outputPath, "sample_enhanced_001.png"));
            testCase.verifySize(imread(payload.results(1).outputPath), [10 12 3]);
            testCase.verifyTrue(isfile(payload.manifestPath));
        end

        function fingerprintChangesWhenTheDestinationOrStepsChange(testCase)
            item = image_enhance.sourceFiles.emptyItem();
            item.path = "sample.png";
            item.name = "sample.png";
            item.image = syntheticImage();
            baseStep = image_enhance.analysisRun.makeStep("Brightness/contrast", 5, 0, 0);
            base = image_enhance.resultFiles.exportTask(item, baseStep, ...
                struct("outputFolder", "out_a", "format", "PNG"));
            moved = image_enhance.resultFiles.exportTask(item, baseStep, ...
                struct("outputFolder", "out_b", "format", "PNG"));
            changed = image_enhance.resultFiles.exportTask(item, ...
                image_enhance.analysisRun.makeStep("Brightness/contrast", 6, 0, 0), ...
                struct("outputFolder", "out_a", "format", "PNG"));

            testCase.verifyNotEqual(base.fingerprint, moved.fingerprint);
            testCase.verifyNotEqual(base.fingerprint, changed.fingerprint);
        end
    end
end

function image = syntheticImage()
image = repmat(linspace(.2, .8, 24), 18, 1);
image = cat(3, image, image, image);
end
