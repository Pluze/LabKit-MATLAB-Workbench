function applyAxesViewportPolicy(ax, policy)
%APPLYAXESVIEWPORTPOLICY Apply a LabKit UI axes viewport policy.
%
% App-facing contract:
%   labkit.ui.view.applyAxesViewportPolicy(ax, policy)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   policy - viewport policy. Supported values are:
%       "curve" or "auto" - fit X/Y limits to finite plotted curve data.
%       "preserve" - leave current X/Y limits unchanged.
%       "image" - leave image viewport handling to drawImage.
%
% Output:
%   None.
%
% Example:
%   plot(ax, t, y);
%   labkit.ui.view.applyAxesViewportPolicy(ax, "curve");

    if nargin < 2
        policy = "curve";
    end

    switch lower(char(string(policy)))
        case {'curve', 'auto', 'tight'}
            [xLim, yLim] = curveDataLimits(ax);
            if isempty(xLim) || isempty(yLim)
                xlim(ax, 'auto');
                ylim(ax, 'auto');
            else
                xlim(ax, xLim);
                ylim(ax, yLim);
            end
        case {'preserve', 'image'}
            return;
        otherwise
            error('labkit:ui:view:InvalidViewportPolicy', ...
                'Unsupported axes viewport policy "%s".', char(string(policy)));
    end
end

function [xLim, yLim] = curveDataLimits(ax)
    x = [];
    y = [];
    children = allchild(ax);
    for k = 1:numel(children)
        child = children(k);
        if ~isprop(child, 'XData') || ~isprop(child, 'YData')
            continue;
        end
        childX = child.XData;
        childY = child.YData;
        if isnumeric(childX) && isnumeric(childY)
            x = [x; childX(:)];
            y = [y; childY(:)];
        end
    end
    x = x(isfinite(x));
    y = y(isfinite(y));
    xLim = paddedLimits(x);
    yLim = paddedLimits(y);
end

function lim = paddedLimits(values)
    if isempty(values)
        lim = [];
        return;
    end
    lo = min(values);
    hi = max(values);
    if lo == hi
        pad = max(abs(lo), 1) * 0.05;
    else
        pad = (hi - lo) * 0.02;
    end
    lim = [lo - pad, hi + pad];
end
