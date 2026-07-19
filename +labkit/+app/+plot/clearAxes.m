function clearAxes(ax, varargin)
%CLEARAXES Prepare an axes for an app-owned redraw.
%
% Usage:
%   labkit.app.plot.clearAxes(ax)
%   labkit.app.plot.clearAxes(ax, Name=Value)
%
% Inputs:
%   ax - Valid scalar MATLAB axes or uiaxes handle to clear.
%
% Name-Value Arguments:
%   ResetScale - Logical value. true restores linear X/Y scales and automatic
%       X/Y tick modes. false preserves those four properties. Default: false.
%   ClearLegend - Logical value. true turns the legend off. Default: true.
%
% Outputs:
%   None.
%
% Description:
%   clear deletes plotted children, clears LabKit's cached image home view,
%   releases hold, and returns XLim, YLim, ZLim, and CLim to automatic mode.
%   Labels and other axes decorations follow MATLAB cla behavior. Call it once
%   at the start of a complete redraw, not when adding an overlay that should
%   preserve the current zoom.
%
% Errors:
%   labkit:app:plot:InvalidAxes - ax is not a valid scalar axes handle.
%   labkit:app:plot:InvalidOptions or labkit:app:plot:InvalidOption -
%   Name-value arguments are malformed or unsupported. MATLAB graphics errors
%   raised while clearing a valid axes propagate to the caller.
%
% Example:
%   fig = figure("Visible", "off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig);
%   plot(ax, 1:3, [2 1 3]);
%   labkit.app.plot.clearAxes(ax, "ResetScale", true);
%   assert(isempty(ax.Children))
%
% See also labkit.app.plot.fitAxesToGraphics, labkit.app.plot.showMessage

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
