function points = offsetPointByAxesFraction( ...
        axesHandle, points, offsetFraction)
%OFFSETPOINTBYAXESFRACTION Offset data points in normalized visual axes space.
%
% Usage:
%   points = labkit.app.plot.offsetPointByAxesFraction( ...
%       axesHandle,points,offsetFraction)
%
% Inputs:
%   axesHandle - Valid scalar axes or uiaxes.
%   points - N-by-2 numeric [x y] data coordinates.
%   offsetFraction - One or N rows of normalized axes offsets.
%
% Outputs:
%   points - Offset N-by-2 data coordinates.
%
% Description:
%   Converts through normalized visual axes space so offsets remain stable on
%   linear, logarithmic, and reversed axes.
%
% Errors:
%   Throws labkit:app:plot:* for invalid axes, points, or offsets.
%
% Example:
%   fig = figure(Visible="off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig, XLim=[0 10], YLim=[0 20]);
%   point = labkit.app.plot.offsetPointByAxesFraction( ...
%       ax, [5 10], [0.1 -0.1]);
%   assert(isequal(point, [6 8]))
%
% See also labkit.app.plot.clampPointToAxes
points = labkit.ui.plot.offsetData(axesHandle, points, offsetFraction);
end
