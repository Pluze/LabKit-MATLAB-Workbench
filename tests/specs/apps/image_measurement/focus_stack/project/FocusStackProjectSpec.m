classdef FocusStackProjectSpec < matlab.unittest.TestCase
    %FOCUSSTACKPROJECTSPEC Specify source-free focus stack project creation.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsAValidSourceFreeProjectWithNoMigrationDebt(testCase)
            spec = focus_stack.projectSpec();
            project = spec.Create();

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyEqual(project.parameters.outputFolder, "");
            testCase.verifyEmpty(spec.Migrate);
        end
    end
end
