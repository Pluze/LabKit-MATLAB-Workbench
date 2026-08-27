classdef PlotViewRevisionSpec < matlab.unittest.TestCase
    % PLOTVIEWREVISIONSPEC Invariant: each Nerve Response Analysis session starts with an independent zero plot generation.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function provesPlotViewRevision(testCase)
            project = nerve_response_analysis.initialData();
            first = nerve_response_analysis.createSession(project, struct());
            first.cache.plotViewRevision = 7;
            second = nerve_response_analysis.createSession(project, struct());

            testCase.verifyEqual(second.cache.plotViewRevision, 0);
            testCase.verifyEqual(first.cache.plotViewRevision, 7);
        end
    end
end
