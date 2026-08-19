classdef NerveResponseScientificSpec < matlab.unittest.TestCase
    %NERVERESPONSESCIENTIFICSPEC Specify stimulus, correction, and CAP metrics.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function detectsAValidFivePulseTrainWithItsDeclaredSource(testCase)
            sampleRate = 30000;
            time = (0:1/sampleRate:.150)';
            signal = zeros(size(time));
            pulseTimes = .030 + (0:4)' .* .010;
            signal(round(pulseTimes .* sampleRate) + 1) = 5;
            options = struct("stdMultiplier", 2, "minPeakDistanceSec", .005, ...
                "sourceId", "synthetic_reference", "train", struct( ...
                "minDetectedPulses", 5, "maxTrainDurationSec", .060, ...
                "groupGapSec", .100, "stimShiftSec", 0));

            [events, trains] = nerve_response_analysis.analysisRun.detectEventTrains( ...
                time, signal, options);

            testCase.verifyEqual(height(events), 5);
            testCase.verifyEqual(height(trains), 1);
            testCase.verifyTrue(trains.isValid(1));
            testCase.verifyEqual(events.source(1), "synthetic_reference");
        end

        function suppressesCommonMode(testCase)
            time = (0:.001:.050)';
            common = sin(2 .* pi .* 120 .* time);

            corrected = nerve_response_analysis.analysisRun.commonModeCorrect(time, ...
                2 + .75 .* common, zeros(size(common)), common, ...
                struct("fitWindowFraction", .25));

            testCase.verifyLessThan(std(corrected.corrected, "omitnan"), .1);
        end

        function measuresCapAmplitudeAndLatencyWithinTheResponseWindow(testCase)
            time = (0:.0001:.040)';
            signal = zeros(size(time));
            signal(abs(time - .014) < .0002) = 2;
            signal(abs(time - .016) < .0002) = -1;

            metrics = nerve_response_analysis.analysisRun.measureCapMetrics( ...
                time, signal, .010, struct("baselineWindowSec", .004, ...
                "blankingAfterPulseSec", .002, "searchEndAfterPulseSec", .008));

            testCase.verifyEqual(height(metrics), 1);
            testCase.verifyGreaterThan(metrics.peakToPeak(1), 2.5);
            testCase.verifyGreaterThan(metrics.latencySec(1), .002);
            testCase.verifyEqual(metrics.status(1), "ok");
        end
    end
end
