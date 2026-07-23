classdef DicPostprocessAppContractTest < matlab.unittest.TestCase
    methods (Test)
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "dic_postprocess"); end
    end
end
