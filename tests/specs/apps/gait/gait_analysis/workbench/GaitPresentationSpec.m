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
            display = struct("pixelsPerUnit", 2, "unitName", "mm");
            original = gait_analysis.gaitPreview.viewportRevision(sources, 2, display);

            testCase.verifyEqual( ...
                gait_analysis.gaitPreview.viewportRevision(sources, 2, display), ...
                original);
            testCase.verifyNotEqual( ...
                gait_analysis.gaitPreview.viewportRevision( ...
                    struct("id", "pose-b"), 2, display), original);
            testCase.verifyNotEqual( ...
                gait_analysis.gaitPreview.viewportRevision(sources, 3, display), ...
                original);
            display.pixelsPerUnit = 4;
            testCase.verifyNotEqual( ...
                gait_analysis.gaitPreview.viewportRevision(sources, 2, display), original);
            display.pixelsPerUnit = 2; display.unitName = "cm";
            testCase.verifyNotEqual( ...
                gait_analysis.gaitPreview.viewportRevision(sources, 2, display), original);
        end
    end
end
