function clear(ax, varargin)
%CLEAR Clear a plot axes before app-owned redraws.
%
% App-facing contract:
%   labkit.ui.plot.clear(ax)
%   labkit.ui.plot.clear(ax, "ResetScale", true)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   ResetScale - optional logical, default false. When true, XScale/YScale are
%       restored to linear and X/Y tick modes are restored to automatic.
%   ClearLegend - optional logical, default true. Turns the axes legend off.
%
% Outputs:
%   None.
%
% Example:
%   labkit.ui.plot.clear(ax, "ResetScale", true);
%   plot(ax, t, y);

    opts = parseAxesOptions(varargin, struct( ...
        'ResetScale', false, ...
        'ClearLegend', true));
    validateAxesHandle(ax, 'clearPlot');

    children = allchild(ax);
    for k = 1:numel(children)
        if isgraphics(children(k)) && isvalid(children(k))
            delete(children(k));
        end
    end
    cla(ax);
    clearAxesViewState(ax);
    if logical(opts.ClearLegend)
        legend(ax, 'off');
    end
    hold(ax, 'off');
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
    ax.ZLimMode = 'auto';
    ax.CLimMode = 'auto';
    if logical(opts.ResetScale)
        ax.XScale = 'linear';
        ax.YScale = 'linear';
        ax.XTickMode = 'auto';
        ax.YTickMode = 'auto';
    end
end
