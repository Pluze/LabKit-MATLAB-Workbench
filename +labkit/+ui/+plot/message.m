function hText = message(ax, message, varargin)
%MESSAGE Show a centered empty-state message in an axes.
%
% App-facing contract:
%   hText = labkit.ui.plot.message(ax, message)
%   hText = labkit.ui.plot.message(ax, message, "Title", titleText)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   message - user-visible message text owned by the calling app.
%   Title - optional axes title, default empty.
%   Color - optional text color, default [0.30 0.30 0.30].
%
% Outputs:
%   hText - text object used for the message.

    opts = parseAxesOptions(varargin, struct( ...
        'Title', "", ...
        'Color', [0.30 0.30 0.30]));
    labkit.ui.plot.clear(ax, 'ResetScale', true);
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
