classdef ImageMatchProjectSpec < matlab.unittest.TestCase
    %IMAGEMATCHPROJECTSPEC Specify a reference separate from batch sources.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsAValidReferenceAndSourceFreeProject(testCase)
            spec = image_match.projectSpec();
            project = spec.Create();

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyEmpty(project.inputs.reference);
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyEqual(project.parameters.matchMethod, "Balanced");
        end
    end
end
