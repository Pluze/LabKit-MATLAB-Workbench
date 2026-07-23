classdef GaitScientificSpec < matlab.unittest.TestCase
    %GAITSCIENTIFICSPEC Specify gait swing segmentation and source-derived options.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function segmentsSwingsAndReportsStepMetrics(testCase)
            pose = testfixtures.syntheticGaitPose();
            options = GaitScientificSpec.options();

            result = gait_analysis.analysisRun.computeGait(pose, options);

            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(result.events.liftOffFrames, [3; 9]);
            testCase.verifyEqual(result.events.landingFrames, [5; 11]);
            testCase.verifyEqual(result.stepTable.step_length, [5; 6], "AbsTol", 1e-12);
            testCase.verifyEqual(result.stepTable.swing_time_s, [2; 2] ./ 30, "AbsTol", 1e-12);
            testCase.verifyTrue(all(ismember(["hip_min_deg", "hip_max_deg", "hip_rom_deg"], ...
                string(result.stepTable.Properties.VariableNames))));
        end

        function derivesTimingScaleAndPointRolesFromPoseFacts(testCase)
            pose = testfixtures.syntheticGaitPose();
            pose.frameRate = 120;
            pose.pointNames(1) = "iliac_crest";
            options = gait_analysis.analysisRun.defaultOptions();
            options.frameRate = 10;
            options.pixelsPerUnit = 22;
            options.unitName = "mm";
            options.iliacPoint = "old_iliac";

            actual = gait_analysis.analysisRun.optionsForPose(pose, options);

            testCase.verifyEqual([actual.frameRate, actual.pixelsPerUnit], [120, 1]);
            testCase.verifyEqual(actual.unitName, "px");
            testCase.verifyEqual(actual.iliacPoint, "iliac_crest");
        end
    end

    methods (Static, Access = private)
        function options = options()
            options = gait_analysis.analysisRun.defaultOptions();
            options.smoothWindow = 1;
            options.detectionProminence = 2;
            options.minLiftOffIntervalSeconds = 0.1;
            options.minStepLength = 2;
        end
    end
end
