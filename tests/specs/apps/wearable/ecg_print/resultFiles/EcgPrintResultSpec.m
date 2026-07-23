classdef EcgPrintResultSpec < matlab.unittest.TestCase
    %ECGPRINTRESULTSPEC Specify ECG segment result schemas and manifests.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function addsCenteredSmoothedMeasurementColumns(testCase)
            segments = table([0; 1; 2; 3], [1; 10; 3; 4], [5; 6; 100; 8], ...
                [20; 10; 40; 30], 'VariableNames', ...
                {'EventTime', 'SignalP2P', 'NoiseRMS', 'SNRdB'});

            actual = ecg_print.resultFiles.analysisTable(segments, 3);

            testCase.verifyEqual(actual.Properties.VariableNames, ...
                {'EventTime', 'SignalP2P', 'NoiseRMS', 'SNRdB', ...
                'SignalP2P_smooth', 'NoiseRMS_smooth', 'SNRdB_smooth'});
            testCase.verifyEqual(actual.SignalP2P_smooth, [5.5; 3; 4; 3.5], AbsTol=1e-12);
            testCase.verifyEqual(actual.NoiseRMS_smooth, [5.5; 6; 8; 54], AbsTol=1e-12);
            testCase.verifyEqual(actual.SNRdB_smooth, [15; 20; 30; 35], AbsTol=1e-12);
        end

        function keepsManifestSummarySmallAndSerializable(testCase)
            analysis = struct("channel", "ECG", "eventCount", 4, ...
                "segmentCount", 3, "summary", struct("mean", 2), ...
                "perSegment", table((1:3)', 'VariableNames', {'Index'}));

            summary = ecg_print.resultFiles.manifestSummary(analysis);

            testCase.verifyFalse(isfield(summary, "perSegment"));
            testCase.verifyEqual(summary.channel, "ECG");
            testCase.verifyEqual(summary.eventCount, 4);
        end
    end
end
