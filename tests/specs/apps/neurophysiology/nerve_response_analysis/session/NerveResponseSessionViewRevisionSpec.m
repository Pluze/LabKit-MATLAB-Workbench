classdef NerveResponseSessionViewRevisionSpec < matlab.unittest.TestCase
    % NERVERESPONSESESSIONVIEWREVISIONSPEC Specify plot-generation isolation.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function startsEachSessionWithIndependentPlotGeneration(testCase)
            project = nerve_response_analysis.initialData();
            first = nerve_response_analysis.createSession(project, struct());
            first.cache.plotViewRevision = 7;
            second = nerve_response_analysis.createSession(project, struct());

            testCase.verifyEqual(second.cache.plotViewRevision, 0);
            testCase.verifyEqual(first.cache.plotViewRevision, 7);
        end
    end
end
