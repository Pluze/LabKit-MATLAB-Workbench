function [lower, supported] = recommendFrequency(items, fullLower)
% Display-only heuristic: find a resolved arc descent followed by a large tail.
% These shape thresholds suppress small reversals; they are UI choices, not
% circuit parameters or a claim that a detected feature is an electrochemical arc.
minimumSamples = 12; % Enough samples to resolve ascent, descent, and tail.
smoothingSamples = 3; % Median suppresses isolated spikes without fitting data.
minimumDropFraction = .30; % Require a substantial peak-to-valley descent.
tailToPeakRatio = 3; % Recommend cropping only when the tail dominates the arc.
minimumDescentDecades = .30; % Descent must span about a factor of two in frequency.
minimumRiseRatio = 2; % Reject peaks already present at the high-frequency boundary.
candidates = NaN(1, numel(items));
for k = 1:numel(items)
    f = items(k).freq_Hz(:);
    y = items(k).negZimag_ohm(:);
    x = items(k).Zreal_ohm(:);
    valid = isfinite(f) & f > 0 & isfinite(x) & isfinite(y);
    f = f(valid); y = y(valid);
    if numel(f) < minimumSamples || numel(unique(f)) ~= numel(f), continue; end
    [f, order] = sort(f, "descend");
    rawY = y(order);
    y = movmedian(rawY, smoothingSamples);
    bestPeak = 0;
    cutoff = NaN;
    for valley = 6:numel(f)-3
        if y(valley) < 0 || y(valley) > y(valley-1) || y(valley) >= y(valley+1)
            continue
        end
        [peak, peakIndex] = max(y(1:valley-3));
        resolvedArc = peak > 0 && peakIndex >= 3 && ...
            peak >= minimumRiseRatio * max(y(1), 0) && ...
            y(valley) <= (1-minimumDropFraction) * peak && ...
            log10(f(peakIndex)/f(valley)) >= minimumDescentDecades;
        dominantTail = median(y(end-2:end)) >= tailToPeakRatio * peak;
        if resolvedArc && dominantTail && peak > bestPeak
            bestPeak = peak;
            [~, localMinimum] = min(rawY(valley-1:valley+1));
            cutoff = f(valley-2+localMinimum);
        end
    end
    if isfinite(cutoff), candidates(k) = log10(cutoff); end
end
candidates = candidates(isfinite(candidates));
supported = numel(candidates);
lower = fullLower;
if supported > 0
    % The lowest proposed cutoff retains the resolved descents of every
    % supporting curve, using one common comparison window for the overlay.
    lower = min(candidates);
end
end
