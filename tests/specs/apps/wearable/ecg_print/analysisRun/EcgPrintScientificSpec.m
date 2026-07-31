classdef EcgPrintScientificSpec < matlab.unittest.TestCase
    %ECGPRINTSCIENTIFICSPEC Specify ECG analysis values independent of UI.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function sanitizesParametersAndMapsPeakMethodLabels(testCase)
            parameters = struct("roiStart", NaN, "roiEnd", Inf, ...
                "lowCut", -2, "highCut", 500, "peakDistance", 0, ...
                "segmentWindow", NaN, "templateTopN", 2.6, "smoothBeats", Inf);

            actual = ecg_print.analysisRun.sanitizeParameters(parameters, 100);

            testCase.verifyEqual(actual.roiStart, 0);
            testCase.verifyEqual(actual.roiEnd, 0);
            testCase.verifyEqual(actual.lowCut, 0);
            testCase.verifyEqual(actual.highCut, 45);
            testCase.verifyEqual(actual.templateTopN, 3);
            testCase.verifyEqual(actual.smoothBeats, 15);
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('Local peaks'), ...
                "local");
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('Pan-Tompkins'), ...
                "pan-tompkins");
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('QRS streaming'), ...
                "qrs-streaming");
            testCase.verifyError( ...
                @() ecg_print.analysisRun.peakMethodValue('unexpected'), ...
                'ecg_print:UnsupportedPeakMethodLabel');
        end

        function derivesGuiIndependentSignalProducts(testCase)
            fs = 100;
            time = (0:1/fs:6)';
            values = 0.02 .* sin(2 .* pi .* 1.5 .* time);
            values(101:100:501) = values(101:100:501) + 1;
            signal = struct("time", time, "values", values, "fs", fs, ...
                "displayName", "Synthetic ECG", "metadata", struct());
            cache = struct("signal", signal, "sourceMarker", 42);
            parameters = struct("lowCut", 0.5, "highCut", 40, "roiStart", 0, ...
                "roiEnd", 0, "peakMethod", "Local peaks", "peakDistance", 0.5, ...
                "segmentWindow", 0.7, "templateTopN", 5);

            actual = ecg_print.analysisRun.analyzeSignal(cache, parameters);

            testCase.verifyEqual(actual.sourceMarker, 42);
            testCase.verifyEqual(actual.workingSignal, signal);
            testCase.verifyEqual(actual.filteredSignal.metadata.filter.cutoffHz, [0.5 40]);
            testCase.verifyEqual(actual.events.metadata.method, "local");
            testCase.verifyEqual(actual.segments.metadata.windowSec, [-0.7 0.7]);
            testCase.verifyLessThanOrEqual(numel(actual.template.keptSegmentIndex), 5);
            testCase.verifyTrue(isfield(actual.measurements, 'perSegment'));
        end

        function summarizesDetectedPeaksWithStableReaderFacingText(testCase)
            signal = struct("displayName", "Lead I", "values", [1 2 3 4], ...
                "fs", 250, "time", [0 .004 .008 .012]);
            events = struct("index", [2 4], "metadata", struct("method", "qrs-streaming"));
            segments = struct("values", zeros(7, 2));
            measurements = struct("summary", struct("SNRdBMean", 12.345, ...
                "SNRdBStd", .9876, "TemplateCorrelationMean", .8765));

            rows = ecg_print.analysisRun.summaryRows(signal, events, segments, measurements);

            testCase.verifyEqual(rowValue(rows, 'Detected peaks'), '2 (qrs-streaming)');
            testCase.verifyEqual(rowValue(rows, 'Mean SNR (dB)'), '12.3');
            testCase.verifyEqual(rowValue(rows, 'SNR std (dB)'), '0.988');
        end
    end
end

function value = rowValue(rows, name)
index = strcmp(rows(:, 1), name);
assert(nnz(index) == 1, "Missing summary row: %s.", name);
value = rows{index, 2};
end
