classdef FocusStackStateSpec < matlab.unittest.TestCase
    %FOCUSSTACKSTATESPEC Specify current focus stack state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsAValidSourceFreeProject(testCase)
            project = focus_stack.initialData();
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyEqual(project.parameters.outputFolder, "");
        end
    end
end
