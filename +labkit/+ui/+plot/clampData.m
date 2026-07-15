function xy = clampData(ax, xy, varargin)
%CLAMPDATA Clamp data coordinates inside the visible axes box.
%
% App-facing contract:
%   xyOut = labkit.ui.plot.clampData(ax, xy)
%   xyOut = labkit.ui.plot.clampData(ax, xy, "Padding", 0.04)
%
% Inputs:
%   ax - target MATLAB axes or uiaxes handle.
%   xy - N-by-2 numeric data coordinates.
%   Padding - optional normalized axes padding, default 0.04.
%
% Outputs:
%   xyOut - N-by-2 clamped data coordinates.

    opts = parseAxesOptions(varargin, struct('Padding', 0.04));
    pad = max(0, min(0.49, double(opts.Padding)));
    uv = dataToFraction(ax, xy);
    uv = min(max(uv, pad), 1 - pad);
    xy = fractionToData(ax, uv);
end
