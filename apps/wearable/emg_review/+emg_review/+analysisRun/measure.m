function result = measure(signal, band, pairs, windowSeconds)
% Apply equal, nonoverlapping baseline/activity windows to one channel.
    [values, edge] = emg_review.analysisRun.prepare(signal, band);
    fs = signal.fs;
    width = emg_review.regions.sampleCount(windowSeconds, fs);
    first = round(pairs * fs) + 1;
    last = first + width - 1;
    if any(~isfinite(first), 'all') || any(first <= edge, 'all') || ...
            any(last > numel(values) - edge, 'all')
        error("emg_review:WindowOutsideRecording", ...
            "Place both windows of each pair inside the usable recording. Filtered analysis excludes 0.25 s at both edges.");
    end
    if any(abs(first(:, 1) - first(:, 2)) < width)
        error("emg_review:OverlappingWindows", "Baseline and activity windows in each pair must not overlap.");
    end

    pairCount = size(pairs, 1);
    levels = zeros(pairCount, 2);
    spectralSum = [];
    for k = 1:pairCount
        samples = values((0:width - 1).' + first(k, :));
        centered = samples - mean(samples, 1);
        levels(k, :) = sqrt(mean(centered.^2, 1));
        [frequency, density] = emg_review.analysisRun.periodogram(samples, fs);
        if k == 1
            spectralSum = zeros(size(density));
        end
        spectralSum = spectralSum + density;
    end
    % The activity window includes baseline noise. Correct in linear power.
    baseline = levels(:, 1);
    activity = levels(:, 2);
    snr = nan(pairCount, 1);
    contrast = nan(pairCount, 1);
    valid = baseline > 0 & activity > baseline;
    ratio = activity(valid) ./ baseline(valid);
    snr(valid) = 10 * log10((ratio - 1) .* (ratio + 1));
    positive = baseline > 0 & activity > 0;
    contrast(positive) = 20 * log10(activity(positive) ./ baseline(positive));
    starts = (first - 1) / fs;
    ends = last / fs;
    metrics = table((1:pairCount).', starts(:, 1), ends(:, 1), ...
        starts(:, 2), ends(:, 2), baseline, activity, snr, contrast, ...
        'VariableNames', {'Pair','BaselineStart_s','BaselineEnd_s','ActivityStart_s', ...
        'ActivityEnd_s','BaselineRMS','ActivityRMS','SNR_dB','Contrast_dB'});
    result = struct('metrics', metrics, 'frequency', frequency, ...
        'density', spectralSum / pairCount, ...
        'spectrogram', timeFrequency(values, fs, edge), ...
        'preview', emg_review.sourceFiles.waveformPreview(signal.time, values));
end

function result = timeFrequency(values, fs, edge)
    % A 250 ms Hann window gives roughly 4 Hz frequency spacing.
    width = min(numel(values) - 2 * edge, max(2, round(0.25 * fs)));
    lastStart = numel(values) - edge - width + 1;
    firstStart = edge + 1;
    % Bound the displayed time-frequency grid while retaining constant hop.
    maxColumns = 600;
    hop = max([1, floor(width / 4), ceil((lastStart - firstStart) / (maxColumns - 1))]);
    starts = firstStart:hop:lastStart;
    [frequency, density] = emg_review.analysisRun.periodogram( ...
        values((0:width - 1).' + starts), fs);
    result = struct('time', (starts - 1 + (width - 1) / 2) / fs, ...
        'frequency', frequency, 'density', density, 'windowSeconds', width / fs);
end
