classdef DicPostprocessProjectSpec < matlab.unittest.TestCase
    %DICPOSTPROCESSPROJECTSPEC Specify the durable DIC project boundary.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function acceptsFiniteParametersAndRejectsInvalidScientificValues(testCase)
            spec = dic_postprocess.projectSpec();
            project = spec.Create();
            invalid = project;
            invalid.parameters.gamma = Inf;

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyFalse(spec.Validate(invalid));
            testCase.verifyEmpty(spec.Migrate);
        end
    end
end
