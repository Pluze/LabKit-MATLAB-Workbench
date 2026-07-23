classdef NerveResponseAnalysisAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'}), function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "nerve_response_analysis"); end, end
end
