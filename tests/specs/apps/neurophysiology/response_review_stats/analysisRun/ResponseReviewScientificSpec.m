classdef ResponseReviewScientificSpec < matlab.unittest.TestCase
    %RESPONSEREVIEWSCIENTIFICSPEC Specify aligned response measurements.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function alignsSegmentCsvSignalsAndMeasuresTheirDistinctAmplitudes(testCase)
            source = syntheticSegments();
            segments = response_review_stats.sourceFiles.parseSegmentTable(source);
            options = struct("baselineWindowSec", [0 .002], ...
                "noiseWindowSec", [0 .002]);

            aligned = response_review_stats.analysisRun.alignSegments(segments, options);
            metrics = response_review_stats.analysisRun.measureAlignedSegments(aligned, options);
            summary = response_review_stats.analysisRun.summarizeMetrics(metrics);

            testCase.verifyEqual(numel(segments), 2);
            testCase.verifyEqual(size(aligned.values, 2), 2);
            testCase.verifyEqual(height(metrics), 2);
            testCase.verifyGreaterThan(metrics.PeakToPeak(2), metrics.PeakToPeak(1));
            testCase.verifyEqual(height(summary), 2);
        end

        function usesTheAlignedIntersectionAndStablePairGroups(testCase)
            segments = struct("timeSec", {[10; 11; 12], [20; 21; 22]}, ...
                "values", {[1; 2; 3], [4; 5; 6]}, ...
                "name", {"first", "second"}, "alignTimeSec", {10, 20});
            metrics = table(["cp"; "cp"; "ta"], [3; 5; 2], [20; 22; 10], ...
                'VariableNames', {'pairId', 'peakToPeak', 'snrDb'});

            aligned = response_review_stats.analysisRun.alignSegments( ...
                segments, struct("sampleIntervalSec", 1));
            summary = response_review_stats.analysisRun.summarizeMetrics(metrics);

            testCase.verifyEqual(aligned.timeSec, [0; 1; 2]);
            testCase.verifyEqual(aligned.values, [1 4; 2 5; 3 6]);
            testCase.verifyEqual(summary.Group(1), "cp");
            testCase.verifyEqual(summary.Count(1), 2);
            testCase.verifyEqual(summary.MeanPeakToPeak(1), 4);
        end
    end
end

function source = syntheticSegments()
time = (0:.001:.020)';
first = zeros(size(time));
second = zeros(size(time));
first(time == .006) = 2;
first(time == .010) = -1;
second(time == .007) = 3;
second(time == .011) = -2;
source = table(time, first, second, 'VariableNames', {'Time_s', 'Signal1', 'Signal2'});
end
