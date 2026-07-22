classdef NerveResponseAnalysisIsolatedPathContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Integration'})
        function runsWithoutSiblingApps(testCase), verifyAppIsolatedPathContract(testCase, "neurophysiology/nerve_response_analysis"); end
    end
end
