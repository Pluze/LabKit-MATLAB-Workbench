function points = clampPointToAxes(axesHandle, points, varargin)
%CLAMPPOINTTOAXES Keep data points inside the visible axes box.
%
% Usage:
%   points = labkit.app.plot.clampPointToAxes( ...
%       axesHandle,points,Name=Value)
%
% Inputs:
%   axesHandle - Valid scalar axes or uiaxes.
%   points - N-by-2 numeric [x y] data coordinates.
%
% Options:
%   Padding - Fractional distance from each edge in [0,0.49]. Default: 0.04.
%
% Outputs:
%   points - Clamped N-by-2 data coordinates.
%
% Description:
%   Converts through normalized visual axes space for consistent behavior on
%   linear, logarithmic, and reversed axes.
%
% Errors:
%   Throws labkit:app:plot:* for invalid axes, points, or options.
%
% Example:
%   fig = figure(Visible="off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig, XLim=[0 10], YLim=[0 20]);
%   point = labkit.app.plot.clampPointToAxes( ...
%       ax, [-2 25], Padding=0.1);
%   assert(isequal(point, [1 18]))
%
% See also labkit.app.plot.offsetPointByAxesFraction
points = labkit.ui.plot.clampData(axesHandle, points, varargin{:});
end
