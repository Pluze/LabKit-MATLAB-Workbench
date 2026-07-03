classdef NerveResponseAnalysisOpsTest < matlab.unittest.TestCase
    %NERVERESPONSEANALYSISOPSTEST Verify event and CAP analysis helpers.

    methods (Test, TestTags = {'Unit'})
        function detectEventTrainsFindsFivePulseTrain(testCase)
            setupLabKitTestPath();

            fs = 30000;
            timeSec = (0:(1 / fs):0.150).';
            signal = zeros(size(timeSec));
            pulseTimes = 0.030 + (0:4).' .* 0.010;
            pulseIdx = round(pulseTimes .* fs) + 1;
            signal(pulseIdx) = 5;

            opts = struct( ...
                "stdMultiplier", 2, ...
                "minPeakDistanceSec", 0.005, ...
                "sourceId", "synthetic_reference", ...
                "train", struct( ...
                "minDetectedPulses", 5, ...
                "maxTrainDurationSec", 0.060, ...
                "groupGapSec", 0.100, ...
                "stimShiftSec", 0));
            [events, trains] = nerve_response_analysis.analysisRun.detectEventTrains( ...
                timeSec, signal, opts);

            testCase.verifyEqual(height(events), 5);
            testCase.verifyEqual(height(trains), 1);
            testCase.verifyTrue(trains.isValid(1));
            testCase.verifyEqual(events.source(1), "synthetic_reference");
        end

        function differentialAndCommonModeHelpersPreserveRoles(testCase)
            setupLabKitTestPath();

            timeSec = (0:0.001:0.050).';
            response = sin(2 * pi * 80 .* timeSec);
            common = sin(2 * pi * 120 .* timeSec);
            signalSet = struct( ...
                "timeSec", timeSec, ...
                "channelNames", ["C-018", "C-012"], ...
                "values", [response + common, common], ...
                "roles", struct( ...
                "cp_positive", struct("channelName", "C-018"), ...
                "cp_negative", struct("channelName", "C-012")));
            pairs = struct("id", "cp_diff", "label", "CP", ...
                "positive", "cp_positive", "negative", "cp_negative");

            derived = nerve_response_analysis.analysisRun.computeDifferentials( ...
                signalSet, pairs);
            corrected = nerve_response_analysis.analysisRun.commonModeCorrect(timeSec, ...
                2 + 0.75 .* common, zeros(size(common)), common, ...
                struct("fitWindowFraction", 0.25));

            testCase.verifyEqual(derived.pairIds, "cp_diff");
            testCase.verifyEqual(derived.status, "ok");
            testCase.verifyLessThan(std(corrected.corrected, "omitnan"), 0.1);
        end

        function measureCapMetricsReportsPeakToPeakAndLatency(testCase)
            setupLabKitTestPath();

            timeSec = (0:0.0001:0.040).';
            signal = zeros(size(timeSec));
            signal(abs(timeSec - 0.014) < 0.0002) = 2;
            signal(abs(timeSec - 0.016) < 0.0002) = -1;

            metrics = nerve_response_analysis.analysisRun.measureCapMetrics(timeSec, ...
                signal, 0.010, struct( ...
                "baselineWindowSec", 0.004, ...
                "blankingAfterPulseSec", 0.002, ...
                "searchEndAfterPulseSec", 0.008));

            testCase.verifyEqual(height(metrics), 1);
            testCase.verifyGreaterThan(metrics.peakToPeak(1), 2.5);
            testCase.verifyGreaterThan(metrics.latencySec(1), 0.002);
            testCase.verifyEqual(metrics.status(1), "ok");
        end

        function analyzeSessionUsesManualFilterLabels(testCase)
            setupLabKitTestPath();

            recordings = table(["R001"; "R002"], ...
                ["missing_bad.rhs"; "missing_good.rhs"], ...
                ["bad"; "good"], ...
                ["manual reject"; "manual keep"], ...
                'VariableNames', {'recordingId', 'filePath', 'label', 'comment'});
            session = struct("recordings", recordings);

            analysis = nerve_response_analysis.analysisRun.analyzeSession(session, ...
                struct(), struct());

            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyEqual(analysis.analyzedCount, 1);
            testCase.verifyEqual(analysis.issues.recordingId(1), "R002");
        end

        function analyzeSessionStillAcceptsLegacyKeepColumn(testCase)
            setupLabKitTestPath();

            recordings = table(["R001"; "R002"], ...
                ["missing_rejected.rhs"; "missing_kept.rhs"], ...
                ["accepted"; "accepted"], ...
                [false; true], ...
                'VariableNames', {'recordingId', 'filePath', 'qcFlag', 'keep'});
            session = struct("recordings", recordings);

            analysis = nerve_response_analysis.analysisRun.analyzeSession(session, ...
                struct(), struct());

            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyEqual(analysis.analyzedCount, 1);
            testCase.verifyEqual(analysis.issues.recordingId(1), "R002");
        end
    end
end
