classdef ImageCurvatureMeasurementTest < matlab.unittest.TestCase
    %IMAGECURVATUREMEASUREMENTTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_imageCurvatureMeasurement(testCase)
            setupLabKitTestPath();
            verify_imageCurvatureMeasurement();
        end
    end
end

function verify_imageCurvatureMeasurement()
%TEST_IMAGECURVATUREMEASUREMENT Verify image curvature app calculations.

    checkCircularFitWithMeasuredScale();
    checkPixelAndTypedScaleModes();
    checkCurveLengthMeasurement();
    checkDensifyUsesCurvePath();
    checkTaskFingerprintsTrackInputs();
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
        'referencePx', 50, ...
        'referenceLength', 5, ...
        'scaleUnit', 'mm', ...
        'doDensify', false, ...
        'denseN', 200);
    fit = curvature.ops.computeFitFromOptions(x, y, opts);

    assert(fit.ok, 'Curvature fit should succeed for circular points.');
    assertClose(fit.xc_px, xc, 1e-6, 'Fitted center x changed.');
    assertClose(fit.yc_px, yc, 1e-6, 'Fitted center y changed.');
    assertClose(fit.R_px, R, 1e-6, 'Fitted pixel radius changed.');
    assertClose(fit.px_per_unit, 10, 1e-12, 'Scale conversion changed.');
    assertClose(fit.R_show, 4.5, 1e-6, 'Fitted mm radius changed.');
    assertClose(fit.kappa_show, 1/4.5, 1e-6, 'Fitted mm curvature changed.');
    assertClose(fit.curveLength_px, sum(hypot(diff(x), diff(y))), 1e-9, ...
        'Fitted result should include curve length in pixels.');

    T = curvature.export.buildResultTable(fit, "sample.png");
    assert(isequal(T.Properties.VariableNames, expectedResultColumns()), ...
        'Curvature result table columns changed.');
    assert(T.Radius_px == fit.R_px, 'Result table should preserve pixel radius.');
    assert(T.Curvature == fit.kappa_show, 'Result table should preserve displayed curvature.');
    assert(T.ReferenceUnit == "mm", 'Result table should preserve the selected scale unit.');
    assert(T.CurveLength_px == fit.curveLength_px, ...
        'Result table should preserve curve length.');
end

function checkPixelAndTypedScaleModes()
    theta = linspace(0, 0.5*pi, 6).';
    x = 12 + 30*cos(theta);
    y = 22 + 30*sin(theta);

    pxOnly = curvature.ops.computeFitFromOptions(x, y, ...
        struct('referencePx', NaN, 'referenceLength', 0, 'scaleUnit', 'um', ...
        'doDensify', false));
    assert(pxOnly.ok, 'Curvature fit should work without a physical scale.');
    assert(~pxOnly.usePhysicalScale, 'Missing scale should keep display units in pixels.');
    assert(strcmp(pxOnly.unitLen, 'px'), 'Pixel-only radius unit changed.');
    assert(strcmp(pxOnly.unitK, '1/px'), 'Pixel-only curvature unit changed.');
    assertClose(pxOnly.R_show, pxOnly.R_px, 1e-9, ...
        'Pixel-only displayed radius should equal pixel radius');
    assertClose(pxOnly.kappa_show, pxOnly.kappa_per_px, 1e-12, ...
        'Pixel-only displayed curvature should equal pixel curvature');

    typedScale = curvature.ops.computeFitFromOptions(x, y, ...
        struct('referencePx', 15, 'referenceLength', 1, 'scaleUnit', 'mm', ...
        'doDensify', false));
    assert(typedScale.ok, 'Typed reference scale should produce a fit.');
    assert(typedScale.usePhysicalScale, 'Typed reference scale should use physical units.');
    assertClose(typedScale.px_per_unit, 15, 1e-12, ...
        'Typed reference scale value should be preserved');
    assertClose(typedScale.R_show, typedScale.R_px / 15, 1e-9, ...
        'Typed reference scale displayed radius conversion');
    assert(strcmp(typedScale.unitLen, 'mm'), ...
        'Typed reference scale should preserve the selected unit.');
end

function checkCurveLengthMeasurement()
    x = [0; 3; 6];
    y = [0; 4; 8];

    pxLength = curvature.ops.computeLengthFromOptions(x, y, ...
        struct('referencePx', NaN, 'referenceLength', 0, 'scaleUnit', 'um'));
    assert(pxLength.ok, 'Curve length should succeed for two or more points.');
    assertClose(pxLength.length_px, 10, 1e-12, ...
        'Pixel curve length changed.');
    assertClose(pxLength.length_show, 10, 1e-12, ...
        'Pixel display length should equal pixel length without scale.');
    assert(strcmp(pxLength.unitLen, 'px'), ...
        'Pixel-only curve length unit changed.');

    mmLength = curvature.ops.computeLengthFromOptions(x, y, ...
        struct('referencePx', 5, 'referenceLength', 1, 'scaleUnit', 'mm'));
    assert(mmLength.ok, 'Typed reference scale should scale curve length.');
    assertClose(mmLength.length_show, 2, 1e-12, ...
        'Typed reference scale curve length conversion changed.');
    assert(strcmp(mmLength.unitLen, 'mm'), ...
        'Typed reference scale curve length unit changed.');
    assert(mmLength.pointCount == 3, ...
        'Curve length should report the number of points used.');
