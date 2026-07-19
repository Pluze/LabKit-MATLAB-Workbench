% Private UI plot helper used by public coordinate operations.
function xy = fractionToData(ax, uv)
%
% Internal contract:
%   xy = fractionToData(ax, uv)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   uv - N-by-2 axes fractions, usually in the range [0, 1].
%
% Outputs:
%   xy - N-by-2 data coordinates after honoring log scales and reversed axes
%       directions.

    validateAxesHandle(ax, 'fractionToData');
    uv = validatePointPairs(uv, 'uv');
    xy = [fractionToData1D(uv(:, 1), ax.XLim, ax.XScale, ax.XDir), ...
        fractionToData1D(uv(:, 2), ax.YLim, ax.YScale, ax.YDir)];
end
