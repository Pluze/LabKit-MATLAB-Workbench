function pxPerUnit = scalePixelsPerUnit(referencePx, referenceLength)
%SCALEPIXELSPERUNIT Convert app scale reference into pixels per display unit.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app private fit and length helpers.
%
% Inputs/outputs:
%   Reference pixel count and physical reference length. Returns zero when no
%   valid physical scale is available.
%
% Side effects:
%   None. Keeps the original validation behavior for invalid reference length.

    pxPerUnit = 0;
    if nargin < 1 || isempty(referencePx)
        referencePx = NaN;
    end
    if nargin < 2 || isempty(referenceLength)
        referenceLength = 0;
    end

    validateattributes(referenceLength, {'numeric'}, {'scalar', 'finite', 'nonnegative'});
    if isfinite(referencePx) && referencePx > 0 && referenceLength > 0
        pxPerUnit = referencePx / referenceLength;
    end
end
