classdef GaitStateSpec < matlab.unittest.TestCase
    %GAITSTATESPEC Specify current Gait state validation.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsSourceFreeInitialData(testCase)
            project = gait_analysis.initialData();
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyLessThanOrEqual(project.parameters.minSwingFrames, ...
                project.parameters.maxSwingFrames);
        end
    end
end
