classdef ResponseReviewStatsOpsTest < matlab.unittest.TestCase
    %RESPONSEREVIEWSTATSOPSTEST Verify segment parsing, alignment, metrics.

    methods (Test, TestTags = {'Unit'})
        function segmentCsvShapeAlignsAndMeasures(testCase)
            setupLabKitTestPath();

            Time_s = (0:0.001:0.020).';
            Signal1 = zeros(size(Time_s));
            Signal2 = zeros(size(Time_s));
            Signal1(Time_s == 0.006) = 2;
            Signal1(Time_s == 0.010) = -1;
            Signal2(Time_s == 0.007) = 3;
            Signal2(Time_s == 0.011) = -2;
            T = table(Time_s, Signal1, Signal2);

            segments = response_review_stats.sourceFiles.parseSegmentTable(T);
            aligned = response_review_stats.analysisRun.alignSegments(segments, ...
                struct("baselineWindowSec", [0 0.002]));
            metrics = response_review_stats.analysisRun.measureAlignedSegments(aligned, ...
                struct("baselineWindowSec", [0 0.002], ...
                "noiseWindowSec", [0 0.002]));
            summary = response_review_stats.analysisRun.summarizeMetrics(metrics);

            testCase.verifyEqual(numel(segments), 2);
            testCase.verifyEqual(size(aligned.values, 2), 2);
            testCase.verifyEqual(height(metrics), 2);
            testCase.verifyGreaterThan(metrics.PeakToPeak(2), metrics.PeakToPeak(1));
            testCase.verifyEqual(height(summary), 2);
        end

        function analysisMetricSummaryUsesPairIds(testCase)
            setupLabKitTestPath();

            metrics = table(["cp"; "cp"; "ta"], [3; 5; 2], [20; 22; 10], ...
                'VariableNames', {'pairId', 'peakToPeak', 'snrDb'});
            summary = response_review_stats.analysisRun.summarizeMetrics(metrics);

            testCase.verifyEqual(height(summary), 2);
            testCase.verifyEqual(summary.Group(1), "cp");
            testCase.verifyEqual(summary.Count(1), 2);
            testCase.verifyEqual(summary.MeanPeakToPeak(1), 4);
        end

        function defaultWindowUsesAlignedTimeIntersection(testCase)
            setupLabKitTestPath();

            segments = struct( ...
                "timeSec", {[10; 11; 12], [20; 21; 22]}, ...
                "values", {[1; 2; 3], [4; 5; 6]}, ...
                "name", {"first", "second"}, ...
                "alignTimeSec", {10, 20});

            aligned = response_review_stats.analysisRun.alignSegments( ...
                segments, struct("sampleIntervalSec", 1));

            testCase.verifyEqual(aligned.timeSec, [0; 1; 2]);
            testCase.verifyEqual(aligned.values, [1 4; 2 5; 3 6]);
        end
    end
end
