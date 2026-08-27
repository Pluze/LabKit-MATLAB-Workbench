classdef FocusStackSessionViewRevisionSpec < matlab.unittest.TestCase
    % FOCUSSTACKSESSIONVIEWREVISIONSPEC Specify plot-generation isolation.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function startsEachSessionWithIndependentPlotGeneration(testCase)
            project = focus_stack.initialData();
            first = focus_stack.createSession(project, struct());
            first.cache.plotViewRevision = 7;
            second = focus_stack.createSession(project, struct());

            testCase.verifyEqual(second.cache.plotViewRevision, 0);
            testCase.verifyEqual(first.cache.plotViewRevision, 7);
        end
    end
end
