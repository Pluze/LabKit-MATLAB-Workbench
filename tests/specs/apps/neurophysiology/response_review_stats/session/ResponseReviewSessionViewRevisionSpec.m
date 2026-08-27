classdef ResponseReviewSessionViewRevisionSpec < matlab.unittest.TestCase
    % RESPONSEREVIEWSESSIONVIEWREVISIONSPEC Specify plot-generation isolation.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function startsEachSessionWithIndependentPlotGeneration(testCase)
            project = response_review_stats.initialData();
            first = response_review_stats.createSession(project, struct());
            first.cache.plotViewRevision = 7;
            second = response_review_stats.createSession(project, struct());

            testCase.verifyEqual(second.cache.plotViewRevision, 0);
            testCase.verifyEqual(first.cache.plotViewRevision, 7);
        end
    end
end
