classdef EisPresentationSpec < matlab.unittest.TestCase
    %EISPRESENTATIONSPEC Specify the EIS workbench snapshot boundary.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsLoadedFilesWithoutUiHandlesInApplicationState(testCase)
            definition = eis.definition();
            runtime = labkit.app.internal.RuntimeFactory.createHeadless(definition);
            cleanup = onCleanup(@() runtime.close());
            fixture = testfixtures.dtaFixturePath("eis_potentiostatic_zcurve.DTA");

            runtime.applyFileSelection("files", string(fixture), 1);
            state = runtime.State;
            snapshot = eis.workbench.present(state);

            testCase.verifyClass(snapshot, "labkit.app.view.Snapshot");
            testCase.verifyEqual(numel(state.session.cache.items), 1);
            testCase.verifyEqual(state.session.selection.files.Indices, 1);
            testCase.verifyFalse(contains(evalc("disp(state)"), "matlab.ui"));
            clear cleanup
        end
    end
end
