function xy = offsetData(ax, xy, offsetFraction)
%OFFSETDATA Move data coordinates by normalized axes fractions.
%
% Usage:
%   xyOut = labkit.ui.plot.offsetData(ax, xy, offsetFraction)
%
% Inputs:
%   ax - Valid scalar MATLAB axes or uiaxes handle. Its current limits, scales,
%       and directions define the coordinate conversion.
%   xy - N-by-2 numeric matrix of [x y] data coordinates.
%   offsetFraction - 1-by-2 or N-by-2 axes-fraction offsets. One row is reused
%       for every point; otherwise the row count must match xy. For example,
%       [0.03 -0.04] moves a label slightly right and down in visual axes
%       space, including on log or reversed axes.
%
% Outputs:
%   xy - N-by-2 offset coordinates in data units, shown as xyOut in the usage
%       syntax. Values are not clamped to the visible axes box.
%
% Description:
%   offsetData expresses annotation spacing in visual axes fractions instead of
%   data units. This keeps the apparent offset stable as data ranges change and
%   correctly handles logarithmic and reversed axes.
%
% Errors:
%   labkit:ui:plot:InvalidAxes - ax is not a valid scalar axes handle.
%   labkit:ui:plot:InvalidPointPairs - xy is not an N-by-2 numeric array.
%   labkit:ui:plot:InvalidPointOffsets - offsetFraction is neither one row nor
%   one row per point.
%
% Example:
%   fig = figure("Visible", "off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig, "XLim", [0 10], "YLim", [0 20]);
%   xy = labkit.ui.plot.offsetData(ax, [5 10], [0.1 -0.1]);
%   assert(isequal(xy, [6 8]))
%
% See also labkit.ui.plot.clampData

    uv = dataToFraction(ax, xy);
    offsetFraction = normalizePointOffsets(offsetFraction, size(uv, 1));
    xy = fractionToData(ax, uv + offsetFraction);
end
