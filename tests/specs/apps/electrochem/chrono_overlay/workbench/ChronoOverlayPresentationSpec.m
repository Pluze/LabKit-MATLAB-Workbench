classdef ChronoOverlayPresentationSpec < matlab.unittest.TestCase
    %CHRONOOVERLAYPRESENTATIONSPEC Specify the workbench snapshot boundary.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsAClosedSnapshotFromApplicationState(testCase)
            project = chrono_overlay.initialData();
            item = struct("name", "synthetic.DTA", "tAligned_s", [-1; 0; 1], ...
                "Vf_V", [10; 20; 30], "Im_A", [1; 2; 3]);
            project.inputs.sources = [ ...
                labkit.app.source.record("trace-a", "chrono", "trace-a.DTA"), ...
                labkit.app.source.record("trace-b", "chrono", "trace-b.DTA")];
            state = struct("project", project, "session", struct( ...
                "cache", struct("items", [item, item]), ...
                "selection", struct("files", ...
                    labkit.app.event.ListSelection(Indices=[1 2]))));

            snapshot = chrono_overlay.workbench.present(state);

            testCase.verifyClass(snapshot, "labkit.app.view.Snapshot");
            testCase.verifyFalse(contains(evalc("disp(state)"), "matlab.ui"));
        end
    end
end
