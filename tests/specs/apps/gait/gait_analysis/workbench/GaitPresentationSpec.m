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
    end
end
