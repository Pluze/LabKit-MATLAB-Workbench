classdef DicPostprocessStateSpec < matlab.unittest.TestCase
    %DICPOSTPROCESSSTATESPEC Specify current DIC initial runtime data.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsFiniteInitialParameters(testCase)
            project = dic_postprocess.initialData();
            testCase.verifyTrue(isfinite(project.parameters.gamma));
        end
    end
end
