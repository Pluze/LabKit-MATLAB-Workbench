classdef ImageMatchStateSpec < matlab.unittest.TestCase
    %IMAGEMATCHSTATESPEC Specify a reference separate from batch sources.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function createsAValidReferenceAndSourceFreeProject(testCase)
            project = image_match.initialData();
            testCase.verifyEmpty(project.inputs.reference);
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyEqual(project.parameters.matchMethod, "Balanced");
        end
    end
end
