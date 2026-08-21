classdef CicStateSpec < matlab.unittest.TestCase
    % CICSTATESPEC Invariant: CIC initial data uses supported defaults.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function createsSupportedDefaults(testCase)
            project = cic.initialData();
            testCase.verifyEmpty(project.inputs.sources);
            choices = cic.analysisRun.analysisChoices();
            testCase.verifyEqual(project.parameters.pulseMode, ...
                choices.pulseModes(1));
        end
    end
end
