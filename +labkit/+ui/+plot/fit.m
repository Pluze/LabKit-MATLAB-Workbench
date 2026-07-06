function limits = fit(ax, varargin)
%FIT Fit axes limits to finite plotted X/Y data.
%
% App-facing contract:
%   limits = labkit.ui.plot.fit(ax)
%   limits = labkit.ui.plot.fit(ax, graphicsHandles)
%   limits = labkit.ui.plot.fit(ax, graphicsHandles, "Padding", 0.02)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   graphicsHandles - optional graphics handles whose XData/YData should drive
%       the fitted range. When omitted, finite X/Y data are collected from the
%       axes children.
%   Padding - optional fractional padding, default 0.02.
%
% Outputs:
%   limits - struct with x and y fields containing the applied limits, or empty
%       arrays when no finite data were available.
%
% Example:
%   h = plot(ax, t, y);
%   xline(ax, eventTime);
%   labkit.ui.plot.fit(ax, h);

    validateAxesHandle(ax, 'fit');
    [handles, opts] = parseFitInputs(ax, varargin);
    [xLim, yLim] = finitePlotLimits(ax, handles, opts.Padding);
    if isempty(xLim)
        xlim(ax, 'auto');
    else
        xlim(ax, xLim);
    end
    if isempty(yLim)
        ylim(ax, 'auto');
    else
        ylim(ax, yLim);
    end
    limits = struct('x', xLim, 'y', yLim);
end

function [handles, opts] = parseFitInputs(ax, args)
    handles = allchild(ax);
    if ~isempty(args) && ~(ischar(args{1}) || isstring(args{1}))
        handles = args{1};
        args = args(2:end);
    end
    opts = parseAxesOptions(args, struct('Padding', 0.02));
end
