classdef GaitAnalysisAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "gait_analysis"); end
    end
end
