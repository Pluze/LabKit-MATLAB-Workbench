classdef CurvatureScientificSpec < matlab.unittest.TestCase
    %CURVATURESCIENTIFICSPEC Specify circular fit and traced-path measurement.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function fitsACircleAndConvertsItsRadiusToTheMeasuredUnit(testCase)
            theta = linspace(.25 .* pi, .75 .* pi, 12)';
            x = 120 + 45 .* cos(theta);
            y = 80 + 45 .* sin(theta);
            calibration = curvature.analysisRun.normalizeScaleCalibration( ...
                50, 5, "mm");

            fit = curvature.analysisRun.computeCurvatureFit( ...
                x, y, calibration, false, 200);

            testCase.verifyTrue(fit.ok);
            testCase.verifyEqual([fit.xc_px fit.yc_px fit.R_px], [120 80 45], AbsTol=1e-6);
            testCase.verifyEqual(fit.px_per_unit, 10, AbsTol=1e-12);
            testCase.verifyEqual(fit.R_show, 4.5, AbsTol=1e-6);
            testCase.verifyEqual(fit.kappa_show, 1/4.5, AbsTol=1e-6);
        end

        function measuresPixelAndPhysicalPolylineLengths(testCase)
            x = [0; 3; 6];
            y = [0; 4; 8];
            pixel = curvature.analysisRun.computeCurveLength(x, y);
            calibration = curvature.analysisRun.normalizeScaleCalibration( ...
                5, 1, "mm");
            physical = curvature.analysisRun.computeCurveLength( ...
                x, y, calibration);

            testCase.verifyEqual(pixel.length_px, 10, AbsTol=1e-12);
            testCase.verifyEqual(pixel.unitLen, 'px');
            testCase.verifyEqual(physical.length_show, 2, AbsTol=1e-12);
            testCase.verifyEqual(physical.unitLen, 'mm');
        end

        function usesTheVisibleCurvePathForDensificationAndTaskIdentity(testCase)
            anchors = [0 0; 10 0; 20 0];
            path = [0 0; 10 10; 20 0];
            fit = curvature.analysisRun.computeCurvatureFit( ...
                anchors(:, 1), anchors(:, 2), [], true, 5, ...
                path(:, 1), path(:, 2));
            calibration = curvature.analysisRun.normalizeScaleCalibration( ...
                10, 2, 'mm', struct("referenceLine", [0 0; 10 0]));
            initial = curvature.analysisRun.fitTask(anchors, path, calibration, ...
                struct("doDensify", true, "denseN", 25));
            changed = curvature.analysisRun.fitTask(anchors, path, calibration, ...
                struct("doDensify", false, "denseN", 25));

            testCase.verifyEqual(numel(fit.xFit), 5);
            testCase.verifyGreaterThan(max(fit.yFit), 0);
            testCase.verifyEqual(fit.curveLength_px, 2 .* hypot(10, 10), AbsTol=1e-9);
            testCase.verifyNotEqual(initial.fingerprint, changed.fingerprint);
        end

        function rejectsDegenerateFitsAndSinglePointLengths(testCase)
            testCase.verifyError(@() curvature.analysisRun.computeCurvatureFit( ...
                [5; 5; 5], [7; 7; 7], [], false), ...
                "labkit_CurvatureMeasurement_app:NotEnoughPoints");
            testCase.verifyError(@() curvature.analysisRun.computeCurvatureFit( ...
                [1; 2], [3; 4], [], false), ...
                "labkit_CurvatureMeasurement_app:NotEnoughPoints");
            testCase.verifyError(@() curvature.analysisRun.computeCurveLength( ...
                1, 3), "labkit_CurvatureMeasurement_app:NotEnoughLengthPoints");
        end
    end
end
