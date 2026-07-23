classdef DicPreprocessAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "dic_preprocess"); end
    end
end
