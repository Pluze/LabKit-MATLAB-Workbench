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
    events = labkit.biosignal.detectPeaks(filtered, ...
        struct('polarity', 'positive', 'minDistanceSec', 0.5, 'thresholdStd', 2));
    assert(numel(events.index) >= 7, 'Peak detection should find repeated synthetic beats.');

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
end

function cleanupFile(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
