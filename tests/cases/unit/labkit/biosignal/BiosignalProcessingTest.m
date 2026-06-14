classdef BiosignalProcessingTest < matlab.unittest.TestCase
    %BIOSIGNALPROCESSINGTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_biosignalProcessing(testCase)
            setupLabKitTestPath();
            verify_biosignalProcessing();
        end
    end
end

function verify_biosignalProcessing()
%TEST_BIOSIGNALPROCESSING Verify signal filtering and crop/filter composition.

    signal = syntheticSignal();
    cropped = labkit.biosignal.cropSignal(signal, [0.5 9.5]);

    filtered = labkit.biosignal.filterSignal(cropped, ...
        struct('type', 'bandpass', 'cutoffHz', [0.5 40]));
    assert(numel(filtered.values) == numel(cropped.values), ...
        'Filtering should preserve cropped signal length.');
    assert(all(isfinite(filtered.values)), ...
        'Filtering should return finite cropped signal values.');

    fullThenCrop = labkit.biosignal.cropSignal( ...
        labkit.biosignal.filterSignal(signal, struct('type', 'bandpass', 'cutoffHz', [0.5 40])), ...
        [0.5 9.5]);
    assert(numel(fullThenCrop.values) == numel(filtered.values), ...
        'Crop/filter composition should preserve the selected ROI sample count.');

    checkFilterEdgeProtection(cropped);
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

function checkFilterEdgeProtection(signal)
    edgeSignal = signal;
    n = numel(edgeSignal.values);
    drift = linspace(-1, 1, n).';
    edgeSignal.values = edgeSignal.values(:) + drift;
    edgeSignal.values(end) = edgeSignal.values(end) + 5;

    protected = labkit.biosignal.filterSignal(edgeSignal, ...
        struct('type', 'bandpass', 'cutoffHz', [0.5 40]));
    unprotected = labkit.biosignal.filterSignal(edgeSignal, ...
        struct('type', 'bandpass', 'cutoffHz', [0.5 40], 'edgeMode', 'none'));

    assert(numel(protected.values) == n, ...
        'Edge-padded filtering should preserve signal length.');
    assert(all(isfinite(protected.values)), ...
        'Edge-padded filtering should return finite values.');
    assert(norm(protected.values - unprotected.values) > eps, ...
        'Reflect edge mode should use a different path than unpadded FFT filtering.');
end
