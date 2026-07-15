% Private UI plot helper used by public coordinate operations.
function uv = dataToFraction(ax, xy)
%
% App-facing contract:
%   uv = labkit.ui.plot.dataToFraction(ax, xy)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   xy - N-by-2 numeric data coordinates.
%
% Outputs:
%   uv - N-by-2 axes fractions, where [0 0] is the lower-left data extent and
%       [1 1] is the upper-right data extent after honoring log scales and
%       reversed axes directions.

    validateAxesHandle(ax, 'dataToFraction');
    xy = validatePointPairs(xy, 'xy');
    uv = [dataToFraction1D(xy(:, 1), ax.XLim, ax.XScale, ax.XDir), ...
        dataToFraction1D(xy(:, 2), ax.YLim, ax.YScale, ax.YDir)];
end
