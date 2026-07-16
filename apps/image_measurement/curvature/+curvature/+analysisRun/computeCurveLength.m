function lengthResult = computeCurveLength(xPix, yPix, calibration)
%COMPUTECURVELENGTH Measure the polyline length of traced image points.
%
% Usage:
%   lengthResult = curvature.analysisRun.computeCurveLength(xPix, yPix)
%   lengthResult = curvature.analysisRun.computeCurveLength( ...
%       xPix, yPix, calibration)
%
% Description:
%   Removes consecutive points closer than the app's duplicate tolerance and
%   sums the Euclidean distance between the remaining adjacent points. A valid
%   calibration converts the pixel length to the requested physical unit. The
%   function does not smooth, interpolate, close the path, plot, or write files.
%
% Inputs:
%   xPix - Numeric x-coordinate vector in image pixels (image columns). At
%       least two unique consecutive point pairs are required.
%   yPix - Numeric y-coordinate vector in image pixels (image rows), with the
%       same number of elements as xPix.
%   calibration - Scale structure accepted by
%       curvature.analysisRun.normalizeScaleCalibration. Empty or omitted
%       input reports length in pixels.
%
% Outputs:
%   lengthResult - Scalar structure with the following fields.
%
% Result Fields:
%   ok, message - true and empty text after a successful calculation.
%   length_px - Sum of adjacent segment lengths in pixels.
%   length_show - length_px divided by pixelsPerUnit when calibrated;
%       otherwise length_px.
%   unitLen - Calibration unit when calibrated, otherwise "px".
%   referencePx, referenceLength, scaleUnit, px_per_unit,
%       usePhysicalScale - Effective scale metadata.
%   pointCount - Number of points remaining after duplicate removal.
%
% Errors:
%   labkit_CurvatureMeasurement_app:NotEnoughLengthPoints - Fewer than two
%       unique points remain.
%
% Example:
%   x = [0 3 3];
%   y = [0 0 4];
%   result = curvature.analysisRun.computeCurveLength(x, y);
%   assert(result.length_px == 7 && result.unitLen == "px")
%
% See also curvature.analysisRun.computeCurvatureFit,
%   curvature.analysisRun.normalizeScaleCalibration

    lengthResult = curvature.appState.emptyLengthResult();
    xPix = xPix(:);
    yPix = yPix(:);
    pointTolerancePx = curvature.analysisRun.curvePointTolerance();
    [xPix, yPix] = curvature.analysisRun.removeDuplicateNeighbors( ...
        xPix, yPix, pointTolerancePx);

    if numel(xPix) < 2
        error('labkit_CurvatureMeasurement_app:NotEnoughLengthPoints', ...
            'At least 2 unique points are required to measure curve length.');
    end

    if nargin < 3 || isempty(calibration)
        calibration = curvature.analysisRun.normalizeScaleCalibration();
    else
        calibration = curvature.analysisRun.normalizeScaleCalibration(calibration);
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
