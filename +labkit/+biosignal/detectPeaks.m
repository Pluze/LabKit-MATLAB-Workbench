function events = detectPeaks(signal, opts)
%DETECTPEAKS Detect generic waveform peaks as event anchors.

    if nargin < 2
        opts = struct();
    end
    validateSignal(signal);

    x = fillVectorMissing(double(signal.values(:)));
    fs = double(signal.fs);
    if isempty(x) || ~isfinite(fs) || fs <= 0
        events = emptyEvents();
        return;
    end

    polarity = lower(string(optionValue(opts, 'polarity', 'auto')));
    minDistanceSec = double(optionValue(opts, 'minDistanceSec', 0.25));
    minDistance = max(1, round(minDistanceSec * fs));

    centered = x - median(x, 'omitnan');
    switch polarity
        case "positive"
            score = centered;
            amplitude = x;
        case "negative"
            score = -centered;
            amplitude = x;
        case "absolute"
            score = abs(centered);
            amplitude = x;
        case "auto"
            if abs(max(centered)) >= abs(min(centered))
                score = centered;
            else
                score = -centered;
            end
            amplitude = x;
        otherwise
            error('labkit:biosignal:UnsupportedPolarity', ...
                'Unsupported peak polarity: %s.', polarity);
    end

    smoothSec = double(optionValue(opts, 'smoothSec', 0.02));
    smoothWindow = max(1, round(smoothSec * fs));
    if smoothWindow > 1
        kernel = ones(smoothWindow, 1) / smoothWindow;
        score = conv(score, kernel, 'same');
    end

    threshold = optionValue(opts, 'threshold', []);
    if isempty(threshold)
        robustSigma = 1.4826 * median(abs(score - median(score, 'omitnan')), 'omitnan');
        thresholdStd = double(optionValue(opts, 'thresholdStd', 3));
        threshold = median(score, 'omitnan') + thresholdStd * max(robustSigma, eps);
    end

    candidateIdx = find(score(2:end-1) >= score(1:end-2) & ...
        score(2:end-1) > score(3:end) & score(2:end-1) >= threshold) + 1;
    if isempty(candidateIdx)
        events = emptyEvents();
        events.threshold = threshold;
        return;
    end

    [~, order] = sort(score(candidateIdx), 'descend');
    accepted = false(size(candidateIdx));
    blocked = false(size(candidateIdx));
    for k = 1:numel(order)
        i = order(k);
        if blocked(i)
            continue;
        end
        accepted(i) = true;
        blocked = blocked | abs(candidateIdx - candidateIdx(i)) < minDistance;
    end
    idx = sort(candidateIdx(accepted));

    events = struct();
    events.type = "biosignalEvents";
    events.index = idx(:);
    events.time = signal.time(idx(:));
    events.amplitude = amplitude(idx(:));
    events.score = score(idx(:));
    events.label = repmat("peak", numel(idx), 1);
    events.threshold = threshold;
    events.metadata = struct('polarity', polarity, 'minDistanceSec', minDistanceSec);
end

function events = emptyEvents()
    events = struct( ...
        'type', "biosignalEvents", ...
        'index', zeros(0, 1), ...
        'time', zeros(0, 1), ...
        'amplitude', zeros(0, 1), ...
        'score', zeros(0, 1), ...
        'label', strings(0, 1), ...
        'threshold', NaN, ...
        'metadata', struct());
end

function validateSignal(signal)
    assert(isstruct(signal) && isfield(signal, 'time') && ...
        isfield(signal, 'values') && isfield(signal, 'fs'), ...
        'labkit:biosignal:InvalidSignal', ...
        'Signal must contain time, values, and fs fields.');
end
