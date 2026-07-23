classdef DicPostprocessAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "dic_postprocess"); end
    end
end
