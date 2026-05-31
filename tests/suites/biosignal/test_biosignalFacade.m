function test_biosignalFacade()
%TEST_BIOSIGNALFACADE Verify biosignal loading, processing, SNR, and stats.

    tempFile = [tempname(tempdir) '.mat'];
    cleaner = onCleanup(@() cleanupFile(tempFile));

    fs = 100;
    t = (0:1/fs:10).';
    x = 0.03 * sin(2*pi*1.5*t);
    for peakTime = 1:9
        x = x + exp(-((t - peakTime) / 0.025).^2);
    end
    x = x + 0.01 * sin(2*pi*17*t);
    TT = timetable(seconds(t), x, 'VariableNames', {'ECG'}); %#ok<NASGU>
    save(tempFile, 'TT');

    [recording, status] = labkit.biosignal.readRecording(tempFile);
    assert(status.ok, status.message);
    channels = labkit.biosignal.listChannels(recording);
    assert(numel(channels) == 1, 'Expected one numeric timetable channel.');

    sig = labkit.biosignal.getChannel(recording, channels{1});
    assert(abs(sig.fs - fs) < 1e-9, 'Sample rate should be inferred from timetable row times.');

    cropped = labkit.biosignal.cropSignal(sig, [0.5 9.5]);
    assert(cropped.time(1) == 0, 'Cropped signal time should restart at zero.');
    assert(numel(cropped.values) < numel(sig.values), 'Cropped signal should contain fewer samples.');

    filtered = labkit.biosignal.filterSignal(cropped, ...
        struct('type', 'bandpass', 'cutoffHz', [0.5 40]));
    defaults = labkit.biosignal.defaultEcgPeakOptions("local");
    assert(defaults.method == "local", 'Default ECG peak options should preserve requested method.');
    assert(isfield(defaults, 'minDistanceSec'), ...
        'Default ECG peak options should expose minDistanceSec.');
    events = labkit.biosignal.detectEcgPeaks(filtered, ...
        mergeStruct(defaults, struct('polarity', 'positive', ...
        'minDistanceSec', 0.5, 'thresholdStd', 2)));
    assert(numel(events.index) >= 7, 'Peak detection should find repeated synthetic beats.');
    checkEcgPeakMethods(filtered);

    segments = labkit.biosignal.segmentByEvents(filtered, events, [-0.7 0.7]);
    assert(size(segments.values, 2) >= 5, 'Segmentation should keep interior beats.');

    template = labkit.biosignal.buildTemplate(segments, struct('topN', 5));
    measurements = labkit.biosignal.measureSegments(segments, template);
    assert(height(measurements.perSegment) == size(segments.values, 2), ...
        'Per-segment measurements should match valid segments.');
    assert(isfinite(measurements.summary.SNRdBMean), ...
        'Synthetic beat SNR summary should be finite.');

    values = [measurements.perSegment.SNRdB; measurements.perSegment.SNRdB + 3];
    groups = [repmat("A", height(measurements.perSegment), 1); ...
        repmat("B", height(measurements.perSegment), 1)];
    comparison = labkit.biosignal.compareGroups(values, groups);
    assert(height(comparison.summary) == 2, 'Two comparison groups should be summarized.');
    assert(height(comparison.pairwise) == 1, 'Two groups should produce one pairwise comparison.');
    assert(comparison.pairwise.P <= 1 && comparison.pairwise.P >= 0, ...
        'Pairwise comparison p-value should be bounded.');

    checkDelimitedTimeInference();
end

function out = mergeStruct(a, b)
    out = a;
    fields = fieldnames(b);
    for k = 1:numel(fields)
        out.(fields{k}) = b.(fields{k});
    end
end

function checkEcgPeakMethods(signal)
    methods = {'local', 'pan-tompkins', 'qrs-streaming'};
    for k = 1:numel(methods)
        events = labkit.biosignal.detectEcgPeaks(signal, ...
            struct('method', methods{k}, 'polarity', 'positive', ...
            'minDistanceSec', 0.5, 'thresholdStd', 2));
        assert(numel(events.index) >= 6, ...
            'ECG peak method %s should find repeated synthetic beats.', methods{k});
        assert(isfield(events.metadata, 'method'), ...
            'ECG peak method %s should report metadata.method.', methods{k});
    end
end

