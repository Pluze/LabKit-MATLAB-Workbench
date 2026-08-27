classdef PlotViewRevisionSpec < matlab.unittest.TestCase
    % PLOTVIEWREVISIONSPEC Invariant: each Focus Stack session starts with an independent zero plot generation.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function provesPlotViewRevision(testCase)
            project = focus_stack.initialData();
            first = focus_stack.createSession(project, struct());
            first.cache.plotViewRevision = 7;
            second = focus_stack.createSession(project, struct());

            testCase.verifyEqual(second.cache.plotViewRevision, 0);
            testCase.verifyEqual(first.cache.plotViewRevision, 7);
        end
    end
end
