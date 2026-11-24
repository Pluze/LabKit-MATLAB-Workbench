function preview = waveformPreview(time, values)
% Keep the time-ordered extrema in each display bin so narrow peaks survive.
    maxBins = 3000;
    count = numel(time);
    if count > 2 * maxBins
        binEdges = round(linspace(0, count, maxBins + 1));
        indices = zeros(2, maxBins);
        for k = 1:maxBins
            first = binEdges(k) + 1;
            range = first:binEdges(k + 1);
            [~, lo] = min(values(range));
            [~, hi] = max(values(range));
            indices(:, k) = sort([lo; hi]) + first - 1;
        end
        time = time(indices(:));
        values = values(indices(:));
    end
    preview = struct('time', time, 'values', values);
end
