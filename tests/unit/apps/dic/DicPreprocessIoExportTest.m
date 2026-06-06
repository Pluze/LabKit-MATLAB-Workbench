classdef DicPreprocessIoExportTest < matlab.unittest.TestCase
    %DICPREPROCESSIOEXPORTTEST Verify DIC preprocess IO/export helpers.

    methods (Test, TestTags = {'Unit'})
        function defaultPathsUseReferenceThenMovingThenFallback(testCase)
            setupLabKitTestPath();

            folder = fullfile(tempdir, 'dic_preprocess_test');

            fromReference = dic_preprocess.io.defaultSaveFolder( ...
                fullfile(folder, 'reference.png'), ...
                fullfile(tempdir, 'moving.png'), tempdir);
            fromMoving = dic_preprocess.io.defaultSaveFolder( ...
                "", fullfile(folder, 'moving.png'), tempdir);
            fromFallback = dic_preprocess.io.defaultSaveFolder("", "", folder);
            maskPath = dic_preprocess.io.defaultMaskPath( ...
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
            cleanup = onCleanup(@() cleanupFolder(outDir)); %#ok<NASGU>
            reference = uint8([0 10; 20 30]);
            moving = uint8([30 20; 10 0]);
            mask = uint8([0 255; 255 0]);

            outputs = dic_preprocess.export.writeCurrentImages( ...
                reference, moving, outDir);
            maskPath = dic_preprocess.export.writeMask(mask, ...
                fullfile(outDir, 'mask.png'));

            testCase.verifyTrue(isfile(outputs.referencePath));
            testCase.verifyTrue(isfile(outputs.movingPath));
            testCase.verifyTrue(isfile(maskPath));
            testCase.verifyEqual(imread(outputs.referencePath), reference);
            testCase.verifyEqual(imread(outputs.movingPath), moving);
            testCase.verifyEqual(imread(maskPath), mask);
        end
    end
end

function cleanupFolder(folder)
    if isfolder(folder)
        rmdir(folder, 's');
    end
end
