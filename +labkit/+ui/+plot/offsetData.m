function xy = offsetData(ax, xy, offsetFraction)
%OFFSETDATA Offset data coordinates by normalized axes fractions.
%
% App-facing contract:
%   xyOut = labkit.ui.plot.offsetData(ax, xy, offsetFraction)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   xy - N-by-2 numeric data coordinates.
%   offsetFraction - 1-by-2 or N-by-2 axes-fraction offsets. For example,
%       [0.03 -0.04] moves a label slightly right and down in visual axes
%       space, including on log or reversed axes.
%
% Outputs:
%   xyOut - N-by-2 offset data coordinates.

    uv = labkit.ui.plot.dataToFraction(ax, xy);
    offsetFraction = normalizePointOffsets(offsetFraction, size(uv, 1));
    xy = labkit.ui.plot.fractionToData(ax, uv + offsetFraction);
end
