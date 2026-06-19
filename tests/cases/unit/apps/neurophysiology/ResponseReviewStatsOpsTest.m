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

            segments = response_review_stats.io.parseSegmentTable(T);
            aligned = response_review_stats.ops.alignSegments(segments, ...
                struct("baselineWindowSec", [0 0.002]));
            metrics = response_review_stats.ops.measureAlignedSegments(aligned, ...
                struct("baselineWindowSec", [0 0.002], ...
                "noiseWindowSec", [0 0.002]));
            summary = response_review_stats.ops.summarizeMetrics(metrics);

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
            summary = response_review_stats.ops.summarizeMetrics(metrics);

            testCase.verifyEqual(height(summary), 2);
            testCase.verifyEqual(summary.Group(1), "cp");
            testCase.verifyEqual(summary.Count(1), 2);
            testCase.verifyEqual(summary.MeanPeakToPeak(1), 4);
        end
    end
end
