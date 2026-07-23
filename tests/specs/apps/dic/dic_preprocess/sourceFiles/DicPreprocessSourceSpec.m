classdef DicPreprocessSourceSpec < matlab.unittest.TestCase
    %DICPREPROCESSSOURCESPEC Specify source-path and pair availability rules.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function derivesSaveAndMaskPathsFromTheFirstAvailableImage(testCase)
            folder = fullfile(tempdir, 'dic_preprocess_test');
            fromReference = dic_preprocess.sourceFiles.defaultSaveFolder( ...
                fullfile(folder, 'reference.png'), fullfile(tempdir, 'moving.png'), tempdir);
            fromMoving = dic_preprocess.sourceFiles.defaultSaveFolder( ...
                "", fullfile(folder, 'moving.png'), tempdir);
            mask = dic_preprocess.sourceFiles.defaultMaskPath( ...
                fullfile(folder, 'reference.tif'), tempdir);
            cache = struct("currentReferenceImage", uint8(1), ...
                "currentMovingImage", uint8(2));

            testCase.verifyEqual(fromReference, folder);
            testCase.verifyEqual(fromMoving, folder);
            testCase.verifyEqual(mask, fullfile(folder, 'reference_roi_mask.png'));
            testCase.verifyTrue(dic_preprocess.sourceFiles.hasImagePair(cache));
        end
    end
end
