classdef EcgPrintHelpersTest < matlab.unittest.TestCase
    %ECGPRINTHELPERSTEST Verify GUI-free ECG Print app-owned helpers.

    methods (Test, TestTags = {'Unit'})
        function projectMigrationAdoptsCanonicalSourceCollection(testCase)
            setupLabKitTestPath();
            spec = ecg_print.projectSpec();
            project = spec.Create();
            expected = struct("absolutePath", "/tmp/ecg.csv");
            project.inputs.source = expected;
            project.inputs = rmfield(project.inputs, "sources");

            migrated = spec.Migrate(project, 1);
            definition = ecg_print.definition();

            testCase.verifyEqual(migrated.inputs.sources, expected);
            testCase.verifyFalse(isfield(migrated.inputs, "source"));
            testCase.verifyEqual(definition.ProjectSchema.Version, 2);
            testCase.verifyEqual( ...
                definition.ProjectSchema.Migrate, spec.Migrate);
        end

        function importOptionsNormalizeUiValues(testCase)
            setupLabKitTestPath();

            opts = ecg_print.sourceFiles.importOptions(2000, 3, 'No', '2', ...
                'milliseconds', '1, 3, 5');

            testCase.verifyEqual(opts.fallbackFs, 2000);
            testCase.verifyEqual(opts.headerLine, 3);
            testCase.verifyFalse(opts.hasHeader);
            testCase.verifyEqual(opts.timeColumn, 2);
            testCase.verifyEqual(opts.timeUnit, 'milliseconds');
            testCase.verifyEqual(opts.signalColumns, [1 3 5]);

            nameOpts = ecg_print.sourceFiles.importOptions(1000, 0, 'Auto', ...
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
            cleaner = onCleanup(@() deleteIfExists(filepath));
            fid = fopen(filepath, 'w');
            testCase.assertGreaterThan(fid, 0);
            fprintf(fid, 'time_s,LeadI\n0,1\n1,2\n');
            fclose(fid);

            lines = ecg_print.sourceFiles.previewFileHeader(filepath, 2);

            testCase.verifyEqual(lines, {'01: time_s,LeadI'; '02: 0,1'});
        end

        function peakMethodValueMapsUiLabels(testCase)
            setupLabKitTestPath();

            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('QRS streaming'), ...
                "qrs-streaming");
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('Pan-Tompkins'), ...
                "pan-tompkins");
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('Local peaks'), ...
                "local");
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('unexpected'), ...
                "qrs-streaming");
        end

        function analyzeSignalBuildsGuiIndependentProducts(testCase)
            setupLabKitTestPath();

            fs = 100;
            time = (0:1/fs:6)';
            values = 0.02 * sin(2 * pi * 1.5 * time);
            values(101:100:501) = values(101:100:501) + 1;
            signal = struct('time', time, 'values', values, 'fs', fs, ...
                'displayName', "Synthetic ECG", 'metadata', struct());
            cache = struct('signal', signal, 'sourceMarker', 42);
            parameters = struct('lowCut', 0.5, 'highCut', 40, ...
                'roiStart', 0, 'roiEnd', 0, ...
                'peakMethod', "Local peaks", 'peakDistance', 0.5, ...
                'segmentWindow', 0.7, 'templateTopN', 5);

            actual = ecg_print.analysisRun.analyzeSignal(cache, parameters);

            testCase.verifyEqual(actual.sourceMarker, 42);
            testCase.verifyEqual(actual.workingSignal, signal);
            testCase.verifyEqual(actual.filteredSignal.metadata.filter.cutoffHz, ...
                [0.5 40]);
            testCase.verifyEqual(actual.events.metadata.method, "local");
            testCase.verifyEqual(actual.segments.metadata.windowSec, [-0.7 0.7]);
            testCase.verifyLessThanOrEqual( ...
                numel(actual.template.keptSegmentIndex), 5);
            testCase.verifyTrue(isfield(actual.measurements, 'perSegment'));
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

            text = ecg_print.sourceFiles.importStatusText(recording, 2);

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

            rows = ecg_print.analysisRun.summaryRows( ...
                signal, events, segments, measurements);

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

            T = ecg_print.resultFiles.analysisTable(perSegment, 3);

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

        function waveformPlotRequestPrefersFilteredSignalAndPeakCoordinates(testCase)
            setupLabKitTestPath();

            workingSignal = struct( ...
                'time', [0 1 2 3], ...
                'values', [10 11 12 13], ...
                'name', 'raw');
            filteredSignal = struct( ...
                'time', [0 1 2 3], ...
                'values', [1 3 2 4], ...
                'name', 'filtered');
            events = struct('index', [2 4]);

            request = ecg_print.analysisRun.waveformPlotRequest( ...
                workingSignal, filteredSignal, events);

            testCase.verifyTrue(request.ok);
            testCase.verifyEqual(request.x, filteredSignal.time);
            testCase.verifyEqual(request.y, filteredSignal.values);
            testCase.verifyEqual(request.yLabel, 'filtered');
            testCase.verifyEqual(request.peakX, [1 3]);
            testCase.verifyEqual(request.peakY, [3 4]);
            testCase.verifyEqual(request.title, 'Waveform + Peaks');
        end

        function templatePlotRequestBuildsResidualBandAndWindows(testCase)
            setupLabKitTestPath();

            segments = struct( ...
                'values', [1 2 3; 2 4 6; 3 6 9], ...
                'timeOffset', [-0.1 0 0.1]);
            template = struct('values', [2; 4; 6]);
            measurements = struct('metadata', struct( ...
                'signalWindowSec', [-0.04 0.04], ...
                'noiseWindowsSec', [-0.2 -0.1; 0.1 0.2]));

            request = ecg_print.analysisRun.templatePlotRequest(segments, template, ...
                measurements, 'Template + residual band');

            testCase.verifyTrue(request.ok);
            testCase.verifyFalse(request.showSegments);
            testCase.verifyEqual(request.title, 'Template + Residual Band');
            testCase.verifyEqual(request.timeOffset, [-0.1; 0; 0.1]);
            testCase.verifyEqual(request.template, [2; 4; 6]);
            testCase.verifyEqual(request.signalWindowSec, [-0.04 0.04]);
            testCase.verifyEqual(request.noiseWindowsSec, [-0.2 -0.1; 0.1 0.2]);
            testCase.verifyEqual(request.upper - request.template, ...
                std(segments.values - template.values, 0, 2, 'omitnan'), ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(request.template - request.lower, ...
                std(segments.values - template.values, 0, 2, 'omitnan'), ...
                'AbsTol', 1e-12);
        end

        function templatePlotRequestSelectsRepresentativeSegments(testCase)
            setupLabKitTestPath();

            segments = struct( ...
                'values', reshape(1:150, 3, 50), ...
                'timeOffset', [-0.1 0 0.1]);
            template = struct('values', [2; 4; 6]);

            request = ecg_print.analysisRun.templatePlotRequest(segments, template, ...
                struct(), 'Template + segments');

            testCase.verifyTrue(request.ok);
            testCase.verifyTrue(request.showSegments);
            testCase.verifyEqual(request.title, 'Template + Segments');
            testCase.verifyEqual(numel(request.showIndex), 40);
            testCase.verifyEqual(request.showIndex(1), 1);
            testCase.verifyEqual(request.showIndex(end), 50);
            testCase.verifyEqual(request.segments, segments.values);
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
