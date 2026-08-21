classdef VtResistanceStateSpec < matlab.unittest.TestCase
    % VTRESISTANCESTATESPEC Invariant: VT Resistance initial data uses supported defaults.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function createsSupportedDefaults(testCase)
            project = vt_resistance.initialData();
            testCase.verifyEmpty(project.inputs.sources);
            choices = vt_resistance.analysisRun.analysisChoices();
            testCase.verifyEqual(project.parameters.steadyWindow, ...
                choices.steadyWindows(1));
        end
    end
end
