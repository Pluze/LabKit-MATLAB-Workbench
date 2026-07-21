function limits = fitAxesToGraphics(ax, varargin)
%FITAXESTOGRAPHICS Fit axes limits to finite plotted X/Y data.
%
% Usage:
%   limits = labkit.app.plot.fitAxesToGraphics(ax)
%   limits = labkit.app.plot.fitAxesToGraphics(ax, graphicsHandles)
%   limits = labkit.app.plot.fitAxesToGraphics(..., Name=Value)
%
% Inputs:
%   ax - Valid scalar MATLAB axes or uiaxes handle whose limits are changed.
%   graphicsHandles - Optional graphics handle array. Objects with numeric
%       XData and YData contribute to the fitted range. When omitted, all
%       current axes children are examined.
%
% Name-Value Arguments:
%   Padding - Nonnegative fractional padding added on each side of the data
%       range. Default: 0.02. For logarithmic axes, padding is computed in
%       base-10 logarithmic space.
%   EqualDataUnits - Logical value. true expands one fitted dimension so one
%       data unit occupies the same screen distance on X and Y without
%       changing the axes position. For logarithmic dimensions, equality is
%       evaluated in base-10 logarithmic space. Default: false.
%
% Outputs:
%   limits - Scalar struct with x and y fields. Each field contains the applied
%       two-element limit, or [] when that dimension had no usable data and was
%       returned to automatic limit mode.
%
% Description:
%   fit ignores nonfinite XData and YData. Nonpositive values do not contribute
%   to a logarithmic dimension. Supplying graphicsHandles lets an app exclude
%   annotations such as reference lines from the fitted range.
%
% Errors:
%   labkit:app:plot:InvalidAxes - ax is not a valid scalar axes handle.
%   labkit:app:plot:InvalidOptions or labkit:app:plot:InvalidOption -
%   Name-value arguments are malformed or unsupported. Invalid supplied
%   graphics handles are ignored when they do not expose numeric XData/YData.
%
% Example:
%   fig = figure("Visible", "off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig);
%   h = plot(ax, [1 2 3], [10 20 15]);
%   xline(ax, 100);
%   limits = labkit.app.plot.fitAxesToGraphics(ax, h, "Padding", 0);
%   assert(isequal(limits.x, [1 3]))
%
% See also labkit.app.plot.clearAxes

    validateAxesHandle(ax, 'fit');
    [handles, opts] = parseFitInputs(ax, varargin);
    [xLim, yLim] = finitePlotLimits( ...
        ax, handles, opts.Padding, logicalScalar(opts.EqualDataUnits));
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
    opts = parseAxesOptions(args, struct( ...
        'Padding', 0.02, 'EqualDataUnits', false));
end

function value = logicalScalar(value)
    if ~(islogical(value) && isscalar(value))
        error('labkit:app:plot:InvalidOption', ...
            'EqualDataUnits must be a logical scalar.');
    end
end
