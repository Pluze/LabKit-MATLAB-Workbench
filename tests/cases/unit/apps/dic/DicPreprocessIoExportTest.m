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

        function runtimeV2ProjectSessionAndPresenterContracts(testCase)
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
            testCase.verifyEqual(definition.contractVersion, 2);
            project = definition.project.Create();
            project.inputs.sources = [sourceRecord( ...
                "referenceImage", "reference", referencePath); ...
                sourceRecord("movingImage", "moving", movingPath)];
            project.annotations.editSteps = struct( ...
                "kind", "crop", "transform", [], ...
                "rect", [1 1 2 2], "description", "crop");

            testCase.verifyTrue(definition.project.Validate(project));
            testCase.verifyEmpty(definition.project.Migrations, ...
                'Payload version 1 should not invent a legacy migration.');
            testCase.verifyFalse(hasDurableImagePixels(project), ...
                'Decoded and derived image pixels belong to session cache.');

            session = dic_preprocess.appLifecycle.createSession(project);
            testCase.verifyEqual(session.cache.referenceImage, reference);
            testCase.verifyEqual(session.cache.movingImage, moving);
            testCase.verifySize(session.cache.currentReferenceImage, [3 3 3]);
            state = struct('project', project, 'session', session);
            presentation = dic_preprocess.userInterface.presentWorkbench(state);
            testCase.verifyTrue(isscalar(presentation));
            testCase.verifyNotEmpty( ...
                presentation.previews.previewAxes.Axes.reference.Model.imageData);
            testCase.verifyNotEmpty( ...
                presentation.previews.previewAxes.Axes.current.Model.imageData);
            testCase.verifyFalse(isfield(presentation, 'interactions'), ...
                'Idle presentation should not construct an interaction runtime.');
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
