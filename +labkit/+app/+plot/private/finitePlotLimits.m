% Private UI plot axes helper. Expected caller: fit. Inputs are an axes,
% graphics handles, and fractional padding. Outputs are X/Y limits fitted to
% finite plotted data.
function [xLim, yLim] = finitePlotLimits(ax, handles, padding, equalDataUnits)
    [x, y] = collectFiniteXY(handles);
    xLim = paddedDataLimits(x, ax.XScale, padding);
    yLim = paddedDataLimits(y, ax.YScale, padding);
    if equalDataUnits && ~isempty(xLim) && ~isempty(yLim)
        [xLim, yLim] = equalDataUnitLimits(ax, xLim, yLim);
    end
end

function [xLim, yLim] = equalDataUnitLimits(ax, xLim, yLim)
    position = resolveAxesPixelPosition(ax);
    if numel(position) ~= 4 || position(3) <= 0 || position(4) <= 0
        return;
    end
    xLog = string(ax.XScale) == "log";
    yLog = string(ax.YScale) == "log";
    xWork = scaleLimits(xLim, xLog);
    yWork = scaleLimits(yLim, yLog);
    if isempty(xWork) || isempty(yWork)
        return;
    end
    targetRatio = position(3) / position(4);
    xSpan = diff(xWork);
    ySpan = diff(yWork);
    if xSpan / ySpan < targetRatio
        xWork = expandAroundCenter(xWork, ySpan * targetRatio);
    else
        yWork = expandAroundCenter(yWork, xSpan / targetRatio);
    end
    xLim = unscaleLimits(xWork, xLog);
    yLim = unscaleLimits(yWork, yLog);
end

function position = resolveAxesPixelPosition(ax)
    position = [NaN NaN NaN NaN];
    for attempt = 1:3
        drawnow
        position = getpixelposition(ax, true);
        if numel(position) == 4 && position(3) > 0 && position(4) > 0
            return;
        end
        if attempt == 3
            break;
        end
    end
    fallback = ax.Position;
    if numel(fallback) == 4 && fallback(3) > 0 && fallback(4) > 0
        position = double(fallback);
    end
end

function limits = scaleLimits(limits, isLog)
    if isLog
        if any(limits <= 0)
            limits = [];
            return;
        end
        limits = log10(limits);
    end
end

function limits = unscaleLimits(limits, isLog)
    if isLog
        limits = 10 .^ limits;
    end
end

function limits = expandAroundCenter(limits, span)
    center = mean(limits);
    limits = center + [-0.5, 0.5] * span;
end

function [x, y] = collectFiniteXY(handles)
    x = [];
    y = [];
    handles = handles(:).';
    for k = 1:numel(handles)
        h = handles(k);
        if ~isgraphics(h) || ~isprop(h, 'XData') || ~isprop(h, 'YData')
            continue;
        end
        childX = h.XData;
        childY = h.YData;
        if isnumeric(childX) && isnumeric(childY)
            x = [x; childX(:)];
            y = [y; childY(:)];
        end
    end
    x = x(isfinite(x));
    y = y(isfinite(y));
end

function lim = paddedDataLimits(values, scaleMode, padding)
    values = values(:);
    if strcmp(char(string(scaleMode)), 'log')
        values = values(values > 0);
        if isempty(values)
            lim = [];
            return;
        end
        logValues = log10(values);
        logLim = paddedLinearLimits(logValues, padding);
        lim = 10 .^ logLim;
    else
        values = values(isfinite(values));
        if isempty(values)
            lim = [];
            return;
        end
        lim = paddedLinearLimits(values, padding);
    end
end

function lim = paddedLinearLimits(values, padding)
    lo = min(values);
    hi = max(values);
    padding = max(0, double(padding));
    if lo == hi
        pad = max(abs(lo), 1) * max(padding, 0.05);
    else
        pad = (hi - lo) * padding;
    end
    lim = [lo - pad, hi + pad];
end
