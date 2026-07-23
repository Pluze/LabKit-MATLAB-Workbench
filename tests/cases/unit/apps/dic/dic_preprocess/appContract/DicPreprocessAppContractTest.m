classdef DicPreprocessAppContractTest < matlab.unittest.TestCase
    methods (Test)
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "dic_preprocess"); end
    end
end
