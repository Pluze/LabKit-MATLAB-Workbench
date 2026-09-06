classdef BiosignalFacadeSpec < matlab.unittest.TestCase
    %BIOSIGNALFACADESPEC Specify public recording and ECG-analysis behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function extendsASoleFiniteSampleWithoutInventingASlope(testCase)
            signal = struct("time", (0:4).', "values", [NaN; Inf; 3; NaN; -Inf], ...
                "fs", 1, "metadata", struct());
            filtered = labkit.biosignal.filterSignal(signal, struct("type", "none"));
            testCase.verifyEqual(filtered.values, 3 * ones(5, 1));
            testCase.verifyEqual(filtered.time, signal.time);
        end

        function rejectsUnknownOrNonstructPublicOptions(testCase)
            signal = BiosignalFacadeSpec.syntheticEcgSignal();
            testCase.verifyError(@() labkit.biosignal.detectEcgPeaks( ...
                signal, struct("methd", "local")), ...
                "labkit:biosignal:InvalidOptions");
            testCase.verifyError(@() labkit.biosignal.filterSignal( ...
                signal, "bandpass"), "labkit:biosignal:InvalidOptions");
        end

        function importsDelimitedRecordingsWithExplicitOrSyntheticTime(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            noTime = fullfile(folder, "signals.csv");
            milliseconds = fullfile(folder, "signals_ms.csv");
            missingTime = fullfile(folder, "signals_missing_time.csv");
            writetable(table((1001:1005).', [0; 1; 0; -1; 0], ...
                'VariableNames', {'Sample', 'ECG'}), noTime);
            writetable(table((0:10:40).', [0; 1; 0; -1; 0], ...
                'VariableNames', {'time_ms', 'ECG'}), milliseconds);
            writeText(missingTime, sprintf( ...
                'time_s,ECG\n0,1\nNaN,2\n0.02,3\n'));

            [synthetic, syntheticStatus] = labkit.biosignal.readRecording(noTime);
            [timed, timedStatus] = labkit.biosignal.readRecording(milliseconds);
            [cleaned, cleanedStatus] = labkit.biosignal.readRecording(missingTime);
            syntheticEcg = labkit.biosignal.getChannel(synthetic, "ECG");
            timedEcg = labkit.biosignal.getChannel(timed, "ECG");

            testCase.verifyTrue(syntheticStatus.ok, syntheticStatus.message);
            testCase.verifyEqual(synthetic.metadata.timeSource, "synthetic_sample_index");
            testCase.verifyEqual(syntheticEcg.time, (0:4).');
            testCase.verifyTrue(timedStatus.ok, timedStatus.message);
            testCase.verifyEqual(timed.metadata.timeUnit, "milliseconds");
            testCase.verifyEqual(timedEcg.fs, 100, "AbsTol", 1e-9);
            testCase.verifyTrue(cleanedStatus.ok, cleanedStatus.message);
            testCase.verifyEqual(cleaned.signals.time, [0; 0.02], "AbsTol", 1e-12);
            testCase.verifyEqual(cleaned.signals.values, [1; 3]);
            testCase.verifyEqual( ...
                cleaned.signals.metadata.samplingNormalization.removedNonfiniteTimeCount, 1);
        end

        function importsTimetablesAndExposesNamedChannels(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            source = fullfile(folder, "recording.mat");
            signal = BiosignalFacadeSpec.syntheticEcgSignal();
            TT = timetable(seconds(signal.time), signal.values, ...
                'VariableNames', {'ECG'});
            save(source, "TT");

            [recording, status] = labkit.biosignal.readRecording(source);
            channels = labkit.biosignal.listChannels(recording);
            ecg = labkit.biosignal.getChannel(recording, "ECG");
            cropped = labkit.biosignal.cropSignal(ecg, [0.5, 9.5]);

            testCase.verifyTrue(status.ok, status.message);
            testCase.verifyEqual(numel(channels), 1);
            testCase.verifyTrue(contains(string(channels), "ECG"));
            testCase.verifyEqual(ecg.fs, 100, "AbsTol", 1e-9);
            testCase.verifyEqual(cropped.time(1), 0);
            testCase.verifyLessThan(numel(cropped.values), numel(ecg.values));
        end

        function importsBiopacMatAndTextExports(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            matSource = fullfile(folder, "biopac.mat");
            data = [1 10; 2 20; 3 30];
            isi = 0.5;
            isi_units = 'ms';
            labels = char('Current Monitor', 'Surface EMG');
            units = char('mA', 'mV');
            start_sample = 12;
            save(matSource, "data", "isi", "isi_units", "labels", "units", "start_sample");

            textSource = fullfile(folder, "biopac.txt");
            writeText(textSource, sprintf([ ...
                'Synthetic.acq\n0.5 msec/sample\n2 channels\n' ...
                'Surface ECG\nmV\nStimulus\nVolts\n' ...
                'sec,CH1,CH2,\n,3,3,\n0,1,5\n0.0005,2,0\n0.001,3,5\n']));

            [matRecording, matStatus] = labkit.biosignal.readRecording(matSource);
            [textRecording, textStatus] = labkit.biosignal.readRecording(textSource);

            testCase.verifyTrue(matStatus.ok, matStatus.message);
            testCase.verifyEqual(string(labkit.biosignal.listChannels(matRecording)), ...
                ["Current Monitor" "Surface EMG"]);
            testCase.verifyEqual(matRecording.signals(2).unit, "mV");
            testCase.verifyEqual(matRecording.signals(1).fs, 2000, "AbsTol", 1e-9);
            testCase.verifyEqual(matRecording.signals(1).time, [0; 0.0005; 0.001], ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(matRecording.signals(1).metadata.startSample, 12);
            testCase.verifyEqual(matStatus.format, "biopac_mat");
            testCase.verifyFalse(matStatus.fallbackUsed);
            testCase.verifyGreaterThan(matStatus.fileInfo.bytes, 0);
            testCase.verifyEqual(matRecording.metadata.detectedFormat, "biopac_mat");
            testCase.verifyTrue(textStatus.ok, textStatus.message);
            testCase.verifyEqual(textRecording.metadata.sourceKind, "biopac_text");
            testCase.verifyEqual(textStatus.format, "biopac_text");
            testCase.verifyEqual(string(labkit.biosignal.listChannels(textRecording)), ...
                ["Surface ECG" "Stimulus"]);
            testCase.verifyEqual(string({textRecording.signals.unit}), ["mV" "Volts"]);
            testCase.verifyEqual(textRecording.signals(1).values, [1; 2; 3]);
        end

        function fallsBackToTheNextCompatibleMatParser(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            source = fullfile(folder, "fallback.mat");
            data = "invalid BIOPAC matrix";
            isi = 1;
            isi_units = 'ms';
            labels = 'Ignored';
            units = 'mV';
            TT = timetable(seconds((0:2).'), [1; 2; 3], ...
                'VariableNames', {'ECG'});
            save(source, "data", "isi", "isi_units", "labels", "units", "TT");

            [recording, status] = labkit.biosignal.readRecording(source);

            testCase.verifyTrue(status.ok, status.message);
            testCase.verifyTrue(status.fallbackUsed);
            testCase.verifyEqual(status.fileInfo.detectedFormat, "biopac_mat");
            testCase.verifyEqual(status.format, "timetable_mat");
            testCase.verifyEqual([status.attempts.ok], [false true]);
            testCase.verifyEqual(string({status.attempts.format}), ...
                ["biopac_mat" "timetable_mat"]);
            testCase.verifyEqual(recording.metadata.importFallbackUsed, true);
        end

        function recognizesQuotedDeviceHeadersAndResamplesUniformly(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            source = fullfile(folder, "quoted.csv");
            writeText(source, sprintf([ ...
                '"Time, sec","ECG, mV"\n' ...
                '0,0\n0.01,1\n0.0205,2\n0.03,3\n1,4\n1.01,5\n']));

            [recording, status] = labkit.biosignal.readRecording(source);
            [original, originalStatus] = labkit.biosignal.readRecording( ...
                source, struct("resampleUniform", false));

            testCase.verifyTrue(status.ok, status.message);
            testCase.verifyEqual(string(labkit.biosignal.listChannels(recording)), "ECG_MV");
            testCase.verifyEqual(diff(recording.signals.time), ...
                repmat(0.01, numel(recording.signals.time) - 1, 1), "AbsTol", 1e-12);
            normalization = recording.signals.metadata.samplingNormalization;
            testCase.verifyTrue(normalization.resampled);
            testCase.verifyEqual(normalization.compressedGapCount, 1);
            testCase.verifyTrue(originalStatus.ok, originalStatus.message);
            testCase.verifyEqual(original.signals.time, [0; 0.01; 0.0205; 0.03; 1; 1.01]);
            testCase.verifyFalse(original.signals.metadata.samplingNormalization.enabled);
        end

        function importsMatTablesAndUnambiguousNumericArrays(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            tableSource = fullfile(folder, "table.mat");
            T = table((0:10:30).', [0; 1; 0; -1], ...
                'VariableNames', {'Time_ms', 'LeadI'});
            T.Properties.VariableUnits = {'ms', 'mV'};
            save(tableSource, "T");
            numericSource = fullfile(folder, "numeric.mat");
            waveform = [0; 1; 0; -1];
            save(numericSource, "waveform");

            [tableRecording, tableStatus] = labkit.biosignal.readRecording(tableSource);
            [numericRecording, numericStatus] = labkit.biosignal.readRecording( ...
                numericSource, struct("fallbackFs", 250));

            testCase.verifyTrue(tableStatus.ok, tableStatus.message);
            testCase.verifyEqual(tableStatus.format, "table_mat");
            testCase.verifyEqual(string(labkit.biosignal.listChannels(tableRecording)), ...
                "T / LeadI");
            testCase.verifyEqual(tableRecording.signals.unit, "mV");
            testCase.verifyEqual(tableRecording.signals.fs, 100, "AbsTol", 1e-9);
            testCase.verifyTrue(numericStatus.ok, numericStatus.message);
            testCase.verifyEqual(numericStatus.format, "numeric_mat");
            testCase.verifyEqual(numericRecording.signals.displayName, "waveform");
            testCase.verifyEqual(numericRecording.signals.fs, 250, "AbsTol", 1e-9);
        end

        function cleansInvalidUnorderedAndDuplicateTimetableTimes(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            source = fullfile(folder, "dirty-timetable.mat");
            dirty = timetable(seconds([0; NaN; 0.02; 0.01; 1; 0.02]), ...
                [1; 2; 3; 4; 5; 6], 'VariableNames', {'ECG'});
            save(source, "dirty");

            [recording, status] = labkit.biosignal.readRecording(source);

            testCase.verifyTrue(status.ok, status.message);
            signal = recording.signals(1);
            testCase.verifyEqual(signal.time, [0; 0.01; 0.02; 0.03], "AbsTol", 1e-12);
            testCase.verifyEqual(signal.values, [1; 4; 3; 5]);
            normalization = signal.metadata.samplingNormalization;
            testCase.verifyEqual(normalization.removedNonfiniteTimeCount, 1);
            testCase.verifyEqual(normalization.removedDuplicateTimeCount, 1);
            testCase.verifyTrue(normalization.reordered);
            testCase.verifyEqual(normalization.compressedGapCount, 1);
        end

        function filtersAndDetectsRepeatedEcgPeaks(testCase)
            signal = BiosignalFacadeSpec.syntheticEcgSignal();
            filtered = labkit.biosignal.filterSignal(signal, ...
                struct("type", "bandpass", "cutoffHz", [0.5, 40]));
            defaults = labkit.biosignal.defaultEcgPeakOptions("local");
            events = labkit.biosignal.detectEcgPeaks(filtered, ...
                BiosignalFacadeSpec.with(defaults, struct( ...
                "polarity", "positive", "minDistanceSec", 0.5, "thresholdStd", 2)));

            testCase.verifyEqual(numel(filtered.values), numel(signal.values));
            testCase.verifyTrue(all(isfinite(filtered.values)));
            testCase.verifyEqual(defaults.method, "local");
            testCase.verifyGreaterThanOrEqual(numel(events.index), 7);
            testCase.verifyEqual(events.metadata.method, "local");
        end

        function buildsBeatMeasurements(testCase)
            signal = labkit.biosignal.filterSignal(BiosignalFacadeSpec.syntheticEcgSignal(), ...
                struct("type", "bandpass", "cutoffHz", [0.5, 40]));
            events = labkit.biosignal.detectEcgPeaks(signal, struct( ...
                "method", "local", "polarity", "positive", ...
                "minDistanceSec", 0.5, "thresholdStd", 2));
            segments = labkit.biosignal.segmentByEvents(signal, events, [-0.7, 0.7]);
            template = labkit.biosignal.buildTemplate(segments, struct("topN", 5));
            measurements = labkit.biosignal.measureSegments(segments, template);
            testCase.verifyGreaterThanOrEqual(size(segments.values, 2), 5);
            testCase.verifyEqual(height(measurements.perSegment), size(segments.values, 2));
            testCase.verifyTrue(isfinite(measurements.summary.SNRdBMean));
        end
    end

    methods (Static, Access = private)
        function signal = syntheticEcgSignal()
            fs = 100;
            time = (0:1 / fs:10).';
            values = 0.03 * sin(2 * pi * 1.5 * time) + 0.01 * sin(2 * pi * 17 * time);
            for peakTime = 1:9
                values = values + exp(-((time - peakTime) / 0.025).^2);
            end
            signal = struct("time", time, "values", values, "fs", fs, ...
                "name", "ECG", "displayName", "ECG", "metadata", struct());
        end

        function result = with(base, changes)
            result = base;
            fields = fieldnames(changes);
            for k = 1:numel(fields)
                result.(fields{k}) = changes.(fields{k});
            end
        end
    end
end


function writeText(path, contents)
file = fopen(path, 'w');
cleanup = onCleanup(@() fclose(file));
fprintf(file, '%s', contents);
clear cleanup
end
