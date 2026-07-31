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

        function rejectsMalformedParametersAndResultState(testCase)
            spec = focus_stack.projectSpec();
            project = spec.Create();
            cases = { ...
                "fusionPreset", "unknown"; ...
                "autoRegister", 1; ...
                "focusWindow", 4; ...
                "smoothRadius", 51; ...
                "uncertainBlend", 101};
            for k = 1:size(cases, 1)
                invalid = project;
                invalid.parameters.(cases{k, 1}) = cases{k, 2};
                testCase.verifyError(@() spec.Validate(invalid), ...
                    "focus_stack:InvalidProject");
            end
            invalid = project;
            invalid.results.lastRun = struct([]);
            testCase.verifyError(@() spec.Validate(invalid), ...
                "focus_stack:InvalidProject");
        end
    end
end
