function info = plotXY(ax, x, y, labels, opts)
%PLOTXY Plot one prepared X/Y numeric series.
%
% Usage:
%   info = plotXY(ax, x, y, struct('x','Time','y','Voltage'));
%
% Inputs:
%   ax - target axes.
%   x, y - numeric vectors of equal length.
%   labels - optional struct with title, x, and y fields; defaults blank.
%   opts - optional struct.
%
% Options:
%   holdPlot - logical, default false; false clears axes before plotting.
%   showGrid - logical or MATLAB grid value, default true.
%   lineWidth - positive scalar, default 1.2.
%
% Output:
%   info - status struct with ok, message, x/y vectors, and x/y names.

    if nargin < 4
        labels = struct();
    end
    if nargin < 5
        opts = struct();
    end
    labels = fillLabels(labels);
    opts = fillOptions(opts);

    info = struct();
    info.ok = false;
    info.message = '';
    info.x = [];
    info.y = [];
    info.xName = labels.x;
    info.yName = labels.y;

    if isempty(x) || isempty(y) || numel(x) ~= numel(y)
        info.message = 'invalid X/Y';
        return;
    end

    x = x(:);
    y = y(:);

    if ~opts.holdPlot
        cla(ax);
    end

    plot(ax, x, y, 'LineWidth', opts.lineWidth);
    grid(ax, opts.showGrid);
    title(ax, labels.title, 'Interpreter', 'none');
    xlabel(ax, labels.x, 'Interpreter', 'none');
    ylabel(ax, labels.y, 'Interpreter', 'none');

    info.ok = true;
    info.message = 'OK';
    info.x = x;
    info.y = y;
end

function labels = fillLabels(labels)
    if ~isfield(labels, 'title')
        labels.title = '';
    end
    if ~isfield(labels, 'x')
        labels.x = '';
    end
    if ~isfield(labels, 'y')
        labels.y = '';
    end
end

function opts = fillOptions(opts)
    if ~isfield(opts, 'holdPlot')
        opts.holdPlot = false;
    end
    if ~isfield(opts, 'showGrid')
        opts.showGrid = true;
    end
    if ~isfield(opts, 'lineWidth')
        opts.lineWidth = 1.2;
    end
end
