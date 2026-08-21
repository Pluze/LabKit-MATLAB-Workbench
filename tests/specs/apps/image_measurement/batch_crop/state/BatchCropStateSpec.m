classdef BatchCropStateSpec < matlab.unittest.TestCase
    %BATCHCROPSTATESPEC Specify current one-task-per-source state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsAValidEmptyCurrentState(testCase)
            project = batch_crop.initialData();
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyEmpty(project.inputs.items);
        end
    end
end
