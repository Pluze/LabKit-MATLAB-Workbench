classdef GaitAnalysisAppContractTest < matlab.unittest.TestCase
    methods (Test)
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "gait_analysis"); end
    end
end
