function hText = showMessage(ax, message, varargin)
%SHOWMESSAGE Show a centered empty-state message in an axes.
%
% Usage:
%   hText = labkit.app.plot.showMessage(ax, message)
%   hText = labkit.app.plot.showMessage(ax, message, Name=Value)
%
% Inputs:
%   ax - Valid scalar MATLAB axes or uiaxes handle.
%   message - User-visible text scalar displayed at the axes center.
%
% Name-Value Arguments:
%   Title - Axes title text. Default: "".
%   Color - MATLAB color value for the message text. Default:
%       [0.30 0.30 0.30].
%
% Outputs:
%   hText - MATLAB text object containing the message.
%
% Description:
%   message clears the axes, resets it to linear unit limits [0 1], removes
%   ticks, and draws non-pickable text. Use it for an empty preview, loading
%   prompt, or unavailable result. Because it performs a complete clear, it is
%   not an overlay operation and does not preserve the previous zoom.
%
% Errors:
%   labkit:app:plot:InvalidAxes - ax is not a valid scalar axes handle.
%   labkit:app:plot:InvalidOptions or labkit:app:plot:InvalidOption -
%   Name-value arguments are malformed or unsupported. Invalid MATLAB text or
%   color values propagate their originating graphics error.
%
% Example:
%   fig = figure("Visible", "off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig);
%   h = labkit.app.plot.showMessage(ax, "No data", "Title", "Preview");
%   assert(string(h.String) == "No data")
%
% See also labkit.app.plot.clearAxes

    opts = parseAxesOptions(varargin, struct( ...
        'Title', "", ...
        'Color', [0.30 0.30 0.30]));
    labkit.app.plot.clearAxes(ax, 'ResetScale', true);
    xlim(ax, [0 1]);
    ylim(ax, [0 1]);
    ax.XTick = [];
    ax.YTick = [];
    title(ax, char(string(opts.Title)), 'Interpreter', 'none');
    hText = text(ax, 0.5, 0.5, string(message), ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Color', opts.Color, ...
        'Interpreter', 'none', ...
        'HitTest', 'off', ...
        'PickableParts', 'none');
end
