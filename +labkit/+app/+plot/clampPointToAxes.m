function xy = clampPointToAxes(ax, xy, varargin)
%CLAMPPOINTTOAXES Keep data coordinates inside the visible axes box.
%
% Usage:
%   xyOut = labkit.app.plot.clampPointToAxes(ax, xy)
%   xyOut = labkit.app.plot.clampPointToAxes(ax, xy, Name=Value)
%
% Inputs:
%   ax - Valid scalar MATLAB axes or uiaxes handle. Its XLim, YLim, XScale,
%       YScale, XDir, and YDir properties define the visible box.
%   xy - N-by-2 numeric matrix of [x y] data coordinates.
%
% Name-Value Arguments:
%   Padding - Minimum distance from each axes edge, expressed as a fraction of
%       the visible width or height. Values are limited to [0, 0.49]. Default:
%       0.04.
%
% Outputs:
%   xy - N-by-2 data coordinates, shown as xyOut in the usage syntax. Each
%       point is moved only as far as needed to satisfy Padding.
%
% Description:
%   clampData is useful for labels and annotations that must remain readable
%   near an axes boundary. Conversion through normalized axes coordinates keeps
%   the result visually consistent on logarithmic or reversed axes.
%
% Errors:
%   labkit:app:plot:InvalidAxes - ax is not a valid scalar axes handle.
%   labkit:app:plot:InvalidPointPairs - xy is not an N-by-2 numeric array.
%   labkit:app:plot:InvalidOptions or labkit:app:plot:InvalidOption -
%   Name-value arguments are malformed or unsupported.
%
% Example:
%   fig = figure("Visible", "off");
%   cleanup = onCleanup(@() close(fig));
%   ax = axes(fig, "XLim", [0 10], "YLim", [0 20]);
%   xy = labkit.app.plot.clampPointToAxes(ax, [-2 25], "Padding", 0.1);
%   assert(isequal(xy, [1 18]))
%
% See also labkit.app.plot.offsetPointByAxesFraction

    opts = parseAxesOptions(varargin, struct('Padding', 0.04));
    pad = max(0, min(0.49, double(opts.Padding)));
    uv = dataToFraction(ax, xy);
    uv = min(max(uv, pad), 1 - pad);
    xy = fractionToData(ax, uv);
end
