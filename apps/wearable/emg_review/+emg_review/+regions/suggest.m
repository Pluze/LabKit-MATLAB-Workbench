function starts = suggest(values, fs, edge, windowSeconds, otherPairs)
% Segment the short-time RMS envelope, then pair each sustained burst with
% quiet data in the interval immediately preceding that burst.
    width = emg_review.regions.sampleCount(windowSeconds, fs);
    usable = values(edge + 1:end - edge);
    if numel(usable) < 2 * width
        error("emg_review:ShortRecording", "Two nonoverlapping windows do not fit. Reduce the window duration.");
    end

    % Match the reference protocol's envelope resolution. Short requested
    % windows still get at least two envelope frames when samples permit.
    envelopeSeconds = 0.1;
    frame = min(max(2, round(envelopeSeconds * fs)), max(2, floor(width / 2)));
    frameCount = floor(numel(usable) / frame);
    blocks = reshape(usable(1:frameCount * frame), frame, []);
    rmsValues = sqrt(mean((blocks - mean(blocks, 1)).^2, 1)).';
    % One isolated frame should neither create a burst nor split a quiet run.
    envelope = movmedian(rmsValues, 3);
    sorted = sort(envelope);
    quietReference = sorted(ceil(0.25 * frameCount));
    activityReference = sorted(ceil(0.80 * frameCount));
    spread = activityReference - quietReference;
    % Leave an undecided band between quiet and activity. Relative thresholds
    % keep selection independent of the input's calibration and units.
    minimumContrast = 1.5;
    quietLimit = min(quietReference + 0.25 * spread, 2 * quietReference);
    activityLimit = max(minimumContrast * quietReference, quietReference + 0.35 * spread);
    quiet = runs(envelope <= quietLimit, frame, width);
    active = runs(envelope > activityLimit, frame, width);

    otherPairs = otherPairs(any(otherPairs ~= 0, 2), :);
    eligible = true(numel(usable) - width + 1, 1);
    reserved = round(otherPairs * fs) - edge + 1;
    for first = reserved(:).'
        overlap = max(1, first - width + 1):min(numel(eligible), first + width - 1);
        eligible(overlap) = false;
    end
    previousEnd = 0;
    for k = 1:size(active, 1)
        burst = active(k, :);
        activityAlreadyMarked = any(reserved(:, 2) <= burst(2) & ...
            reserved(:, 2) + width - 1 >= burst(1));
        if ~activityAlreadyMarked
            activity = centeredWindow(burst, width, eligible);
            prior = find(quiet(:, 1) > previousEnd & quiet(:, 2) < burst(1));
            for j = flip(prior(:).')
                baseline = centeredWindow(quiet(j, :), width, eligible);
                if ~isempty(activity) && ~isempty(baseline)
                    starts = ([baseline activity] + edge - 1) / fs;
                    return;
                end
            end
        end
        previousEnd = burst(2);
    end
    error("emg_review:NoDistinctPair", ...
        "No unused sustained activity with a preceding quiet window was found. Shorten the windows or mark a pair manually.");
end

function ranges = runs(mask, frame, width)
    boundaries = diff([false; mask; false]);
    first = (find(boundaries == 1) - 1) * frame + 1;
    last = (find(boundaries == -1) - 1) * frame;
    fits = last - first + 1 >= width;
    ranges = [first(fits), last(fits)];
end

function start = centeredWindow(range, width, eligible)
    possible = (range(1):range(2) - width + 1).';
    possible = possible(eligible(possible));
    midpoint = (range(1) + range(2) - width + 1) / 2;
    [~, index] = min(abs(possible - midpoint));
    start = possible(index);
end