end

function checkDensifyUsesCurvePath()
    anchorX = [0; 10; 20];
    anchorY = [0; 0; 0];
    curveX = [0; 10; 20];
    curveY = [0; 10; 0];

    fit = curvature.ops.computeFitFromOptions(anchorX, anchorY, ...
        struct('referencePx', NaN, 'referenceLength', 0, ...
        'scaleUnit', 'um', 'doDensify', true, 'denseN', 5, ...
        'fitPathX', curveX, 'fitPathY', curveY));

    assert(fit.ok, 'Curve-path densified fit should succeed.');
    assert(numel(fit.xFit) == 5, ...
        'Densified fit should use the requested dense point count.');
    assert(max(fit.yFit) > 0, ...
        'Densified fit points should follow the displayed curve path, not the anchor chord.');
    assertClose(fit.curveLength_px, 2 * hypot(10, 10), 1e-9, ...
        'Curve-path fit should measure length along the displayed curve path.');
end

function checkTaskFingerprintsTrackInputs()
    points = [0 0; 10 0; 20 10];
    fitPath = [0 0; 5 5; 10 0; 20 10];
    calibration = curvature.ops.normalizeScaleCalibration( ...
        10, 2, 'mm', struct('referenceLine', [0 0; 10 0]));

    fitTask = curvature.state.fitTask(points, fitPath, calibration, ...
        struct('doDensify', true, 'denseN', 25));
    sameFitTask = curvature.state.fitTask(points, fitPath, calibration, ...
        struct('doDensify', true, 'denseN', 25));
    changedFitTask = curvature.state.fitTask(points, fitPath, calibration, ...
        struct('doDensify', false, 'denseN', 25));

    assert(fitTask.fingerprint == sameFitTask.fingerprint, ...
        'Identical curvature fit tasks should keep a stable fingerprint.');
    assert(fitTask.fingerprint ~= changedFitTask.fingerprint, ...
        'Changed densify options should invalidate curvature fit tasks.');
    assert(isequal(fitTask.points, points), ...
        'Fit task should preserve anchor points.');
    assert(isequal(fitTask.fitPath, fitPath), ...
        'Fit task should preserve displayed fit path.');

    lengthTask = curvature.state.lengthTask(points, fitPath, calibration);
    changedLengthTask = curvature.state.lengthTask(points + [0 1], fitPath, calibration);
    changedPathTask = curvature.state.lengthTask(points, points, calibration);

    assert(lengthTask.fingerprint ~= changedLengthTask.fingerprint, ...
        'Changed anchor points should invalidate curvature length tasks.');
    assert(lengthTask.fingerprint ~= changedPathTask.fingerprint, ...
        'Changed displayed path should invalidate curvature length tasks.');
    assert(isequal(lengthTask.lengthPath, fitPath), ...
        'Length task should preserve displayed length path.');
end

function checkInvalidCurvePoints()
    opts = struct('referencePx', NaN, 'referenceLength', 0, ...
        'scaleUnit', 'um', 'doDensify', false);

    assertThrows(@() curvature.ops.computeFitFromOptions( ...
        [5; 5; 5], [7; 7; 7], opts), ...
        'labkit_CurvatureMeasurement_app:NotEnoughPoints', ...
        'Duplicate-only curve points should be rejected.');
    assertThrows(@() curvature.ops.computeFitFromOptions( ...
        [1; 2], [3; 4], opts), ...
        'labkit_CurvatureMeasurement_app:NotEnoughPoints', ...
        'Two unique curve points should be rejected.');
    assertThrows(@() curvature.ops.computeLengthFromOptions([1], [3], opts), ...
        'labkit_CurvatureMeasurement_app:NotEnoughLengthPoints', ...
        'Single-point curve length should be rejected.');
end

function columns = expectedResultColumns()
    columns = {'Image', 'CenterX_px', 'CenterY_px', ...
        'Radius_px', 'Curvature_1_per_px', 'RMSE_px', 'ReferencePixels_px', ...
        'ReferenceLength', 'ReferenceUnit', 'PixelsPerUnit', 'Radius', 'RadiusUnit', ...
        'Curvature', 'CurvatureUnit', 'RMSE', ...
        'CurveLength_px', 'CurveLength', 'CurveLengthUnit', 'CurvePointCount'};
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
