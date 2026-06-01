function test_imageCurvatureMeasurement()
%TEST_IMAGECURVATUREMEASUREMENT Verify image curvature app calculations.

    checkCircularFitWithMeasuredScale();
    checkPixelAndManualScaleModes();
    checkInvalidCurvePoints();
end

function checkCircularFitWithMeasuredScale()
    theta = linspace(0.25*pi, 0.75*pi, 12).';
    xc = 120;
    yc = 80;
    R = 45;
    x = xc + R*cos(theta);
    y = yc + R*sin(theta);

    opts = struct( ...
        'rawpx', 50, ...
        'scaleLengthMm', 5, ...
        'manualPxPerMm', 0, ...
        'doDensify', false, ...
        'denseN', 200);
    fit = labkit_CurvatureMeasurement_app('__labkit_test__', 'computeCurvatureFit', x, y, opts);

    assert(fit.ok, 'Curvature fit should succeed for circular points.');
    assertClose(fit.xc_px, xc, 1e-6, 'Fitted center x changed.');
    assertClose(fit.yc_px, yc, 1e-6, 'Fitted center y changed.');
    assertClose(fit.R_px, R, 1e-6, 'Fitted pixel radius changed.');
    assertClose(fit.px_per_mm, 10, 1e-12, 'Scale conversion changed.');
    assertClose(fit.R_show, 4.5, 1e-6, 'Fitted mm radius changed.');
    assertClose(fit.kappa_show, 1/4.5, 1e-6, 'Fitted mm curvature changed.');

    T = labkit_CurvatureMeasurement_app('__labkit_test__', 'buildCurvatureResultTable', ...
        fit, "sample.png");
    assert(isequal(T.Properties.VariableNames, expectedResultColumns()), ...
        'Curvature result table columns changed.');
    assert(T.Radius_px == fit.R_px, 'Result table should preserve pixel radius.');
    assert(T.Curvature == fit.kappa_show, 'Result table should preserve displayed curvature.');
end

function checkPixelAndManualScaleModes()
    theta = linspace(0, 0.5*pi, 6).';
    x = 12 + 30*cos(theta);
    y = 22 + 30*sin(theta);

    pxOnly = labkit_CurvatureMeasurement_app('__labkit_test__', 'computeCurvatureFit', x, y, ...
        struct('rawpx', NaN, 'scaleLengthMm', 0, 'manualPxPerMm', 0, ...
        'doDensify', false));
    assert(pxOnly.ok, 'Curvature fit should work without a physical scale.');
    assert(~pxOnly.useMM, 'Missing scale should keep display units in pixels.');
    assert(strcmp(pxOnly.unitLen, 'px'), 'Pixel-only radius unit changed.');
    assert(strcmp(pxOnly.unitK, '1/px'), 'Pixel-only curvature unit changed.');
    assertClose(pxOnly.R_show, pxOnly.R_px, 1e-9, ...
        'Pixel-only displayed radius should equal pixel radius');
    assertClose(pxOnly.kappa_show, pxOnly.kappa_per_px, 1e-12, ...
        'Pixel-only displayed curvature should equal pixel curvature');

    manualScale = labkit_CurvatureMeasurement_app('__labkit_test__', 'computeCurvatureFit', x, y, ...
        struct('rawpx', NaN, 'scaleLengthMm', 0, 'manualPxPerMm', 15, ...
        'doDensify', false));
    assert(manualScale.ok, 'Manual px/mm scale should produce a fit.');
    assert(manualScale.useMM, 'Manual px/mm scale should use physical units.');
    assertClose(manualScale.px_per_mm, 15, 1e-12, ...
        'Manual px/mm value should be preserved');
    assertClose(manualScale.R_show, manualScale.R_px / 15, 1e-9, ...
        'Manual scale displayed radius conversion');
end

function checkInvalidCurvePoints()
    opts = struct('rawpx', NaN, 'scaleLengthMm', 0, ...
        'manualPxPerMm', 0, 'doDensify', false);

    assertThrows(@() labkit_CurvatureMeasurement_app( ...
        '__labkit_test__', 'computeCurvatureFit', [5; 5; 5], [7; 7; 7], opts), ...
        'labkit_CurvatureMeasurement_app:NotEnoughPoints', ...
        'Duplicate-only curve points should be rejected.');
    assertThrows(@() labkit_CurvatureMeasurement_app( ...
        '__labkit_test__', 'computeCurvatureFit', [1; 2], [3; 4], opts), ...
        'labkit_CurvatureMeasurement_app:NotEnoughPoints', ...
        'Two unique curve points should be rejected.');
end

function columns = expectedResultColumns()
    columns = {'Image', 'CenterX_px', 'CenterY_px', ...
        'Radius_px', 'Curvature_1_per_px', 'RMSE_px', 'RawScale_px', ...
        'ScaleLength_mm', 'PixelsPerMm', 'Radius', 'RadiusUnit', ...
        'Curvature', 'CurvatureUnit', 'RMSE'};
end

function assertThrows(fn, expectedIdentifier, label)
    try
        fn();
    catch ME
        assert(strcmp(ME.identifier, expectedIdentifier), ...
            '%s Expected %s but caught %s.', ...
            label, expectedIdentifier, ME.identifier);
        return;
    end
    error('%s Expected an error with identifier %s.', label, expectedIdentifier);
end
