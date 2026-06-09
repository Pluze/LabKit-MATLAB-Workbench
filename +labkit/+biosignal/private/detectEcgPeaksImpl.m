% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function events = detectEcgPeaksImpl(signal, opts)
%DETECTECGPEAKSIMPL Dispatch the ECG peak detector behind detectEcgPeaks.
%
% Called by:
%   labkit.biosignal.detectEcgPeaks
%
% Inputs:
%   signal - biosignal signal struct with time, values, and fs fields.
%   opts - options struct normalized by the public facade. Important fields
%          are method, polarity, minDistanceSec, integrationWindowSec,
%          baselineWindowSec, envelopeWindowSec, refineSearchSec,
%          rawRefineSearchSec, medianPolarityCorrection, and
%          medianReviewPeakCount.
%
% Output:
%   events - biosignalEvents struct with index, time, amplitude, score,
%            label, threshold, and metadata fields.
%
% Notes:
%   This file owns private algorithm implementations only. Keep public
%   option documentation in detectEcgPeaks/defaultEcgPeakOptions and
%   docs/biosignal.md.

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

    method = normalizeMethod(optionValue(opts, 'method', 'qrs_streaming'));
    switch method
        case "local"
            events = detectLocal(signal, x, fs, opts);
        case "pan_tompkins"
            events = detectPanTompkins(signal, x, fs, opts);
        case "qrs_streaming"
            events = detectQrsStreaming(signal, x, fs, opts);
        otherwise
            error('labkit:biosignal:UnsupportedPeakMethod', ...
                'Unsupported peak detection method: %s.', method);
    end
end

function events = detectLocal(signal, x, fs, opts)
    polarity = normalizePolarity(optionValue(opts, 'polarity', 'auto'));
    minDistanceSec = double(optionValue(opts, 'minDistanceSec', 0.05));
    minDistance = max(1, round(minDistanceSec * fs));

    [score, amplitude] = polarityScore(x, polarity);
    smoothSec = double(optionValue(opts, 'smoothSec', 0.01));
    score = movingAverage(score, max(1, round(smoothSec * fs)));

    threshold = optionValue(opts, 'threshold', []);
    if isempty(threshold)
        thresholdStd = double(optionValue(opts, 'thresholdStd', 3));
        threshold = median(score, 'omitnan') + thresholdStd * max(robustSigma(score), eps);
    end

    idx = localPeakNms(score, minDistance, threshold);
    metadata = struct('method', "local", ...
        'polarity', polarity, ...
        'minDistanceSec', minDistanceSec);
    events = makeEvents(signal, idx, amplitude, score, threshold, "peak", metadata);
end

