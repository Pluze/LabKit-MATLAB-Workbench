classdef ImageEnhanceProjectSpec < matlab.unittest.TestCase
    %IMAGEENHANCEPROJECTSPEC Specify durable enhancement history ownership.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsAValidPixelFreeProject(testCase)
            spec = image_enhance.projectSpec();
            project = spec.Create();

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyTrue(project.parameters.batchMode);
            testCase.verifyEmpty(project.annotations.sharedSteps);
            testCase.verifyEmpty(project.annotations.items);
        end
    end
end
