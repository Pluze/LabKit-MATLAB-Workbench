% Private UI runtime helper. Zooms an axes around one pointer location.
function didZoom = zoomAxesAtPoint(ax, point, scrollCount, varargin)
%
% Internal contract:
%   didZoom = zoomAxesAtPoint(ax, [x y], scrollCount, ...
%       "Bounds", [xmin xmax ymin ymax], "MinSpan", [minX minY], ...
%       "ZoomBase", 1.20)
%
% Inputs:
%   ax - target UIAxes or axes handle.
%   point - 1-by-2 data-space [x y] anchor point. The anchor must be inside
%       the current XLim/YLim.
%   scrollCount - MATLAB scroll-wheel count. Positive counts zoom out;
%       negative counts zoom in.
%   Bounds - optional [xmin xmax ymin ymax] clamp bounds. When omitted, image
%       bounds are inferred from displayed image children when possible.
%   MinSpan - optional [minX minY] minimum axis spans in data units for
%       linear axes. Default is 10 data units for bounded/image axes and no
%       practical minimum for unbounded plot axes.
%   ZoomBase - optional scalar zoom base, default 1.20.
%   ZoomAxes - optional "xy", "x", or "y". Default is "xy", except plot axes
%       whose x-axis label is time-like default to "x".
%
% Output:
%   didZoom - true when the axes limits were updated.

    didZoom = false;
    if ~isValidHandle(ax) || isempty(point) || numel(point) < 2
        return;
    end

    opts = parseOptions(varargin);
    zoomBase = optionValue(opts, 'ZoomBase', 1.20);
    if ~isnumeric(zoomBase) || ~isscalar(zoomBase) || ...
            ~isfinite(zoomBase) || zoomBase <= 0
        error('labkit:app:interaction:InvalidZoomBase', ...
            'ZoomBase must be a positive finite scalar.');
    end

    scrollCount = double(scrollCount);
    if ~isfinite(scrollCount) || scrollCount == 0
        return;
    end

    point = double(point(:).');
    x = point(1);
    y = point(2);
    if ~isfinite(x) || ~isfinite(y)
        return;
    end

    bounds = optionValue(opts, 'Bounds', []);
    if isempty(bounds)
        bounds = imageBounds(ax);
    else
        bounds = normalizeBounds(bounds);
    end

    minSpan = optionValue(opts, 'MinSpan', defaultMinSpan(bounds));
    minSpan = normalizeMinSpan(minSpan);
    zoomAxes = normalizeZoomAxes(optionValue(opts, 'ZoomAxes', ...
        defaultZoomAxes(ax, bounds)));

    currentX = double(ax.XLim);
    currentY = double(ax.YLim);
    if ~pointInsideLimits(x, y, currentX, currentY)
        return;
    end

    xBounds = [];
    yBounds = [];
    if ~isempty(bounds)
        xBounds = bounds(1:2);
        yBounds = bounds(3:4);
    end

    newX = currentX;
    newY = currentY;
    okX = true;
    okY = true;
    if contains(zoomAxes, "x")
        [newX, okX] = zoomOneAxis(currentX, x, scrollCount, ...
            string(ax.XScale), xBounds, minSpan(1), zoomBase);
    end
    if contains(zoomAxes, "y")
        [newY, okY] = zoomOneAxis(currentY, y, scrollCount, ...
            string(ax.YScale), yBounds, minSpan(2), zoomBase);
    end
    if ~(okX && okY)
        return;
    end

    ax.XLim = newX;
    ax.YLim = newY;
    didZoom = ~isequal(currentX, newX) || ~isequal(currentY, newY);
end

function opts = parseOptions(args)
    opts = struct();
    if isempty(args)
        return;
    end
    if isscalar(args) && isstruct(args{1})
        opts = args{1};
        return;
    end
    if mod(numel(args), 2) ~= 0
        error('labkit:app:interaction:InvalidOptions', ...
            'zoomAxesAtPoint options must be name/value pairs.');
    end
    for k = 1:2:numel(args)
        opts.(char(string(args{k}))) = args{k + 1};
    end
end

function [limits, ok] = zoomOneAxis(currentLimits, anchor, scrollCount, ...
        axisScale, bounds, minSpan, zoomBase)
    ok = false;
    limits = currentLimits;
    if numel(currentLimits) ~= 2 || any(~isfinite(currentLimits)) || ...
            diff(currentLimits) <= 0
        return;
    end

    if axisScale == "log"
        if anchor <= 0 || any(currentLimits <= 0)
            return;
        end
        workLimits = log10(currentLimits);
        workAnchor = log10(anchor);
        workBounds = [];
        workMinSpan = 0;
        if ~isempty(bounds) && all(bounds > 0)
            workBounds = log10(bounds);
        end
    else
        workLimits = currentLimits;
        workAnchor = anchor;
        workBounds = bounds;
        workMinSpan = minSpan;
    end

    span = diff(workLimits);
    if span <= 0 || ~isfinite(span)
        return;
    end
    factor = zoomBase ^ scrollCount;
    newSpan = max(span * factor, workMinSpan);
    if ~isempty(workBounds)
        fullSpan = diff(workBounds);
        if fullSpan <= 0 || ~isfinite(fullSpan)
            return;
        end
        newSpan = min(newSpan, fullSpan);
    end

    anchorFraction = (workAnchor - workLimits(1)) ./ span;
    anchorFraction = min(max(anchorFraction, 0), 1);
    workNew = [workAnchor - anchorFraction .* newSpan, ...
        workAnchor + (1 - anchorFraction) .* newSpan];
    if ~isempty(workBounds)
        workNew = clampLimits(workNew, workBounds);
    end

    if axisScale == "log"
        limits = 10 .^ workNew;
    else
        limits = workNew;
    end
    ok = all(isfinite(limits)) && diff(limits) > 0;
end

function bounds = imageBounds(ax)
    images = findobj(ax, 'Type', 'Image');
    if isempty(images)
        bounds = [];
        return;
    end

    bounds = [Inf, -Inf, Inf, -Inf];
    for k = 1:numel(images)
        img = images(k);
        if ~isValidHandle(img) || ~isprop(img, 'CData')
            continue;
        end
        dataSize = size(img.CData);
        xLim = imageDataLimits(img.XData, dataSize(2));
        yLim = imageDataLimits(img.YData, dataSize(1));
        bounds = [min(bounds(1), xLim(1)), max(bounds(2), xLim(2)), ...
            min(bounds(3), yLim(1)), max(bounds(4), yLim(2))];
    end
    if any(~isfinite(bounds)) || bounds(2) <= bounds(1) || bounds(4) <= bounds(3)
        bounds = [];
    end
end

function limits = imageDataLimits(values, count)
    values = double(values(:).');
    if isempty(values)
        limits = [0.5, double(count) + 0.5];
        return;
    end
    if isscalar(values)
        limits = [values(1) - 0.5, values(1) + double(count) - 0.5];
        return;
    end
    edgeValues = [values(1), values(end)];
    if count > 1
        step = abs(diff(edgeValues)) ./ double(count - 1);
    else
        step = 1;
    end
    limits = [min(edgeValues) - step ./ 2, max(edgeValues) + step ./ 2];
end

function tf = pointInsideLimits(x, y, xLimits, yLimits)
    tf = x >= xLimits(1) && x <= xLimits(2) && ...
        y >= yLimits(1) && y <= yLimits(2);
end

function limits = clampLimits(limits, fullLimits)
    span = diff(limits);
    fullSpan = diff(fullLimits);
    if span >= fullSpan
        limits = fullLimits;
        return;
    end
    if limits(1) < fullLimits(1)
        limits = [fullLimits(1), fullLimits(1) + span];
    end
    if limits(2) > fullLimits(2)
        limits = [fullLimits(2) - span, fullLimits(2)];
    end
end

function bounds = normalizeBounds(bounds)
    if ~isnumeric(bounds) || numel(bounds) ~= 4
        error('labkit:app:interaction:InvalidBounds', ...
            'Bounds must be [xmin xmax ymin ymax].');
    end
    bounds = double(bounds(:).');
    if any(~isfinite(bounds)) || bounds(2) <= bounds(1) || bounds(4) <= bounds(3)
        error('labkit:app:interaction:InvalidBounds', ...
            'Bounds must contain finite increasing x and y limits.');
    end
end

function minSpan = normalizeMinSpan(minSpan)
    if isempty(minSpan)
        minSpan = [0, 0];
    end
    if ~isnumeric(minSpan) || ~(isscalar(minSpan) || numel(minSpan) == 2)
        error('labkit:app:interaction:InvalidMinSpan', ...
            'MinSpan must be a scalar or [minX minY].');
    end
    minSpan = double(minSpan(:).');
    if isscalar(minSpan)
        minSpan = [minSpan, minSpan];
    end
    minSpan(~isfinite(minSpan) | minSpan < 0) = 0;
end

function minSpan = defaultMinSpan(bounds)
    if isempty(bounds)
        minSpan = [0, 0];
    else
        minSpan = [min(10, diff(bounds(1:2))), ...
            min(10, diff(bounds(3:4)))];
    end
end

function zoomAxes = defaultZoomAxes(ax, bounds)
    if isempty(bounds) && hasTimeXLabel(ax)
        zoomAxes = "x";
    else
        zoomAxes = "xy";
    end
end

function tf = hasTimeXLabel(ax)
    tf = false;
    try
        label = string(ax.XLabel.String);
    catch
        return;
    end
    label = lower(strjoin(label(:).', " "));
    tf = contains(label, "time");
end

function zoomAxes = normalizeZoomAxes(value)
    zoomAxes = lower(strtrim(string(value)));
    if zoomAxes == "both"
        zoomAxes = "xy";
    end
    if ~isscalar(zoomAxes) || ~ismember(zoomAxes, ["xy", "x", "y"])
        error('labkit:app:interaction:InvalidZoomAxes', ...
            'ZoomAxes must be "xy", "x", or "y".');
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function tf = isValidHandle(h)
    tf = ~isempty(h) && all(isvalid(h));
end