function events = detectPanTompkins(signal, x, fs, opts)
    polarity = normalizePolarity(optionValue(opts, 'polarity', 'auto'));
    minDistanceSec = double(optionValue(opts, 'minDistanceSec', 0.25));
    minDistance = max(1, round(minDistanceSec * fs));
    if numel(x) < max(12, minDistance)
        events = emptyEventsWithMetadata("pan_tompkins");
        return;
    end

    centered = normalizeRobust(x - median(x, 'omitnan'));
    highHz = min(18, 0.45 * fs);
    lowHz = min(5, max(0.1, 0.4 * highHz));
    if highHz > lowHz
        qrsBand = fftBandpass(centered, fs, [lowHz highHz]);
    else
        qrsBand = centered - movingAverage(centered, max(1, round(0.6 * fs)));
    end

    derivative = [0; diff(qrsBand)] * fs;
    energy = derivative .^ 2;
    integrationWindowSec = double(optionValue(opts, 'integrationWindowSec', 0.150));
    integrated = movingAverage(energy, max(1, round(integrationWindowSec * fs)));

    candidateDistance = max(1, round(max(0.12, 0.7 * minDistanceSec) * fs));
    candidateIdx = localPeakNms(integrated, candidateDistance, 0);
    if isempty(candidateIdx)
        events = emptyEventsWithMetadata("pan_tompkins");
        return;
    end

    initN = min(numel(integrated), max(round(2 * fs), min(round(8 * fs), numel(integrated))));
    initValues = integrated(1:initN);
    signalLevel = percentileValue(initValues, 90);
    noiseLevel = median(initValues, 'omitnan');
    if ~isfinite(signalLevel) || signalLevel <= noiseLevel
        signalLevel = max(initValues);
    end
    threshold = noiseLevel + 0.25 * max(signalLevel - noiseLevel, eps);
    refineRadius = max(1, round(double(optionValue(opts, 'refineSearchSec', 0.120)) * fs));
    acceptedIdx = zeros(0, 1);
    acceptedScore = zeros(0, 1);
    rejectedIdx = zeros(0, 1);
    rejectedScore = zeros(0, 1);

    for k = 1:numel(candidateIdx)
        candidate = candidateIdx(k);
        candidateScore = integrated(candidate);
        anchor = snapPeak(qrsBand, candidate, refineRadius, polarity);
        if candidateScore >= threshold
            [acceptedIdx, acceptedScore] = acceptRefractory( ...
                acceptedIdx, acceptedScore, anchor, candidateScore, minDistance);
            signalLevel = 0.125 * candidateScore + 0.875 * signalLevel;
        else
            rejectedIdx(end+1, 1) = anchor;
            rejectedScore(end+1, 1) = candidateScore;
            noiseLevel = 0.125 * candidateScore + 0.875 * noiseLevel;
        end
        threshold = noiseLevel + 0.25 * max(signalLevel - noiseLevel, eps);

        [acceptedIdx, acceptedScore] = searchBackIfNeeded(acceptedIdx, acceptedScore, ...
            rejectedIdx, rejectedScore, minDistance, fs, 1.66, 0.5 * threshold);
    end

    idx = cleanupPeaks(acceptedIdx, x, minDistance, polarity);
    idx = snapPeaksToRaw(idx, x, fs, opts, polarity, minDistance);
    metadata = struct('method', "pan_tompkins", ...
        'polarity', polarity, ...
        'minDistanceSec', minDistanceSec, ...
        'bandpassHz', [lowHz highHz], ...
        'integrationWindowSec', integrationWindowSec);
    events = makeEvents(signal, idx, x, integrated, threshold, "qrs", metadata);
end

function events = detectQrsStreaming(signal, x, fs, opts)
    polarity = normalizePolarity(optionValue(opts, 'polarity', 'auto'));
    minDistanceSec = double(optionValue(opts, 'minDistanceSec', 0.25));
    minDistance = max(1, round(minDistanceSec * fs));
    if numel(x) < max(12, minDistance)
        events = emptyEventsWithMetadata("qrs_streaming");
        return;
    end

    centered = normalizeRobust(x - median(x, 'omitnan'));
    baselineWindowSec = double(optionValue(opts, 'baselineWindowSec', 0.600));
    highPassed = centered - causalAverage(centered, max(1, round(baselineWindowSec * fs)));
    slope = [0; diff(highPassed)];
    envelopeWindowSec = double(optionValue(opts, 'envelopeWindowSec', 0.080));
    envelope = causalAverage(abs(slope), max(1, round(envelopeWindowSec * fs)));

    lookahead = max(1, round(double(optionValue(opts, 'lookaheadSec', 0.080)) * fs));
    snapRadius = max(1, round(double(optionValue(opts, 'refineSearchSec', 0.090)) * fs));
    initN = min(numel(envelope), max(round(2 * fs), min(round(8 * fs), numel(envelope))));
    initValues = envelope(1:initN);
    signalLevel = percentileValue(initValues, 90);
    noiseLevel = median(initValues, 'omitnan');
    if ~isfinite(signalLevel) || signalLevel <= noiseLevel
        signalLevel = max(initValues);
    end
    threshold = noiseLevel + 0.35 * max(signalLevel - noiseLevel, eps);

    acceptedIdx = zeros(0, 1);
    acceptedScore = zeros(0, 1);
    templateSegments = zeros(0, 0);
    templateRadius = max(2, round(0.120 * fs));
    minTemplateScore = double(optionValue(opts, 'minTemplateScore', 0.45));

    i = lookahead + 1;
    stopIdx = numel(envelope) - lookahead;
    while i <= stopIdx
        candidateScore = envelope(i);
        isCandidate = candidateScore >= threshold && ...
            candidateScore >= max(envelope(i-lookahead:i-1)) && ...
            candidateScore > max(envelope(i+1:i+lookahead));
        if ~isCandidate
            i = i + 1;
            continue;
        end

        anchor = snapPeak(highPassed, i, snapRadius, polarity);
        templateScore = templateSimilarity(highPassed, anchor, templateRadius, templateSegments);
        templateReady = size(templateSegments, 2) >= 4;
        passesTemplate = ~templateReady || templateScore >= minTemplateScore || candidateScore >= 1.5 * threshold;

        if isempty(acceptedIdx) || anchor - acceptedIdx(end) >= minDistance
            if passesTemplate
                acceptedIdx(end+1, 1) = anchor;
                acceptedScore(end+1, 1) = candidateScore;
                segment = normalizedSegment(highPassed, anchor, templateRadius);
                if ~isempty(segment)
                    templateSegments(:, end+1) = segment;
                end
                signalLevel = 0.125 * candidateScore + 0.875 * signalLevel;
            else
                noiseLevel = 0.125 * candidateScore + 0.875 * noiseLevel;
            end
        elseif candidateScore > acceptedScore(end)
            acceptedIdx(end) = anchor;
            acceptedScore(end) = candidateScore;
            signalLevel = 0.125 * candidateScore + 0.875 * signalLevel;
        else
            noiseLevel = 0.125 * candidateScore + 0.875 * noiseLevel;
        end
        threshold = noiseLevel + 0.35 * max(signalLevel - noiseLevel, eps);

        i = i + lookahead;
    end

    idx = cleanupPeaks(acceptedIdx, x, minDistance, polarity);
    idx = snapPeaksToRaw(idx, x, fs, opts, polarity, minDistance);
    idx = correctStreamingMedianPolarity(idx, x, fs, opts, polarity, minDistance);
    metadata = struct('method', "qrs_streaming", ...
        'polarity', polarity, ...
        'minDistanceSec', minDistanceSec, ...
        'baselineWindowSec', baselineWindowSec, ...
        'envelopeWindowSec', envelopeWindowSec, ...
        'templateQcEnabled', true);
    events = makeEvents(signal, idx, x, envelope, threshold, "qrs", metadata);
