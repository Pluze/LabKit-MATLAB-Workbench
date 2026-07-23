classdef BatchCropResultSpec < matlab.unittest.TestCase
    %BATCHCROPRESULTSPEC Specify crop result metadata and collision avoidance.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function emitsTheStableManifestColumns(testCase)
            crop = batch_crop.cropGeometry.cropImage(uint8(ones(5, 6)), struct( ...
                "cropWidth", 3, "cropHeight", 4, "centerXY", [3 3], "angleDeg", 0));
            crop.sourcePath = "source.png";
            crop.outputPath = "source_crop.png";
            crop.status = "saved";
            crop.message = "Saved";

            manifest = batch_crop.resultFiles.buildManifest(crop);

            testCase.verifyEqual(height(manifest), 1);
            testCase.verifyEqual(string(manifest.Properties.VariableNames), ...
                ["SourceImage" "OutputImage" "Status" "RotationDeg" ...
                 "PaddingPercent" "CenterX_px" "CenterY_px" "CropWidth_px" ...
                 "CropHeight_px" "SourceWidth_px" "SourceHeight_px" ...
                 "ScaleMode" "ScaleUnit" "SourcePixelsPerUnit" ...
                 "TargetPixelsPerUnit" "ResampleFactor" "NativeCropWidth_px" ...
                 "NativeCropHeight_px" "OutputWidth_px" "OutputHeight_px" ...
                 "ScaleWarning" "Message"]);
        end

        function avoidsOverwritingAnExistingCropOutput(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            imwrite(uint8(zeros(4)), fullfile(folder, "sample_crop.png"));
            item = batch_crop.sourceFiles.emptyItem();
            item.path = fullfile(folder, "sample.png");
            item.image = uint8(20 .* ones(6));
            item.centerXY = [3 3];
            item.centerSet = true;

            payload = batch_crop.resultFiles.writeOutputs(item, struct( ...
                "outputFolder", folder, "format", "PNG", "cropWidth", 4, ...
                "cropHeight", 4, "paddingPercent", 0));

            testCase.verifyTrue(endsWith(payload.results(1).outputPath, "sample_crop_001.png"));
            testCase.verifyTrue(isfile(payload.results(1).outputPath));
            testCase.verifyTrue(isfile(payload.manifestPath));
        end
    end
end
