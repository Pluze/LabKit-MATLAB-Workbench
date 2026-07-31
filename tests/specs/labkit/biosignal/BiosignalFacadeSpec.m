classdef BiosignalFacadeSpec < matlab.unittest.TestCase
    %BIOSIGNALFACADESPEC Specify public recording and ECG-analysis behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
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
            writetable(table((1001:1005).', [0; 1; 0; -1; 0], ...
                'VariableNames', {'Sample', 'ECG'}), noTime);
            writetable(table((0:10:40).', [0; 1; 0; -1; 0], ...
                'VariableNames', {'time_ms', 'ECG'}), milliseconds);

            [synthetic, syntheticStatus] = labkit.biosignal.readRecording(noTime);
            [timed, timedStatus] = labkit.biosignal.readRecording(milliseconds);
            syntheticEcg = labkit.biosignal.getChannel(synthetic, "ECG");
            timedEcg = labkit.biosignal.getChannel(timed, "ECG");

            testCase.verifyTrue(syntheticStatus.ok, syntheticStatus.message);
            testCase.verifyEqual(synthetic.metadata.timeSource, "synthetic_sample_index");
            testCase.verifyEqual(syntheticEcg.time, (0:4).');
            testCase.verifyTrue(timedStatus.ok, timedStatus.message);
            testCase.verifyEqual(timed.metadata.timeUnit, "milliseconds");
            testCase.verifyEqual(timedEcg.fs, 100, "AbsTol", 1e-9);
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

        function buildsBeatMeasurementsAndGroupComparisons(testCase)
            signal = labkit.biosignal.filterSignal(BiosignalFacadeSpec.syntheticEcgSignal(), ...
                struct("type", "bandpass", "cutoffHz", [0.5, 40]));
            events = labkit.biosignal.detectEcgPeaks(signal, struct( ...
                "method", "local", "polarity", "positive", ...
                "minDistanceSec", 0.5, "thresholdStd", 2));
            segments = labkit.biosignal.segmentByEvents(signal, events, [-0.7, 0.7]);
            template = labkit.biosignal.buildTemplate(segments, struct("topN", 5));
            measurements = labkit.biosignal.measureSegments(segments, template);
            values = [measurements.perSegment.SNRdB; measurements.perSegment.SNRdB + 3];
            groups = [repmat("A", height(measurements.perSegment), 1); ...
                repmat("B", height(measurements.perSegment), 1)];
            comparison = labkit.biosignal.compareGroups(values, groups);

            testCase.verifyGreaterThanOrEqual(size(segments.values, 2), 5);
            testCase.verifyEqual(height(measurements.perSegment), size(segments.values, 2));
            testCase.verifyTrue(isfinite(measurements.summary.SNRdBMean));
            testCase.verifyEqual([height(comparison.summary), height(comparison.pairwise)], [2, 1]);
            testCase.verifyGreaterThanOrEqual(comparison.pairwise.P, 0);
            testCase.verifyLessThanOrEqual(comparison.pairwise.P, 1);
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