end

function events = makeEvents(signal, idx, amplitudeTrace, scoreTrace, threshold, label, metadata)
    idx = idx(:);
    idx = idx(idx >= 1 & idx <= numel(signal.values));
    idx = unique(idx, 'stable');
    scoreIdx = min(max(idx, 1), numel(scoreTrace));
    events = struct();
    events.type = "biosignalEvents";
    events.index = idx;
    events.time = signal.time(idx);
    events.amplitude = amplitudeTrace(idx);
    events.score = scoreTrace(scoreIdx);
    events.label = repmat(string(label), numel(idx), 1);
    events.threshold = threshold;
    events.metadata = metadata;
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

function events = emptyEventsWithMetadata(method)
    events = emptyEvents();
    events.metadata = struct('method', string(method));
end

function validateSignal(signal)
    assert(isstruct(signal) && isfield(signal, 'time') && ...
        isfield(signal, 'values') && isfield(signal, 'fs'), ...
        'labkit:biosignal:InvalidSignal', ...
        'Signal must contain time, values, and fs fields.');
end

function method = normalizeMethod(value)
    method = lower(strtrim(string(value)));
    method = regexprep(method, '[\s\-/+]+', '_');
    switch method
        case {"", "auto", "local", "local_peaks", "simple", "simple_local"}
            method = "local";
        case {"pantompkin", "pan_tompkin", "pan_tompkins", "pan_tompkins_qrs"}
            method = "pan_tompkins";
        case {"streaming", "streaming_qrs", "qrs_streaming"}
            method = "qrs_streaming";
    end
end

function polarity = normalizePolarity(value)
    polarity = lower(strtrim(string(value)));
    switch polarity
        case {"positive", "negative", "absolute", "auto"}
            return;
        otherwise
            error('labkit:biosignal:UnsupportedPolarity', ...
                'Unsupported peak polarity: %s.', polarity);
    end
end

function [score, amplitude] = polarityScore(x, polarity)
    centered = x - median(x, 'omitnan');
    amplitude = x;
    switch polarity
        case "positive"
            score = centered;
        case "negative"
            score = -centered;
        case "absolute"
            score = abs(centered);
        otherwise
            if abs(max(centered)) >= abs(min(centered))
                score = centered;
            else
                score = -centered;
            end
    end
end

function y = normalizeRobust(x)
    sigma = robustSigma(x);
    if sigma > 0
        y = x ./ sigma;
    else
        y = x;
    end
end

