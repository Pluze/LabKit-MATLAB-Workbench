classdef ImageEnhanceStateSpec < matlab.unittest.TestCase
    %IMAGEENHANCESTATESPEC Specify runtime enhancement history ownership.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function createsAValidPixelFreeProject(testCase)
            project = image_enhance.initialData();
            testCase.verifyTrue(project.parameters.batchMode);
            testCase.verifyEmpty(project.annotations.sharedSteps);
            testCase.verifyEmpty(project.annotations.items);
        end
    end
end
