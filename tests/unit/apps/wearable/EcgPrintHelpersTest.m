classdef EcgPrintHelpersTest < matlab.unittest.TestCase
    %ECGPRINTHELPERSTEST Verify GUI-free ECG Print app-owned helpers.

    methods (Test, TestTags = {'Unit'})
        function importOptionsNormalizeUiValues(testCase)
            setupLabKitTestPath();

            opts = ecg_print.io.importOptions(2000, 3, 'No', '2', ...
                'milliseconds', '1, 3, 5');

            testCase.verifyEqual(opts.fallbackFs, 2000);
            testCase.verifyEqual(opts.headerLine, 3);
            testCase.verifyFalse(opts.hasHeader);
            testCase.verifyEqual(opts.timeColumn, 2);
            testCase.verifyEqual(opts.timeUnit, 'milliseconds');
            testCase.verifyEqual(opts.signalColumns, [1 3 5]);

            nameOpts = ecg_print.io.importOptions(1000, 0, 'Auto', ...
                'time_s', 'Auto', 'LeadI; LeadII');
            testCase.verifyFalse(isfield(nameOpts, 'headerLine'));
            testCase.verifyFalse(isfield(nameOpts, 'hasHeader'));
            testCase.verifyEqual(nameOpts.timeColumn, 'time_s');
            testCase.verifyFalse(isfield(nameOpts, 'timeUnit'));
            testCase.verifyEqual(nameOpts.signalColumns(:), {'LeadI'; 'LeadII'});
        end

        function previewFileHeaderReturnsNumberedLines(testCase)
            setupLabKitTestPath();

            filepath = [tempname '.csv'];
            cleaner = onCleanup(@() deleteIfExists(filepath)); %#ok<NASGU>
            fid = fopen(filepath, 'w');
            testCase.assertGreaterThan(fid, 0);
            fprintf(fid, 'time_s,LeadI\n0,1\n1,2\n');
            fclose(fid);

            lines = ecg_print.io.previewFileHeader(filepath, 2);

            testCase.verifyEqual(lines, {'01: time_s,LeadI'; '02: 0,1'});
        end

        function peakMethodValueMapsUiLabels(testCase)
            setupLabKitTestPath();

            testCase.verifyEqual(ecg_print.ops.peakMethodValue('QRS streaming'), ...
                "qrs-streaming");
            testCase.verifyEqual(ecg_print.ops.peakMethodValue('Pan-Tompkins'), ...
                "pan-tompkins");
            testCase.verifyEqual(ecg_print.ops.peakMethodValue('Local peaks'), ...
                "local");
            testCase.verifyEqual(ecg_print.ops.peakMethodValue('unexpected'), ...
                "qrs-streaming");
        end

        function importStatusTextPreservesMetadataSummary(testCase)
            setupLabKitTestPath();

            recording = struct();
            recording.metadata = struct( ...
                'timeColumn', 'time_s', ...
                'timeUnit', 'seconds', ...
                'timeSource', 'column', ...
                'timeRepair', struct( ...
                    'repairedBackwardCount', 3, ...
                    'largeGapCount', 1));

            text = ecg_print.view.importStatusText(recording, 2);

            testCase.verifyEqual(text, ...
                ['2 channel(s) | time: time_s | unit: seconds | source: column | ' ...
                'repaired backward: 3 | large gaps: 1']);
        end

        function summaryRowsReflectSignalAndMeasurementState(testCase)
            setupLabKitTestPath();

            signal = struct( ...
                'displayName', 'Lead I', ...
                'values', [1 2 3 4], ...
                'fs', 250, ...
                'time', [0 0.004 0.008 0.012]);
            events = struct( ...
                'index', [2 4], ...
                'metadata', struct('method', 'qrs-streaming'));
            segments = struct('values', zeros(7, 2));
            measurements = struct('summary', struct( ...
                'SNRdBMean', 12.345, ...
                'SNRdBStd', 0.9876, ...
                'TemplateCorrelationMean', 0.8765));

            rows = ecg_print.view.summaryRows(signal, events, segments, measurements);

            testCase.verifyEqual(rowValue(rows, 'Status'), 'No signal analyzed');
            testCase.verifyEqual(rowValue(rows, 'Channel'), 'Lead I');
            testCase.verifyEqual(rowValue(rows, 'Samples'), '4');
            testCase.verifyEqual(rowValue(rows, 'Estimated Fs (Hz)'), '250');
            testCase.verifyEqual(rowValue(rows, 'Duration (s)'), '0.012');
            testCase.verifyEqual(rowValue(rows, 'Detected peaks'), ...
                '2 (qrs-streaming)');
            testCase.verifyEqual(rowValue(rows, 'Valid segments'), '2');
            testCase.verifyEqual(rowValue(rows, 'Mean SNR (dB)'), '12.3');
            testCase.verifyEqual(rowValue(rows, 'SNR std (dB)'), '0.988');
            testCase.verifyEqual(rowValue(rows, 'Mean template corr.'), '0.876');
        end

        function analysisTableAddsSmoothedColumns(testCase)
            setupLabKitTestPath();

            perSegment = table( ...
                [0; 1; 2; 3], ...
                [1; 10; 3; 4], ...
                [5; 6; 100; 8], ...
                [20; 10; 40; 30], ...
                'VariableNames', {'EventTime', 'SignalP2P', 'NoiseRMS', 'SNRdB'});

            T = ecg_print.export.analysisTable(perSegment, 3);

            testCase.verifyEqual(T.Properties.VariableNames, ...
                {'EventTime', 'SignalP2P', 'NoiseRMS', 'SNRdB', ...
                'SignalP2P_smooth', 'NoiseRMS_smooth', 'SNRdB_smooth'});
            testCase.verifyEqual(T.SignalP2P_smooth, [5.5; 3; 4; 3.5], ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(T.NoiseRMS_smooth, [5.5; 6; 8; 54], ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(T.SNRdB_smooth, [15; 20; 30; 35], ...
                'AbsTol', 1e-12);
        end
    end
end

function value = rowValue(rows, name)
    idx = strcmp(rows(:, 1), name);
    assert(nnz(idx) == 1, ['Missing summary row: ' name]);
    value = rows{idx, 2};
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