function sigma = robustSigma(x)
    x = x(isfinite(x));
    if isempty(x)
        sigma = 0;
        return;
    end
    med = median(x, 'omitnan');
    sigma = 1.4826 * median(abs(x - med), 'omitnan');
    if ~isfinite(sigma) || sigma <= 0
        sigma = std(x, 'omitnan');
    end
    if ~isfinite(sigma)
        sigma = 0;
    end
end

function y = movingAverage(x, width)
    width = max(1, round(width));
    if width <= 1
        y = x(:);
        return;
    end
    y = conv(x(:), ones(width, 1) / width, 'same');
end

function y = causalAverage(x, width)
    width = max(1, round(width));
    if width <= 1
        y = x(:);
        return;
    end
    y = filter(ones(width, 1) / width, 1, x(:));
end

function y = fftBandpass(x, fs, cutoffHz)
    cutoffHz = sort(double(cutoffHz(:)));
    n = numel(x);
    freq = (0:n-1).' * fs / n;
    foldedFreq = min(freq, fs - freq);
    mask = foldedFreq >= cutoffHz(1) & foldedFreq <= cutoffHz(end);
    y = real(ifft(fft(x(:)) .* mask));
end

function idx = localPeakNms(score, minDistance, minHeight)
    score = score(:);
    if numel(score) < 3
        idx = zeros(0, 1);
        return;
    end
    candidates = find(score(2:end-1) >= score(1:end-2) & ...
        score(2:end-1) > score(3:end) & score(2:end-1) >= minHeight) + 1;
    if isempty(candidates)
        idx = zeros(0, 1);
        return;
    end
    [~, order] = sort(score(candidates), 'descend');
    accepted = false(size(candidates));
    blocked = false(size(candidates));
    for k = 1:numel(order)
        i = order(k);
        if blocked(i)
            continue;
        end
        accepted(i) = true;
        blocked = blocked | abs(candidates - candidates(i)) < minDistance;
    end
    idx = sort(candidates(accepted));
end

function value = percentileValue(x, percentile)
    x = sort(x(isfinite(x)));
    if isempty(x)
        value = NaN;
        return;
    end
    q = min(max(double(percentile) / 100, 0), 1);
    pos = 1 + (numel(x) - 1) * q;
    lo = floor(pos);
    hi = ceil(pos);
    if lo == hi
        value = x(lo);
    else
        value = x(lo) + (x(hi) - x(lo)) * (pos - lo);
    end
end

function idx = snapPeak(trace, centerIdx, radius, polarity)
    i1 = max(1, centerIdx - radius);
    i2 = min(numel(trace), centerIdx + radius);
    window = trace(i1:i2);
    switch polarity
        case "positive"
            [~, local] = max(window);
        case "negative"
            [~, local] = min(window);
        otherwise
            [~, local] = max(abs(window));
    end
    idx = i1 + local - 1;
end

function idx = snapPeaksToRaw(idx, x, fs, opts, polarity, minDistance)
    idx = idx(:);
    if isempty(idx)
        return;
    end
    radiusSec = double(optionValue(opts, 'rawRefineSearchSec', 0.020));
    if ~isfinite(radiusSec) || radiusSec <= 0
        return;
    end
    radius = max(1, round(radiusSec * fs));
    for k = 1:numel(idx)
        idx(k) = snapRawPeak(x, idx(k), radius, polarity);
    end
    idx = cleanupPeaks(idx, x, minDistance, polarity);
end

function idx = correctStreamingMedianPolarity(idx, x, fs, opts, polarity, minDistance)
    idx = idx(:);
    if isempty(idx) || polarity == "negative" || polarity == "absolute"
        return;
    end
    enabled = logical(optionValue(opts, 'medianPolarityCorrection', true));
    if ~enabled
        return;
    end

    med = median(x, 'omitnan');
    if ~isfinite(med)
        return;
    end
    reviewCount = max(1, round(double(optionValue(opts, 'medianReviewPeakCount', 3))));
    radiusSec = double(optionValue(opts, 'rawRefineSearchSec', 0.020));
    radius = max(1, round(max(radiusSec, 0.020) * fs));

    for k = 1:numel(idx)
        first = max(1, k - reviewCount + 1);
        review = first:k;
        lowMask = x(idx(review)) <= med;
        if ~any(lowMask)
            continue;
        end
        lowPositions = review(lowMask);
        for p = lowPositions(:).'
            idx(p) = snapRawPeakAboveMedian(x, idx(p), radius, med);
        end
    end
    idx = cleanupPeaks(idx, x, minDistance, "positive");
