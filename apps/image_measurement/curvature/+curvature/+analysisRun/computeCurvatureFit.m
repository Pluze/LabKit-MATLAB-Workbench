function fit = computeCurvatureFit(xPix, yPix, calibration, doDensify, denseN, fitPathX, fitPathY)
%COMPUTECURVATUREFIT Fit a circle and curvature to traced image points.
%
% Usage:
%   fit = curvature.analysisRun.computeCurvatureFit(xPix, yPix)
%   fit = curvature.analysisRun.computeCurvatureFit(xPix, yPix, calibration)
%   fit = curvature.analysisRun.computeCurvatureFit(xPix, yPix, ...
%       calibration, doDensify, denseN, fitPathX, fitPathY)
%
% Description:
%   Removes consecutive duplicate points, optionally resamples a traced path
%   at equal arc-length intervals, obtains an algebraic Kasa circle estimate,
%   and minimizes radial squared error with base-MATLAB fminsearch. The result
%   includes pixel-space values and, when calibration is valid, physical radius,
%   curvature, residuals, RMSE, and traced length. No GUI or file is required.
%
% Inputs:
%   xPix - Numeric x-coordinate vector in image pixels (image columns). At
%       least three unique consecutive point pairs must remain.
%   yPix - Numeric y-coordinate vector in image pixels (image rows), with the
%       same number of elements as xPix.
%   calibration - Scale structure accepted by
%       curvature.analysisRun.normalizeScaleCalibration. Important fields are
%       referencePixels, referenceLength, unit, pixelsPerUnit, isCalibrated,
%       and referenceLine. Empty or omitted input selects uncalibrated pixels.
%   doDensify - Logical-like scalar controlling equal-arc-length resampling.
%       Default: true.
%   denseN - Number of resampled fitting points, rounded to an integer with a
%       minimum of three. Default: 300.
%   fitPathX - Optional displayed-path x-coordinate vector.
%   fitPathY - Optional displayed-path y-coordinate vector. When fitPathX and
%       fitPathY have equal length and at least three unique points, this path
%       supplies curve length and, when doDensify is true, the circle fit.
%       Otherwise the anchor vectors supply both calculations.
%
% Calculations:
%   R_px is the fitted radius and kappa_per_px = 1/R_px. rmse_px is the root
%   mean square radial residual of the points used by the optimizer. When
%   calibration.isCalibrated is true, displayed lengths are divided by
%   pixelsPerUnit and displayed curvature is the reciprocal physical radius.
%   residuals_show always corresponds to the original unique anchor points.
%
% Outputs:
%   fit - Scalar structure describing the successful fit.
%
% Fit Fields:
%   ok, message - true and empty text after a successful calculation.
%   xc_px, yc_px, R_px - Circle center and radius in pixels.
%   kappa_per_px, rmse_px - Pixel curvature and radial RMSE.
%   R_show, kappa_show, rmse_show - Values in unitLen/unitK when calibrated,
%       otherwise the corresponding pixel values.
%   unitLen, unitK - Length and curvature units, for example "um" and
%       "1/um", or "px" and "1/px" without calibration.
%   residuals_show - Anchor-point radial residual column vector in unitLen.
%   xPix, yPix - Unique anchor coordinates used for reported residuals.
%   xFit, yFit - Points passed to the circle optimizer.
%   curveLength_px, curveLength_show, curveLengthUnit, curvePointCount -
%       Polyline length result for the accepted fit path.
%   referencePx, referenceLength, scaleUnit, px_per_unit,
%       usePhysicalScale - Effective scale metadata.
%
% Errors:
%   labkit_CurvatureMeasurement_app:NotEnoughPoints - Fewer than three unique
%       anchor points remain.
%   labkit_CurvatureMeasurement_app:InvalidFit - Optimization returns a
%       nonfinite or nonpositive radius.
%
% Example:
%   theta = (0:11).' * (2*pi/12);
%   x = 30 + 10*cos(theta);
%   y = 40 + 10*sin(theta);
%   fit = curvature.analysisRun.computeCurvatureFit(x, y, [], false);
%   assert(fit.ok && abs(fit.R_px - 10) < 1e-3)
%
% See also curvature.analysisRun.computeCurveLength,
%   curvature.analysisRun.normalizeScaleCalibration

    fit = curvature.appState.emptyFitResult();
    xPix = xPix(:);
    yPix = yPix(:);
    pointTolerancePx = curvature.analysisRun.curvePointTolerance();
    [xPix, yPix] = curvature.analysisRun.removeDuplicateNeighbors( ...
        xPix, yPix, pointTolerancePx);

    if numel(xPix) < 3
        error('labkit_CurvatureMeasurement_app:NotEnoughPoints', ...
            'At least 3 unique points are required to fit a circle.');
    end

    if nargin < 3 || isempty(calibration)
        calibration = curvature.analysisRun.normalizeScaleCalibration();
    else
        calibration = curvature.analysisRun.normalizeScaleCalibration(calibration);
    end

    if nargin < 4 || isempty(doDensify)
        doDensify = true;
    end
    if nargin < 5 || isempty(denseN)
        denseN = 300;
    end
    denseN = max(3, round(denseN));

    fitSourceX = xPix;
    fitSourceY = yPix;
    hasFitPath = nargin >= 7 && ~isempty(fitPathX) && ~isempty(fitPathY);
    if hasFitPath
        fitPathX = fitPathX(:);
        fitPathY = fitPathY(:);
        if numel(fitPathX) == numel(fitPathY)
            [fitPathX, fitPathY] = curvature.analysisRun.removeDuplicateNeighbors( ...
                fitPathX, fitPathY, pointTolerancePx);
            if numel(fitPathX) >= 3
                fitSourceX = fitPathX;
                fitSourceY = fitPathY;
            end
        end
    end

    xFit = xPix;
    yFit = yPix;
    if doDensify && (numel(fitSourceX) >= 5 || (hasFitPath && numel(fitSourceX) >= 3))
        [xFit, yFit] = resamplePathByArcLength(fitSourceX, fitSourceY, denseN);
    end

    [xc0, yc0, R0] = circleInitKasa(xFit, yFit);
    [xc, yc, R_px, rmse_px] = fitCircleGeomWithFallback(xFit, yFit, xc0, yc0, R0);
    if ~isfinite(R_px) || R_px <= 0
        error('labkit_CurvatureMeasurement_app:InvalidFit', ...
            'Circle fit produced an invalid radius.');
    end

    scaleUnit = char(calibration.unit);
    pxPerUnit = calibration.pixelsPerUnit;
    usePhysicalScale = calibration.isCalibrated;
    kappa_px = 1 / R_px;
    lengthResult = curvature.analysisRun.computeCurveLength(fitSourceX, fitSourceY, calibration);

    if usePhysicalScale
        unitLen = scaleUnit;
        unitK = sprintf('1/%s', scaleUnit);
        R_show = R_px / pxPerUnit;
        rmse_show = rmse_px / pxPerUnit;
        kappa_show = 1 / R_show;
        residuals_show = radialResiduals(xPix, yPix, xc, yc, R_px) / pxPerUnit;
    else
        unitLen = 'px';
        unitK = '1/px';
        R_show = R_px;
        rmse_show = rmse_px;
        kappa_show = kappa_px;
        residuals_show = radialResiduals(xPix, yPix, xc, yc, R_px);
    end

    fit.ok = true;
    fit.message = '';
    fit.xc_px = xc;
    fit.yc_px = yc;
    fit.R_px = R_px;
    fit.kappa_per_px = kappa_px;
    fit.rmse_px = rmse_px;
    fit.referencePx = calibration.referencePixels;
    fit.referenceLength = calibration.referenceLength;
    fit.scaleUnit = scaleUnit;
    fit.px_per_unit = pxPerUnit;
    fit.usePhysicalScale = usePhysicalScale;
    fit.R_show = R_show;
    fit.kappa_show = kappa_show;
    fit.rmse_show = rmse_show;
    fit.unitLen = unitLen;
    fit.unitK = unitK;
    fit.residuals_show = residuals_show;
    fit.xPix = xPix;
    fit.yPix = yPix;
    fit.xFit = xFit;
    fit.yFit = yFit;
    fit.curveLength_px = lengthResult.length_px;
    fit.curveLength_show = lengthResult.length_show;
    fit.curveLengthUnit = lengthResult.unitLen;
    fit.curvePointCount = lengthResult.pointCount;
