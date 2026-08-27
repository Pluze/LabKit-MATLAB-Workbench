classdef GaitPresentationSpec < matlab.unittest.TestCase
    %GAITPRESENTATIONSPEC Specify analysis availability and status presentation.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsRunAvailabilityAndAnalysisStatus(testCase)
            pose = gait_analysis.sourceFiles.emptyPoseData();
            pose.ok = true;
            result = gait_analysis.analysisRun.emptyResult();
            result.message = "Run analysis to calculate gait metrics.";

            snapshot = gait_analysis.analysisRun.present(pose, result);

            testCase.verifyClass(snapshot, "labkit.app.view.Snapshot");
        end


        function sourceResultAndSelectedStepOwnViewportRevision(testCase)
            sources = struct("id", "pose-a");
            original = gait_analysis.gaitPreview.viewportRevision(sources, 2);

            testCase.verifyEqual( ...
                gait_analysis.gaitPreview.viewportRevision(sources, 2), ...
                original);
            testCase.verifyNotEqual( ...
                gait_analysis.gaitPreview.viewportRevision( ...
                    struct("id", "pose-b"), 2), original);
            testCase.verifyNotEqual( ...
                gait_analysis.gaitPreview.viewportRevision(sources, 3), ...
                original);
        end
    end
end