end

function idx = snapRawPeak(x, centerIdx, radius, polarity)
    i1 = max(1, centerIdx - radius);
    i2 = min(numel(x), centerIdx + radius);
    window = x(i1:i2);
    switch polarity
        case "negative"
            [~, local] = min(window);
        case "positive"
            [~, local] = max(window);
        otherwise
            med = median(x, 'omitnan');
            [~, local] = max(abs(window - med));
    end
    idx = i1 + local - 1;
end

function idx = snapRawPeakAboveMedian(x, centerIdx, radius, med)
    i1 = max(1, centerIdx - radius);
    i2 = min(numel(x), centerIdx + radius);
    window = x(i1:i2);
    above = window > med;
    if any(above)
        candidates = find(above);
        [~, best] = max(window(above));
        local = candidates(best);
    else
        [~, local] = max(window);
    end
    idx = i1 + local - 1;
end

function [idx, score] = acceptRefractory(idx, score, candidateIdx, candidateScore, minDistance)
    if isempty(idx) || candidateIdx - idx(end) >= minDistance
        idx(end+1, 1) = candidateIdx;
        score(end+1, 1) = candidateScore;
    elseif candidateScore > score(end)
        idx(end) = candidateIdx;
        score(end) = candidateScore;
    end
end

function [idx, score] = searchBackIfNeeded(idx, score, rejectedIdx, rejectedScore, minDistance, fs, rrMissFrac, minScore)
    if numel(idx) < 3 || isempty(rejectedIdx)
        return;
    end
    rr = diff(idx) ./ fs;
    rrStart = max(1, numel(rr) - 7);
    rrRef = median(rr(rrStart:end), 'omitnan');
    if ~isfinite(rrRef) || rrRef <= 0 || (idx(end) - idx(end-1)) / fs <= rrMissFrac * rrRef
        return;
    end
    gapMask = rejectedIdx > idx(end-1) + minDistance & ...
        rejectedIdx < idx(end) - minDistance & ...
        rejectedScore >= minScore;
    gapCandidates = find(gapMask);
    if isempty(gapCandidates)
        return;
    end
    [~, bestLocal] = max(rejectedScore(gapCandidates));
    selected = gapCandidates(bestLocal);
    idx(end+1, 1) = rejectedIdx(selected);
    score(end+1, 1) = rejectedScore(selected);
    [idx, order] = sort(idx);
    score = score(order);
end

function idx = cleanupPeaks(idx, x, minDistance, polarity)
    idx = idx(:);
    idx = idx(idx >= 1 & idx <= numel(x));
    if isempty(idx)
        return;
    end
    idx = sort(unique(idx));
    switch polarity
        case "positive"
            quality = x(idx);
        case "negative"
            quality = -x(idx);
        otherwise
            quality = abs(x(idx) - median(x, 'omitnan'));
    end
    [~, order] = sort(quality, 'descend');
    accepted = false(size(idx));
    blocked = false(size(idx));
    for k = 1:numel(order)
        i = order(k);
        if blocked(i)
            continue;
        end
        accepted(i) = true;
        blocked = blocked | abs(idx - idx(i)) < minDistance;
    end
    idx = sort(idx(accepted));
end

function score = templateSimilarity(x, anchor, radius, templateSegments)
    if isempty(templateSegments)
        score = 1;
        return;
    end
    segment = normalizedSegment(x, anchor, radius);
    if isempty(segment)
        score = -Inf;
        return;
    end
    template = median(templateSegments, 2, 'omitnan');
    score = cosineSimilarity(segment, template);
end

function segment = normalizedSegment(x, anchor, radius)
    i1 = anchor - radius;
    i2 = anchor + radius;
    if i1 < 1 || i2 > numel(x)
        segment = [];
        return;
    end
    segment = x(i1:i2);
    segment = segment - mean(segment, 'omitnan');
    scale = norm(segment);
    if scale > 0
        segment = segment ./ scale;
    end
end

function score = cosineSimilarity(a, b)
    good = isfinite(a) & isfinite(b);
    if nnz(good) < 3
        score = -Inf;
        return;
    end
    a = a(good);
    b = b(good);
    denom = norm(a) * norm(b);
    if denom <= 0
        score = -Inf;
    else
        score = dot(a, b) / denom;
    end
end
