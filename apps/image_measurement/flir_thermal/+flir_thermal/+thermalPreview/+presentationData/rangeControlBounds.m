% Expected caller: FLIR thermal runner and tests. Inputs are one loaded app
% item, a range-bound preset label, and fallback bounds. Output is the
% app-owned adjustment bounds for the current image controls; no GUI effects.
function bounds = rangeControlBounds(item, preset, fallbackBounds)

    if nargin < 3 || isempty(fallbackBounds)
        fallbackBounds = [-20 120];
    end
    preset = string(preset);
    labels = flir_thermal.thermalPreview.presentationData.rangeControlLabels();
    switch preset
        case labels.standardPreset
            bounds = [-20 120];
        case labels.estimatedPreset
            bounds = estimatedExpandedBounds(item, fallbackBounds);
        case labels.highPreset
            bounds = [-20 400];
        case labels.widePreset
            bounds = [-100 2000];
        otherwise
            bounds = normalizeBounds(fallbackBounds);
    end
end

function bounds = estimatedExpandedBounds(item, fallbackBounds)
    values = flir_thermal.thermalPreview.presentationData.valueMatrix(item);
    values = values(isfinite(values));
    if isempty(values)
        bounds = normalizeBounds(fallbackBounds);
        return;
    end
    lo = min(values);
    hi = max(values);
    width = hi - lo;
    if width <= 0
        bounds = [lo - 1, hi + 1];
        return;
    end
    padding = width;
    bounds = [lo - padding, hi + padding];
end

function bounds = normalizeBounds(bounds)
    bounds = double(bounds(:)).';
    if numel(bounds) ~= 2 || ~all(isfinite(bounds))
        bounds = [-20 120];
        return;
    end
    bounds = sort(bounds);
    if bounds(2) <= bounds(1)
        bounds(2) = bounds(1) + 1;
    end
end
