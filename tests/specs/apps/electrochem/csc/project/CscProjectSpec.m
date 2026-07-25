classdef CscProjectSpec < matlab.unittest.TestCase
    % CSCPROJECTSPEC Invariant: CSC project defaults satisfy the durable validation contract.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsValidDefaultsAndRejectsAnUnknownAnalysisMode(testCase)
            spec = csc.projectSpec();
            project = spec.Create();
            invalid = project;
            invalid.parameters.mode = "unknown";

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyError(@() spec.Validate(invalid), ...
                "csc:InvalidProject");
        end
    end
end
