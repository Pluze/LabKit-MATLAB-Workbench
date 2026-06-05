function lengthResult = computeCurveLength(xPix, yPix, calibration)
%COMPUTECURVELENGTH Measure traced curve length for labkit_CurvatureMeasurement_app.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app callbacks, test handlers, and private
%   curvature fit helpers.
%
% Inputs/outputs:
%   Pixel vectors plus a labkit.ui scale-bar calibration struct. Returns the
%   same length-result struct previously built inside the app file.
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

    if nargin < 3 || isempty(calibration)
        calibration = labkit.ui.tool.scaleBarCalibration();
    end

    lengthPx = sum(hypot(diff(xPix), diff(yPix)));
    scaleUnit = char(calibration.unit);
    pxPerUnit = calibration.pixelsPerUnit;
    usePhysicalScale = calibration.isCalibrated;
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
    lengthResult.referencePx = calibration.referencePixels;
    lengthResult.referenceLength = calibration.referenceLength;
    lengthResult.scaleUnit = scaleUnit;
    lengthResult.px_per_unit = pxPerUnit;
    lengthResult.usePhysicalScale = usePhysicalScale;
    lengthResult.pointCount = numel(xPix);
end
