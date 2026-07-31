classdef CurvatureWorkbenchSpec < matlab.unittest.TestCase
    %CURVATUREWORKBENCHSPEC Specify complete Curvature snapshot composition.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function composesTheEmptyProjectSnapshot(testCase)
            project = curvature.projectSpec().Create();
            session = curvature.createSession(project, ...
                labkit.app.internal.CallbackContextFactory.disconnected());

            snapshot = curvature.workbench.present(struct( ...
                "project", project, "session", session));

            testCase.verifyClass(snapshot, "labkit.app.view.Snapshot");
        end
    end
end