function cleanupFile(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end

function checkDelimitedTimeInference()
    csvNoTime = [tempname(tempdir) '.csv'];
    csvMs = [tempname(tempdir) '.csv'];
    csvHeaderless = [tempname(tempdir) '.csv'];
    csvArduino = [tempname(tempdir) '.csv'];
    csvPreamble = [tempname(tempdir) '.csv'];
    csvTimeRepair = [tempname(tempdir) '.csv'];
    cleaner = onCleanup(@() cleanupFiles({csvNoTime, csvMs, csvHeaderless, ...
        csvArduino, csvPreamble, csvTimeRepair}));

    sample = (1001:1005).';
    ecg = [0; 1; 0; -1; 0];
    T = table(sample, ecg, 'VariableNames', {'Sample', 'ECG'});
    writetable(T, csvNoTime);

    [recording, status] = labkit.biosignal.readRecording(csvNoTime);
    assert(status.ok, status.message);
    channels = labkit.biosignal.listChannels(recording);
    assert(any(strcmpi(channels, 'Sample')), ...
        ['A monotonic non-time column should remain a signal channel. Found: ' strjoin(channels, ', ')]);
    assertHasChannel(recording, 'ECG', 'CSV without time-like column');
    sig = labkit.biosignal.getChannel(recording, 'ECG');
    assert(isequal(sig.time, (0:4).'), ...
        'CSV without a time-like column should use synthetic sample-index time.');
    assert(recording.metadata.timeSource == "synthetic_sample_index", ...
        'CSV without a time-like column should report synthetic time.');

    time_ms = (0:10:40).';
    T = table(time_ms, ecg, 'VariableNames', {'time_ms', 'ECG'});
    writetable(T, csvMs);

    [recording, status] = labkit.biosignal.readRecording(csvMs);
    assert(status.ok, status.message);
    assertHasChannel(recording, 'ECG', 'time_ms CSV');
    sig = labkit.biosignal.getChannel(recording, 'ECG');
    assert(abs(sig.fs - 100) < 1e-9, ...
        'time_ms columns should be converted from milliseconds to seconds.');
    assert(recording.metadata.timeUnit == "milliseconds", ...
        'Millisecond time columns should report their inferred unit.');

    writeLines(csvHeaderless, ["0,-0.1"; "0.0005,-0.2"; "0.0010,-0.3"]);
    [recording, status] = labkit.biosignal.readRecording(csvHeaderless);
    assert(status.ok, status.message);
    sig = labkit.biosignal.getChannel(recording, 'Var2');
    assert(abs(sig.fs - 2000) < 1e-9, ...
        sprintf('Headerless two-column signal CSV should treat the first column as seconds; fs=%.12g source=%s timeColumn=%s importHeader=%d.', ...
        sig.fs, recording.metadata.timeSource, recording.metadata.timeColumn, ...
        recording.metadata.importHasHeader));

    writeLines(csvArduino, ["I0,I1,I2"; ...
        "1048387.625000,477.000000,537.000000"; ...
        "1048388.625000,420.000000,539.000000"; ...
        "1048389.625000,373.000000,540.000000"]);
    [recording, status] = labkit.biosignal.readRecording(csvArduino);
    assert(status.ok, status.message);
    sig = labkit.biosignal.getChannel(recording, 'I1');
    assert(abs(sig.fs - 1000) < 1e-9, ...
        sprintf('Arduino I0/I1/I2 signal CSV should treat I0 as millisecond time; fs=%.12g source=%s timeColumn=%s unit=%s header=%d channels=%s.', ...
        sig.fs, recording.metadata.timeSource, recording.metadata.timeColumn, recording.metadata.timeUnit, ...
        recording.metadata.importHasHeader, strjoin(labkit.biosignal.listChannels(recording), '|')));

    writeLines(csvPreamble, ["MAX86178reg0x11,MAX86178reg0x12,0"; ...
        "0x02,0x00,0x01"; ...
        "start time,1776697565615"; ...
        "timestamp,sampleNum,ECG,"; ...
        "1776697565635.000000,1,627.000000,,,"; ...
        "1776697565635.002000,2,594.000000,,,"; ...
        "1776697565635.004000,3,618.000000,,," ]);
    [recording, status] = labkit.biosignal.readRecording(csvPreamble);
    assert(status.ok, status.message);
    assertHasChannel(recording, 'ECG', 'MAX86178-style CSV');
    sig = labkit.biosignal.getChannel(recording, 'ECG');
    assert(abs(sig.fs - 500) < 1e-9, ...
        sprintf(['MAX86178-style CSV preamble should be skipped and timestamp should drive time; ' ...
        'fs=%.12g source=%s unit=%s timeColumn=%s time=[%s].'], ...
        sig.fs, recording.metadata.timeSource, recording.metadata.timeUnit, ...
        recording.metadata.timeColumn, sprintf('%.12g ', sig.time)));

    writeLines(csvTimeRepair, ["timestamp,ECG"; ...
        "1000,0"; ...
        "1001,1"; ...
        "1002,0"; ...
        "900,-1"; ...
        "901,0"; ...
        "3000,1"]);
    [recording, status] = labkit.biosignal.readRecording(csvTimeRepair, ...
        struct('timeUnit', 'milliseconds'));
    assert(status.ok, status.message);
    assertHasChannel(recording, 'ECG', 'timestamp repair CSV');
    sig = labkit.biosignal.getChannel(recording, 'ECG');
    assert(all(diff(sig.time) > 0), ...
        'CSV timestamp repair should produce a strictly increasing app time axis.');
    assert(recording.metadata.timeRepair.repairedBackwardCount == 1, ...
        'CSV timestamp repair should report one backward timestamp repair.');
    assert(recording.metadata.timeRepair.largeGapCount == 1, ...
        'CSV timestamp repair should report one retained large positive gap.');
end

function cleanupFiles(filepaths)
    for k = 1:numel(filepaths)
        cleanupFile(filepaths{k});
    end
end

function writeLines(filepath, lines)
    fid = fopen(filepath, 'w');
    assert(fid > 0, 'Could not create temporary CSV fixture.');
    cleaner = onCleanup(@() fclose(fid));
    for k = 1:numel(lines)
        fprintf(fid, '%s\n', char(lines(k)));
    end
end

function assertHasChannel(recording, channel, context)
    channels = labkit.biosignal.listChannels(recording);
    assert(any(strcmp(channels, channel)), ...
        '%s should expose channel %s. Found: %s.', ...
        context, channel, strjoin(channels, ', '));
end
