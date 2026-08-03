classdef FocusStackWorkbenchSpec < matlab.unittest.TestCase
    %FOCUSSTACKWORKBENCHSPEC Specify complete Focus Stack snapshot composition.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function composesTheEmptyProjectSnapshot(testCase)
            project = focus_stack.projectSpec().Create();
            session = focus_stack.createSession(project, ...
                labkittest.disconnectedCallbackContext());

            snapshot = focus_stack.workbench.present(struct( ...
                "project", project, "session", session));

            testCase.verifyClass(snapshot, "labkit.app.view.Snapshot");
        end
    end
end
