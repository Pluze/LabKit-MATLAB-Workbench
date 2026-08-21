classdef CurvatureStateSpec < matlab.unittest.TestCase
    %CURVATURESTATESPEC Specify current source state and empty session.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function validatesDefaultsAndRebuildsAnEmptySession(testCase)
            project = curvature.initialData();
            session = curvature.createSession(project, ...
                labkittest.disconnectedCallbackContext());

            testCase.verifyEmpty(session.cache.image);
            testCase.verifyEqual(session.workflow.editMode, "none");
        end
    end
end
