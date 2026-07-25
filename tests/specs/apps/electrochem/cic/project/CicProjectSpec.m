classdef CicProjectSpec < matlab.unittest.TestCase
    % CICPROJECTSPEC Invariant: CIC project defaults satisfy the durable validation contract.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsValidDefaultsAndRejectsAnUnknownPulseMode(testCase)
            spec = cic.projectSpec();
            project = spec.Create();
            invalid = project;
            invalid.parameters.pulseMode = "unknown";

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyError(@() spec.Validate(invalid), ...
                "cic:InvalidProject");
        end
    end
end
