function test_imageCurvatureMeasurement()
%TEST_IMAGECURVATUREMEASUREMENT Verify image curvature app calculations.

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
    fit = labkit_CurvatureMeasurement_app('__test_computeCurvatureFit__', x, y, opts);

    assert(fit.ok, 'Curvature fit should succeed for circular points.');
    assertClose(fit.xc_px, xc, 1e-6, 'Fitted center x changed.');
    assertClose(fit.yc_px, yc, 1e-6, 'Fitted center y changed.');
    assertClose(fit.R_px, R, 1e-6, 'Fitted pixel radius changed.');
    assertClose(fit.px_per_mm, 10, 1e-12, 'Scale conversion changed.');
    assertClose(fit.R_show, 4.5, 1e-6, 'Fitted mm radius changed.');
    assertClose(fit.kappa_show, 1/4.5, 1e-6, 'Fitted mm curvature changed.');

    T = labkit_CurvatureMeasurement_app('__test_buildCurvatureResultTable__', ...
        fit, "sample.png");
    assert(isequal(T.Properties.VariableNames, expectedResultColumns()), ...
        'Curvature result table columns changed.');
    assert(T.Radius_px == fit.R_px, 'Result table should preserve pixel radius.');
    assert(T.Curvature == fit.kappa_show, 'Result table should preserve displayed curvature.');
end

function columns = expectedResultColumns()
    columns = {'Image', 'CenterX_px', 'CenterY_px', ...
        'Radius_px', 'Curvature_1_per_px', 'RMSE_px', 'RawScale_px', ...
        'ScaleLength_mm', 'PixelsPerMm', 'Radius', 'RadiusUnit', ...
        'Curvature', 'CurvatureUnit', 'RMSE'};
end
