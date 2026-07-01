% Expected caller: FLIR thermal runner and tests. Inputs are one loaded app
% item, a range-bound preset label, and fallback bounds. Output is the
% app-owned adjustment bounds for the current image controls; no GUI effects.
function bounds = rangeControlBounds(item, preset, fallbackBounds)

    if nargin < 3 || isempty(fallbackBounds)
        fallbackBounds = [-20 120];
    end
    preset = string(preset);
    switch preset
        case "-20 to 120 C"
            bounds = [-20 120];
        case "Image estimate +50%"
            bounds = estimatedExpandedBounds(item, fallbackBounds);
        case "-20 to 400 C"
            bounds = [-20 400];
        case "-100 to 2000 C"
            bounds = [-100 2000];
        otherwise
            bounds = normalizeBounds(fallbackBounds);
    end
end

function bounds = estimatedExpandedBounds(item, fallbackBounds)
    values = flir_thermal.view.valueMatrix(item);
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
    center = (lo + hi) / 2;
    halfWidth = 1.5 * width;
    bounds = [center - halfWidth, center + halfWidth];
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
