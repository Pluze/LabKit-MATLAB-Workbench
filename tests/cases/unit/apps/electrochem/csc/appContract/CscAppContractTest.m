classdef CscAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "csc"); end
    end
end
