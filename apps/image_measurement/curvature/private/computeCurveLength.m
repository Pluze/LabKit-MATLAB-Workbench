function lengthResult = computeCurveLength(xPix, yPix, referencePx, referenceLength, scaleUnit)
%COMPUTECURVELENGTH Measure traced curve length for labkit_CurvatureMeasurement_app.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app callbacks, test handlers, and private
%   curvature fit helpers.
%
% Inputs/outputs:
%   Pixel vectors plus optional reference scale fields. Returns the same
%   length-result struct previously built inside the app file.
%
% Side effects:
%   None. This helper performs GUI-free numeric length measurement only.

    lengthResult = emptyLengthResult();
    xPix = xPix(:);
    yPix = yPix(:);
    [xPix, yPix] = removeDuplicateNeighbors(xPix, yPix, 1e-9);

    if numel(xPix) < 2
        error('labkit_CurvatureMeasurement_app:NotEnoughLengthPoints', ...
            'At least 2 unique points are required to measure curve length.');
    end

    lengthPx = sum(hypot(diff(xPix), diff(yPix)));
    scaleUnit = char(normalizeScaleUnit(scaleUnit));
    pxPerUnit = scalePixelsPerUnit(referencePx, referenceLength);
    usePhysicalScale = pxPerUnit > 0;
    if usePhysicalScale
        lengthShow = lengthPx / pxPerUnit;
        unitLen = scaleUnit;
    else
        lengthShow = lengthPx;
        unitLen = 'px';
    end

    lengthResult.ok = true;
    lengthResult.message = '';
    lengthResult.length_px = lengthPx;
    lengthResult.length_show = lengthShow;
    lengthResult.unitLen = unitLen;
    lengthResult.referencePx = referencePx;
    lengthResult.referenceLength = referenceLength;
    lengthResult.scaleUnit = scaleUnit;
    lengthResult.px_per_unit = pxPerUnit;
    lengthResult.usePhysicalScale = usePhysicalScale;
    lengthResult.pointCount = numel(xPix);
end
