classdef DicPreprocessSourceSpec < matlab.unittest.TestCase
    %DICPREPROCESSSOURCESPEC Specify source-path and pair availability rules.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function detectsAnAvailableImagePair(testCase)
            cache = struct("currentReferenceImage", uint8(1), ...
                "currentMovingImage", uint8(2));

            testCase.verifyTrue(dic_preprocess.sourceFiles.hasImagePair(cache));
        end
    end
end
