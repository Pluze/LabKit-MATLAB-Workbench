classdef ResponseReviewStateSpec < matlab.unittest.TestCase
    %RESPONSEREVIEWSTATESPEC Specify current response-review state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsTheCurrentSourceCollection(testCase)
            project = response_review_stats.initialData();
            testCase.verifyEmpty(project.inputs.sources);
        end
    end
end
