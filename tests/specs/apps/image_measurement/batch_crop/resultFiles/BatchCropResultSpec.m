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
                ["SourceImage" "OutputImage" "Status" "TaskIndex" "RotationDeg" ...
                 "PaddingPercent" "CenterX_px" "CenterY_px" "CropWidth_px" ...
                 "CropHeight_px" "SourceWidth_px" "SourceHeight_px" ...
                 "ScaleMode" "ScaleUnit" "SourcePixelsPerUnit" ...
                 "TargetPixelsPerUnit" "ResampleFactor" "NativeCropWidth_px" ...
                 "NativeCropHeight_px" "OutputWidth_px" "OutputHeight_px" ...
                 "PhysicalWidth" "PhysicalHeight" "MaxUpsamplePercent" ...
                 "OutputFormat" "ScaleWarning" "Message"]);
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

        function exportsEveryPhysicalCropAtOneDeclaredOutputSize(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            items = [physicalItem(fullfile(folder, "source_a.png"), 4); ...
                physicalItem(fullfile(folder, "source_b.png"), 8)];

            payload = batch_crop.resultFiles.writeOutputs(items, struct( ...
                "outputFolder", folder, "format", "PNG", ...
                "cropWidth", 10, "cropHeight", 10, "paddingPercent", 0, ...
                "scaleMode", "Physical", "physicalWidth", 10, ...
                "physicalHeight", 5, "scaleUnit", "um", ...
                "targetPixelsPerUnit", 0, "maxUpsamplePercent", 15));

            first = imread(payload.results(1).outputPath);
            second = imread(payload.results(2).outputPath);
            testCase.verifySize(first, [30 60]);
            testCase.verifySize(second, [30 60]);
            testCase.verifyEqual([payload.results.nativeCropWidth], [40 80]);
            testCase.verifyTrue(contains(payload.results(1).scaleWarning, "upsample"));
            testCase.verifyEqual(payload.manifest.OutputWidth_px, [60; 60]);
        end

        function givesDuplicateSourceTasksDistinctOutputsAndManifestRows(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            items = repmat(batch_crop.sourceFiles.emptyItem(), 2, 1);
            for k = 1:2
                items(k).path = fullfile(folder, "shared_source.png");
                items(k).image = uint8(20 .* ones(8));
                items(k).centerXY = [3 + 3 * (k - 1), 3];
                items(k).centerSet = true;
            end

            payload = batch_crop.resultFiles.writeOutputs(items, struct( ...
                "outputFolder", folder, "format", "PNG", "cropWidth", 4, ...
                "cropHeight", 4, "paddingPercent", 0));
            outputs = string({payload.results.outputPath});

            testCase.verifyEqual(numel(unique(outputs)), 2);
            testCase.verifyTrue(endsWith(outputs(1), "shared_source_crop.png"));
            testCase.verifyTrue(endsWith(outputs(2), "shared_source_crop_001.png"));
            testCase.verifyEqual(height(payload.manifest), 2);
        end

        function restoresExactPhysicalTasksFromCurrentManifest(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            items = [physicalItem(fullfile(folder, "source_a.png"), 4); ...
                physicalItem(fullfile(folder, "source_b.png"), 8)];
            imwrite(items(1).image, items(1).path);
            imwrite(items(2).image, items(2).path);
            options = struct( ...
                "outputFolder", folder, "format", "TIFF", ...
                "cropWidth", 10, "cropHeight", 10, "paddingPercent", 0, ...
                "scaleMode", "Physical", "physicalWidth", 7.5, ...
                "physicalHeight", 4.25, "scaleUnit", "um", ...
                "targetPixelsPerUnit", 6, "maxUpsamplePercent", 22);
            items(1).angleDeg = 12;
            items(1).paddingPercent = 15;
            payload = batch_crop.resultFiles.writeOutputs(items, options);

            plan = batch_crop.resultFiles.readManifest(payload.manifestPath);

            testCase.verifyEqual(plan.paths, string({items.path}).');
            testCase.verifyEqual([plan.tasks.angleDeg], [12 0]);
            testCase.verifyEqual([plan.tasks.paddingPercent], [15 0]);
            testCase.verifyEqual([plan.tasks.centerSet], [true true]);
            calibrations = [plan.tasks.scaleCalibration];
            testCase.verifyEqual( ...
                [calibrations.pixelsPerUnit], [4 8]);
            testCase.verifyEqual(plan.parameters.scaleMode, "Physical");
            testCase.verifyEqual(plan.parameters.physicalWidth, 7.5);
            testCase.verifyEqual(plan.parameters.physicalHeight, 4.25);
            testCase.verifyEqual(plan.parameters.targetPixelsPerUnit, 6);
            testCase.verifyEqual(plan.parameters.maxUpsamplePercent, 22);
            testCase.verifyEqual(plan.parameters.format, "TIFF");
        end

        function rejectsManifestWhenSourceDimensionsChanged(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            item = batch_crop.sourceFiles.emptyItem();
            item.path = fullfile(folder, "source.png");
            item.image = uint8(ones(8, 9));
            item.centerXY = [5 4];
            item.centerSet = true;
            imwrite(item.image, item.path);
            payload = batch_crop.resultFiles.writeOutputs(item, struct( ...
                "outputFolder", folder, "format", "PNG", ...
                "cropWidth", 4, "cropHeight", 4, "paddingPercent", 0));
            imwrite(uint8(ones(7, 9)), item.path);

            testCase.verifyError( ...
                @() batch_crop.resultFiles.readManifest(payload.manifestPath), ...
                "batch_crop:ManifestSourceChanged");
        end

        function restoresOnlySuccessfullySavedFinalRows(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            item = batch_crop.sourceFiles.emptyItem();
            item.path = fullfile(folder, "saved_source.png");
            item.image = uint8(ones(8, 9));
            item.centerXY = [5 4];
            item.centerSet = true;
            imwrite(item.image, item.path);
            payload = batch_crop.resultFiles.writeOutputs(item, struct( ...
                "outputFolder", folder, "format", "PNG", ...
                "cropWidth", 4, "cropHeight", 4, "paddingPercent", 0, ...
                "maxUpsamplePercent", 15));
            failed = payload.manifest;
            failed.Status = "failed";
            failed.TaskIndex = 2;
            failed.SourceImage = fullfile(folder, "missing.png");
            final = [payload.manifest; failed];
            finalPath = fullfile(folder, "final_manifest.csv");
            writetable(final, finalPath);

            plan = batch_crop.resultFiles.readManifest(finalPath);

            testCase.verifyEqual(numel(plan.tasks), 1);
            testCase.verifyEqual(plan.paths, string(item.path));
        end

        function rejectsManifestMissingARequiredColumn(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            crop = batch_crop.cropGeometry.cropImage(uint8(ones(5, 6)), struct( ...
                "cropWidth", 3, "cropHeight", 4, "centerXY", [3 3]));
            crop.sourcePath = fullfile(folder, "source.png");
            crop.outputPath = fullfile(folder, "source_crop.png");
            crop.status = "saved";
            incomplete = removevars( ...
                batch_crop.resultFiles.buildManifest(crop), "TaskIndex");
            incompletePath = fullfile(folder, "incomplete_manifest.csv");
            writetable(incomplete, incompletePath);

            testCase.verifyError( ...
                @() batch_crop.resultFiles.readManifest(incompletePath), ...
                "batch_crop:InvalidManifest");
        end
    end
end

function item = physicalItem(path, pixelsPerUnit)
item = batch_crop.sourceFiles.emptyItem();
item.path = string(path);
item.image = uint8(80 .* ones(120, 120));
item.centerXY = [60 60];
item.centerSet = true;
item.scaleCalibration = labkit.app.interaction.scaleCalibration( ...
    pixelsPerUnit, 1, "um", struct("defaultUnit", "um", ...
    "referenceLine", [1 1; 1 + pixelsPerUnit 1]));
end
