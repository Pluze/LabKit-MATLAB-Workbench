classdef DicPostprocessPresentationSpec < matlab.unittest.TestCase
    %DICPOSTPROCESSPRESENTATIONSPEC Specify headless DIC view construction.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function mapsSummaryAndOverlaysToOneValidatedSnapshot(testCase)
            definition = dic_postprocess.definition();
            project = definition.ProjectSchema.Create();
            project.results.summaryTable = table(cellstr(['Mean'; 'Std ']), [1.25; 0.5], ...
                [-2; 0.25], 'VariableNames', {'Metric', 'EXX', 'EYY'});
            state = struct("project", project, "session", struct("cache", ...
                struct("overlayExx", zeros(2, 2, 3), "overlayEyy", ones(2, 2, 3))));

            view = dic_postprocess.workbench.present(state);
            data = dic_postprocess.overlayPreview.summaryTableData( ...
                project.results.summaryTable);

            testCase.verifyClass(view, "labkit.app.view.Snapshot");
            testCase.verifyEqual(data, {'Mean', 1.25, -2; 'Std', 0.5, 0.25});
        end
    end
end
