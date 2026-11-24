function starts = suggest(values, fs, edge, windowSeconds, otherPairs)
% Select the quietest window, then the strongest nonoverlapping window.
% A global shift improves cancellation in rolling mean-removed RMS power.
    width = emg_review.regions.sampleCount(windowSeconds, fs);
    usable = values(edge + 1:end - edge);
    if numel(usable) < 2 * width
        error("emg_review:ShortRecording", "Two nonoverlapping windows do not fit. Reduce the window duration.");
    end
    shifted = usable - mean(usable);
    sumValues = [0; cumsum(shifted)];
    sumSquares = [0; cumsum(shifted.^2)];
    meanValues = (sumValues(1 + width:end) - sumValues(1:end - width)) / width;
    meanSquares = (sumSquares(1 + width:end) - sumSquares(1:end - width)) / width;
    power = max(0, meanSquares - meanValues.^2);
    % A quiet window near the center must leave room for a full partner.
    lastStart = numel(power);
    possible = (1:lastStart).';
    eligible = true(lastStart, 1);
    reserved = round(otherPairs(:) * fs) - edge + 1;
    for k = 1:numel(reserved)
        overlap = max(1, reserved(k) - width + 1): ...
            min(lastStart, reserved(k) + width - 1);
        eligible(overlap) = false;
    end
    firstEligible = find(eligible, 1, 'first');
    lastEligible = find(eligible, 1, 'last');
    if isempty(firstEligible) || lastEligible - firstEligible < width
        error("emg_review:NoUnusedWindows", ...
            "Two unused windows do not fit. Reduce the window duration or edit the pair manually.");
    end
    canPair = eligible & (possible >= firstEligible + width | possible <= lastEligible - width);
    quietPower = power;
    quietPower(~canPair) = Inf;
    [~, quiet] = min(quietPower);
    power(~eligible | abs(possible - quiet) < width) = -Inf;
    [~, active] = max(power);
    starts = ([quiet active] + edge - 1) / fs;
end
