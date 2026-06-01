function test_biosignalSegmentsMeasurements()
%TEST_BIOSIGNALSEGMENTSMEASUREMENTS Verify segments, templates, measurements, and groups.

    signal = labkit.biosignal.filterSignal(syntheticSignal(), ...
        struct('type', 'bandpass', 'cutoffHz', [0.5 40]));
    events = labkit.biosignal.detectEcgPeaks(signal, ...
        struct('method', 'local', 'polarity', 'positive', ...
        'minDistanceSec', 0.5, 'thresholdStd', 2));

    segments = labkit.biosignal.segmentByEvents(signal, events, [-0.7 0.7]);
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

function signal = syntheticSignal()
    fs = 100;
    t = (0:1/fs:10).';
    x = 0.03 * sin(2*pi*1.5*t);
    for peakTime = 1:9
        x = x + exp(-((t - peakTime) / 0.025).^2);
    end
    x = x + 0.01 * sin(2*pi*17*t);
    signal = struct('time', t, 'values', x, 'fs', fs, ...
        'name', "ECG", 'displayName', "ECG", 'metadata', struct());
end
