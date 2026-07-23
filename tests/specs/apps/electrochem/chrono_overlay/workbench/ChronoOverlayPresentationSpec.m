classdef ChronoOverlayPresentationSpec < matlab.unittest.TestCase
    %CHRONOOVERLAYPRESENTATIONSPEC Specify the workbench snapshot boundary.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsAClosedSnapshotFromApplicationState(testCase)
            definition = chrono_overlay.definition();
            project = definition.ProjectSchema.Create();
            item = struct("name", "synthetic.DTA", "tAligned_s", [-1; 0; 1], ...
                "Vf_V", [10; 20; 30], "Im_A", [1; 2; 3]);
            state = struct("project", project, "session", struct( ...
                "cache", struct("items", item), ...
                "selection", struct("files", labkit.app.event.ListSelection(Indices=1))));

            snapshot = chrono_overlay.workbench.present(state);

            testCase.verifyClass(snapshot, "labkit.app.view.Snapshot");
            testCase.verifyFalse(contains(evalc("disp(state)"), "matlab.ui"));
        end
    end
end
