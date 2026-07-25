classdef VtResistanceProjectSpec < matlab.unittest.TestCase
    % VTRESISTANCEPROJECTSPEC Invariant: VT Resistance project defaults satisfy the durable validation contract.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsValidDefaultsAndRejectsAnUnknownWindowMode(testCase)
            spec = vt_resistance.projectSpec();
            project = spec.Create();
            invalid = project;
            invalid.parameters.steadyWindow = "unknown";

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyError(@() spec.Validate(invalid), ...
                "vt_resistance:InvalidProject");
        end
    end
end
