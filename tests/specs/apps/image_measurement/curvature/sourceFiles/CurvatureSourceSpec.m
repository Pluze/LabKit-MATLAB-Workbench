classdef CurvatureSourceSpec < matlab.unittest.TestCase
    %CURVATURESOURCESPEC Specify source replacement resets derived annotations.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function clearingAnImageSelectionClearsCurveState(testCase)
            definition = curvature.definition();
            project = definition.ProjectSchema.Create();
            project.annotations.curvePoints = [1 2; 3 4];
            state = struct("project", project, "session", struct( ...
                "workflow", struct("editMode", "curve"), ...
                "view", struct("scaleBar", [1 2]), "cache", struct("image", [])));
            selection = labkit.app.event.ListSelection();
            context = labkittest.createCallbackContext( ...
                struct("log", @(varargin) []));

            actual = curvature.sourceFiles.selectionChanged(state, selection, context);

            testCase.verifyEmpty(actual.project.annotations.curvePoints);
            testCase.verifyEqual(actual.session.workflow.editMode, "none");
            testCase.verifyEqual(actual.session.workflow.statusMessage, ...
                "Open an image to trace a curve.");
        end
    end
end
