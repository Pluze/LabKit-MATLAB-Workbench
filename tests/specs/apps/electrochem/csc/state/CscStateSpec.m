classdef CscStateSpec < matlab.unittest.TestCase
    % CSCSTATESPEC Invariant: CSC initial data uses supported defaults.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function createsSupportedDefaults(testCase)
            project = csc.initialData();
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyNotEmpty(project.parameters.mode);
        end
    end
end
