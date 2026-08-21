classdef TTestStateSpec < matlab.unittest.TestCase
    %TTESTSTATESPEC Specify current T-Test Wizard state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsCurrentGroups(testCase)
            project = ttest_wizard.initialData();
            testCase.verifyEmpty(project.inputs.groups);
            testCase.verifyEmpty(project.results.current);
        end
    end
end
