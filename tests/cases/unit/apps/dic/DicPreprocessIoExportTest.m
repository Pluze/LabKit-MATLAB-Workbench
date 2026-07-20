classdef DicPreprocessIoExportTest < matlab.unittest.TestCase
    %DICPREPROCESSIOEXPORTTEST Verify DIC preprocess IO/export helpers.

    methods (Test, TestTags = {'Unit'})
        function defaultPathsUseReferenceThenMovingThenFallback(testCase)
            setupLabKitTestPath();

            folder = fullfile(tempdir, 'dic_preprocess_test');

            fromReference = dic_preprocess.sourceFiles.defaultSaveFolder( ...
                fullfile(folder, 'reference.png'), ...
                fullfile(tempdir, 'moving.png'), tempdir);
            fromMoving = dic_preprocess.sourceFiles.defaultSaveFolder( ...
                "", fullfile(folder, 'moving.png'), tempdir);
            fromFallback = dic_preprocess.sourceFiles.defaultSaveFolder("", "", folder);
            maskPath = dic_preprocess.sourceFiles.defaultMaskPath( ...
                fullfile(folder, 'reference.tif'), tempdir);

            testCase.verifyEqual(fromReference, folder);
            testCase.verifyEqual(fromMoving, folder);
            testCase.verifyEqual(fromFallback, folder);
            testCase.verifyEqual(maskPath, fullfile(folder, 'reference_roi_mask.png'));
        end

        function writeCurrentImagesAndMaskCreatePngOutputs(testCase)
            setupLabKitTestPath();

            outDir = tempname;
            mkdir(outDir);
            cleanup = onCleanup(@() cleanupFolder(outDir));
            reference = uint8([0 10; 20 30]);
            moving = uint8([30 20; 10 0]);
            mask = uint8([0 255; 255 0]);

            outputs = dic_preprocess.resultFiles.writeCurrentImages( ...
                reference, moving, outDir);
            maskPath = dic_preprocess.resultFiles.writeMask(mask, ...
                fullfile(outDir, 'mask.png'));

            testCase.verifyTrue(isfile(outputs.referencePath));
            testCase.verifyTrue(isfile(outputs.movingPath));
            testCase.verifyTrue(isfile(maskPath));
            testCase.verifyEqual(imread(outputs.referencePath), reference);
            testCase.verifyEqual(imread(outputs.movingPath), moving);
            testCase.verifyEqual(imread(maskPath), mask);
        end

        function appSdkProjectSessionAndPresenterContracts(testCase)
            setupLabKitTestPath();

            folder = string(tempname);
            mkdir(folder);
            cleanup = onCleanup(@() cleanupFolder(folder));
            referencePath = fullfile(folder, "reference.png");
            movingPath = fullfile(folder, "moving.png");
            reference = uint8(reshape(1:48, [4 4 3]));
            moving = uint8(reshape(48:-1:1, [4 4 3]));
            imwrite(reference, referencePath);
            imwrite(moving, movingPath);

            definition = dic_preprocess.definition();
            project = definition.ProjectSchema.Create();
            project.inputs.sources = [sourceRecord( ...
                "referenceImage", "referenceImage", referencePath); ...
                sourceRecord("movingImage", "movingImage", movingPath)];
            project.annotations.editSteps = struct( ...
                "kind", "crop", "transform", [], ...
                "rect", [1 1 2 2], "description", "crop");

            testCase.verifyTrue(definition.ProjectSchema.Validate(project));
            testCase.verifyEmpty(definition.ProjectSchema.Migrate, ...
                'Payload version 1 should not invent a migration callback.');
            testCase.verifyFalse(hasDurableImagePixels(project), ...
                'Decoded and derived image pixels belong to session cache.');

            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, project);
            runtimeCleanup = onCleanup(@() runtime.close());
            session = runtime.State.session;
            testCase.verifyEqual(session.cache.referenceImage, reference);
            testCase.verifyEqual(session.cache.movingImage, moving);
            testCase.verifySize(session.cache.currentReferenceImage, [3 3 3]);
            presentation = runtime.Presentation;
            testCase.verifyClass(presentation, "labkit.app.view.Snapshot");
            testCase.verifyTrue( ...
                definition.validateViewSnapshot(presentation));
            clear runtimeCleanup
        end
    end
end

function source = sourceRecord(id, role, filepath)
    [~, name, extension] = fileparts(filepath);
    source = struct( ...
        "id", string(id), ...
        "required", true, ...
        "role", string(role), ...
        "reference", struct( ...
            "schemaVersion", 1, ...
            "relativePath", "", ...
            "originalPath", string(filepath), ...
            "fileName", string(name) + string(extension)));
end

function tf = hasDurableImagePixels(project)
    forbidden = ["referenceImage", "movingImage", ...
        "currentReferenceImage", "currentMovingImage", "alignedImage"];
    tf = any(isfield(project.inputs, cellstr(forbidden)));
end

function cleanupFolder(folder)
    if isfolder(folder)
        rmdir(folder, 's');
    end
end
