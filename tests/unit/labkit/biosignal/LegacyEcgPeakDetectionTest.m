classdef LegacyEcgPeakDetectionTest < matlab.unittest.TestCase
    %LEGACYECGPEAKDETECTIONTEST Official wrapper for migrated legacy coverage.

    methods (Test, TestTags = {'Unit'})
        function test_ecgPeakDetection(testCase)
            setupLabKitTestPath();
            legacy_test_ecgPeakDetection();
        end
    end
end

function legacy_test_ecgPeakDetection()
%TEST_ECGPEAKDETECTION Verify ECG peak detector methods and post-processing.

    signal = labkit.biosignal.filterSignal(syntheticSignal(), ...
        struct('type', 'bandpass', 'cutoffHz', [0.5 40]));
    defaults = labkit.biosignal.defaultEcgPeakOptions("local");
    assert(defaults.method == "local", 'Default ECG peak options should preserve requested method.');
    assert(isfield(defaults, 'minDistanceSec'), ...
        'Default ECG peak options should expose minDistanceSec.');

    events = labkit.biosignal.detectEcgPeaks(signal, ...
        mergeStruct(defaults, struct('polarity', 'positive', ...
        'minDistanceSec', 0.5, 'thresholdStd', 2)));
    assert(numel(events.index) >= 7, 'Peak detection should find repeated synthetic beats.');

    checkEcgPeakMethods(signal);
    checkEcgPeakPostProcessing();
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

function checkEcgPeakPostProcessing()
    fs = 500;
    t = (0:1/fs:5).';
    x = 0.02 * sin(2*pi*0.4*t);
    for peakTime = 1:4
        x = x + exp(-((t - peakTime) / 0.010).^2);
        x = x - 1.8 * exp(-((t - (peakTime - 0.012)) / 0.004).^2);
    end
    signal = struct('time', t, 'values', x, 'fs', fs, ...
        'name', "ECG", 'displayName', "ECG", 'metadata', struct());

    panOpts = labkit.biosignal.defaultEcgPeakOptions("pan-tompkins");
    panOpts.polarity = "positive";
    panOpts.minDistanceSec = 0.5;
    panEvents = labkit.biosignal.detectEcgPeaks(signal, panOpts);
    assert(~isempty(panEvents.index), 'Pan-Tompkins should detect synthetic ECG peaks.');
    rawRadius = round(panOpts.rawRefineSearchSec * fs);
    for k = 1:numel(panEvents.index)
        idx = panEvents.index(k);
        i1 = max(1, idx - rawRadius);
        i2 = min(numel(x), idx + rawRadius);
        assert(x(idx) == max(x(i1:i2)), ...
            'Pan-Tompkins final anchors should snap to the raw signal peak.');
    end

    streamOpts = labkit.biosignal.defaultEcgPeakOptions("qrs-streaming");
    streamOpts.polarity = "auto";
    streamOpts.minDistanceSec = 0.5;
    streamEvents = labkit.biosignal.detectEcgPeaks(signal, streamOpts);
    assert(numel(streamEvents.index) >= 3, ...
        'Streaming ECG detector should detect repeated synthetic peaks.');
    assert(all(streamEvents.amplitude > median(x, 'omitnan')), ...
        'Streaming median review should correct accidental inverted peak anchors.');
end
