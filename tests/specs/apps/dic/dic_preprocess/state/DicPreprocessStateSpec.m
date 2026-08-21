classdef DicPreprocessStateSpec < matlab.unittest.TestCase
    %DICPREPROCESSSTATESPEC Specify current DIC preprocess state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsTheCurrentStateShape(testCase)
            project = dic_preprocess.initialData();
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyEqual(project.parameters.previewMode, "Current pair");
        end
    end
end
