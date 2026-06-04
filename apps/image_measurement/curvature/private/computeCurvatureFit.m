function fit = computeCurvatureFit(xPix, yPix, referencePx, referenceLength, scaleUnit, doDensify, denseN, fitPathX, fitPathY)
%COMPUTECURVATUREFIT Fit image-curve curvature for labkit_CurvatureMeasurement_app.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app callbacks and __labkit_test__ handlers.
%
% Inputs/outputs:
%   Pixel anchor vectors plus optional displayed fit-path vectors. Returns the
%   same fit-result struct previously built inside the app file.
%
% Side effects:
%   None. This helper performs GUI-free numeric fitting only.

    fit = emptyFitResult();
    xPix = xPix(:);
    yPix = yPix(:);
    [xPix, yPix] = removeDuplicateNeighbors(xPix, yPix, 1e-9);

    if numel(xPix) < 3
        error('labkit_CurvatureMeasurement_app:NotEnoughPoints', ...
            'At least 3 unique points are required to fit a circle.');
    end

    if nargin < 6 || isempty(doDensify)
        doDensify = true;
    end
    if nargin < 7 || isempty(denseN)
        denseN = 300;
    end
    denseN = max(3, round(denseN));

    fitSourceX = xPix;
    fitSourceY = yPix;
    hasFitPath = nargin >= 9 && ~isempty(fitPathX) && ~isempty(fitPathY);
    if hasFitPath
        fitPathX = fitPathX(:);
        fitPathY = fitPathY(:);
        if numel(fitPathX) == numel(fitPathY)
            [fitPathX, fitPathY] = removeDuplicateNeighbors(fitPathX, fitPathY, 1e-9);
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

    scaleUnit = char(normalizeScaleUnit(scaleUnit));
    pxPerUnit = scalePixelsPerUnit(referencePx, referenceLength);
    usePhysicalScale = pxPerUnit > 0;
    kappa_px = 1 / R_px;
    lengthResult = computeCurveLength(fitSourceX, fitSourceY, referencePx, referenceLength, scaleUnit);

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
    fit.referencePx = referencePx;
    fit.referenceLength = referenceLength;
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

    useLSQ = exist('lsqnonlin', 'file') == 2;
    if useLSQ
        try
            opts = optimoptions('lsqnonlin', ...
                'Display', 'off', ...
                'MaxFunctionEvaluations', 2e4, ...
                'MaxIterations', 2e4);
            p = lsqnonlin(residual, p0, [], [], opts);
        catch
            useLSQ = false;
        end
    end

    if ~useLSQ
        f = @(p) sum(residual(p).^2);
        opts = optimset('Display', 'off', 'MaxFunEvals', 2e4, 'MaxIter', 2e4);
        p = fminsearch(f, p0, opts);
    end

    xc = p(1);
    yc = p(2);
    R = abs(p(3));
    rmse = sqrt(mean(residual([xc; yc; R]).^2));
end

function residuals = radialResiduals(x, y, xc, yc, R)
    residuals = sqrt((x(:) - xc).^2 + (y(:) - yc).^2) - R;
end
