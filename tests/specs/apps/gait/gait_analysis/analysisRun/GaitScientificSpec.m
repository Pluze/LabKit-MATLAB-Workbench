classdef GaitScientificSpec < matlab.unittest.TestCase
    %GAITSCIENTIFICSPEC Specify gait swing segmentation and source-derived options.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function singleFrameRetainsOneRowOfKinematics(testCase)
            pose = testfixtures.gait.pose();
            pose.coords = zeros(1, 5, 2);
            pose.coords(1, :, 1) = 0:4;
            pose.frameIndex = 1;
            pose.time = 0;
            result = gait_analysis.analysisRun.computeGait( ...
                pose, GaitScientificSpec.options());
            testCase.verifyEqual(height(result.frameTable), 1);
            testCase.verifyEqual(height(result.coordinateTable), 1);
            testCase.verifyEqual(result.frameTable.hip_angle_deg, 180);
            testCase.verifyEqual(result.frameTable.iliac_hip_length, 1);
            testCase.verifyEmpty(result.stepTable);
        end

        function preservesCoordinatesForNamesWithTheSameSanitizedForm(testCase)
            pose = testfixtures.gait.pose();
            baseline = gait_analysis.analysisRun.computeGait( ...
                pose, GaitScientificSpec.options());
            count = size(pose.coords, 1);
            pose.pointNames = [pose.pointNames(:); "probe-a"; "probe/a"];
            pose.coords(:, 6, 1) = 10;
            pose.coords(:, 6, 2) = 20;
            pose.coords(:, 7, 1) = 30;
            pose.coords(:, 7, 2) = 40;
            result = gait_analysis.analysisRun.computeGait( ...
                pose, GaitScientificSpec.options());
            testCase.assertEqual(width(result.frameTable), ...
                width(baseline.frameTable) + 4);
            testCase.assertEqual(width(result.coordinateTable), ...
                width(baseline.coordinateTable) + 8);
            testCase.verifyEqual(result.frameTable{:, end-3:end}, ...
                repmat([10 20 30 40], count, 1));
            testCase.verifyEqual(result.coordinateTable{:, end-7:end}, ...
                repmat([10 20 10 20 30 40 30 40], count, 1));
        end

        function segmentsSwingsAndReportsStepMetrics(testCase)
            pose = testfixtures.gait.pose();
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
            pose = testfixtures.gait.pose();
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
