classdef ResponseReviewStatsIsolatedPathContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Integration'})
        function runsWithoutSiblingApps(testCase), verifyAppIsolatedPathContract(testCase, "neurophysiology/response_review_stats"); end
    end
end
