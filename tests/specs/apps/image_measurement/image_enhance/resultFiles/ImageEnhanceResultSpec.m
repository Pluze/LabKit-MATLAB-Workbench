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

        function writesPerImageHistoriesAndTheStableManifestSchema(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            first = fullfile(folder, "first.png");
            second = fullfile(folder, "second.png");
            imwrite(uint8(80 .* ones(8, 9, 3)), first);
            imwrite(uint8(120 .* ones(8, 9, 3)), second);
            items = image_enhance.sourceFiles.readImages([string(first); string(second)]);
            steps = { ...
                image_enhance.analysisRun.makeStep("Brightness/contrast", 20, 0, 0); ...
                image_enhance.analysisRun.makeStep("Brightness/contrast", -20, 0, 0)};

            payload = image_enhance.resultFiles.writeOutputs(items, ...
                repmat(image_enhance.analysisRun.emptyStep(), 0, 1), struct( ...
                "outputFolder", folder, "format", "PNG", "itemSteps", {steps}));
            manifest = image_enhance.resultFiles.buildManifest(payload.results);
            firstWritten = labkit.image.im2double(imread(payload.results(1).outputPath));
            secondWritten = labkit.image.im2double(imread(payload.results(2).outputPath));

            testCase.verifyEqual(string(manifest.Properties.VariableNames), ...
                ["SourceImage", "OutputImage", "Status", "Width_px", ...
                 "Height_px", "StepCount", "Message"]);
            testCase.verifyEqual(manifest.StepCount, [1; 1]);
            testCase.verifyGreaterThan(mean(firstWritten, "all"), mean(items(1).image, "all"));
            testCase.verifyLessThan(mean(secondWritten, "all"), mean(items(2).image, "all"));
        end
    end
end

function image = syntheticImage()
image = repmat(linspace(.2, .8, 24), 18, 1);
image = cat(3, image, image, image);
end
