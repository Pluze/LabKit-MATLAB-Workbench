classdef NerveResponseScientificSpec < matlab.unittest.TestCase
    %NERVERESPONSESCIENTIFICSPEC Specify stimulus, correction, and CAP metrics.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function returnsNoEventsWithoutPositiveTransitionEvidence(testCase)
            signals = {zeros(5, 1), NaN(5, 1), [NaN; 3; NaN; Inf; NaN], 0};
            for k = 1:numel(signals)
                signal = signals{k};
                [events, trains] = nerve_response_analysis.analysisRun.detectEventTrains( ...
                    (0:numel(signal)-1).', signal);
                testCase.verifyEmpty(events);
                testCase.verifyEmpty(trains);
            end
        end

        function excludesNonfiniteValuesFromBaselineAndResponse(testCase)
            time = (0:6).';
            signal = [1; Inf; 3; 0; 4; -2; NaN];
            options = struct("baselineWindowSec", 3, ...
                "blankingAfterPulseSec", 1, "searchEndAfterPulseSec", 3);
            metrics = nerve_response_analysis.analysisRun.measureCapMetrics( ...
                time, signal, 3, options);
            testCase.verifyEqual(metrics.baselineMean, 2);
            testCase.verifyEqual(metrics.noiseRms, 1);
            testCase.verifyEqual(metrics.peakToPeak, 6);
            testCase.verifyEqual(metrics.latencySec, 2);
            testCase.verifyEqual(metrics.status, "ok");
            signal(5:7) = [NaN; Inf; -Inf];
            missing = nerve_response_analysis.analysisRun.measureCapMetrics( ...
                time, signal, 3, options);
            testCase.verifyEqual(missing.status, "noSamples");
            testCase.verifyTrue(isnan(missing.peakToPeak));
            testCase.verifyTrue(isnan(missing.peakTimeSec));
        end

        function qcFlagsExcludeRejectedRecordingsWithoutALabelColumn(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            recordings = table(["excluded"; "included"], ...
                string(fullfile(folder, ["absent-a.rhs"; "absent-b.rhs"])), ...
                ["rejected"; "accepted"], ...
                VariableNames=["recordingId", "filePath", "qcFlag"]);
            analysis = nerve_response_analysis.analysisRun.analyzeSession( ...
                struct("recordings", recordings));
            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyEqual(analysis.analyzedCount, 1);
            testCase.verifyNotEmpty(analysis.issues);
            testCase.verifyEqual(unique(analysis.issues.recordingId), "included");
        end

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
