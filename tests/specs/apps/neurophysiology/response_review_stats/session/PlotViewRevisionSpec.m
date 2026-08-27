classdef PlotViewRevisionSpec < matlab.unittest.TestCase
    % PLOTVIEWREVISIONSPEC Invariant: each Response Review Stats session starts with an independent zero plot generation.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function provesPlotViewRevision(testCase)
            project = response_review_stats.initialData();
            first = response_review_stats.createSession(project, struct());
            first.cache.plotViewRevision = 7;
            second = response_review_stats.createSession(project, struct());

            testCase.verifyEqual(second.cache.plotViewRevision, 0);
            testCase.verifyEqual(first.cache.plotViewRevision, 7);
        end
    end
end
