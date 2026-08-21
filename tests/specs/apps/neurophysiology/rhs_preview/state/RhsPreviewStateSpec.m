classdef RhsPreviewStateSpec < matlab.unittest.TestCase
    %RHSPREVIEWSTATESPEC Specify current role-tagged source state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsTheCurrentSourceCollection(testCase)
            project = rhs_preview.initialData();
            testCase.verifyEmpty(project.inputs.sources);
        end
    end
end
