% Private UI plot axes helper. Expected caller: fit. Inputs are an axes,
% graphics handles, and fractional padding. Outputs are X/Y limits fitted to
% finite plotted data.
function [xLim, yLim] = finitePlotLimits(ax, handles, padding)
    [x, y] = collectFiniteXY(handles);
    xLim = paddedDataLimits(x, ax.XScale, padding);
    yLim = paddedDataLimits(y, ax.YScale, padding);
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