end

function [xDense, yDense] = resamplePathByArcLength(x, y, denseN)
    s = [0; cumsum(hypot(diff(x), diff(y)))];
    if s(end) <= 0
        xDense = x;
        yDense = y;
        return;
    end
    s2 = linspace(0, s(end), denseN).';
    xDense = interp1(s, x, s2, 'linear');
    yDense = interp1(s, y, s2, 'linear');
end

function [xc, yc, R] = circleInitKasa(x, y)
    x = x(:);
    y = y(:);
    A = [2*x, 2*y, ones(size(x))];
    b = x.^2 + y.^2;
    p = A\b;
    xc = p(1);
    yc = p(2);
    R = sqrt(max(p(3) + xc^2 + yc^2, eps));
end

function [xc, yc, R, rmse] = fitCircleGeomWithFallback(x, y, xc0, yc0, R0)
    x = x(:);
    y = y(:);
    p0 = [xc0; yc0; R0];
    residual = @(p) sqrt((x - p(1)).^2 + (y - p(2)).^2) - abs(p(3));

    f = @(p) sum(residual(p).^2);
    % Constant: 20,000 evaluations/iterations retain the legacy convergence
    % budget for difficult hand-traced circle fits.
    optimizerIterationLimit = 2e4;
    opts = optimset('Display', 'off', ...
        'MaxFunEvals', optimizerIterationLimit, ...
        'MaxIter', optimizerIterationLimit);
    p = fminsearch(f, p0, opts);

    xc = p(1);
    yc = p(2);
    R = abs(p(3));
    rmse = sqrt(mean(residual([xc; yc; R]).^2));
end

function residuals = radialResiduals(x, y, xc, yc, R)
    residuals = sqrt((x(:) - xc).^2 + (y(:) - yc).^2) - R;
end
