classdef CurvatureScientificSpec < matlab.unittest.TestCase
    %CURVATURESCIENTIFICSPEC Specify circular fit and traced-path measurement.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function fitsACircleAndConvertsItsRadiusToTheMeasuredUnit(testCase)
            theta = linspace(.25 .* pi, .75 .* pi, 12)';
            x = 120 + 45 .* cos(theta);
            y = 80 + 45 .* sin(theta);
            options = struct("referencePx", 50, "referenceLength", 5, ...
                "scaleUnit", "mm", "doDensify", false, "denseN", 200);

            fit = curvature.analysisRun.computeFitFromOptions(x, y, options);

            testCase.verifyTrue(fit.ok);
            testCase.verifyEqual([fit.xc_px fit.yc_px fit.R_px], [120 80 45], AbsTol=1e-6);
            testCase.verifyEqual(fit.px_per_unit, 10, AbsTol=1e-12);
            testCase.verifyEqual(fit.R_show, 4.5, AbsTol=1e-6);
            testCase.verifyEqual(fit.kappa_show, 1/4.5, AbsTol=1e-6);
        end

        function measuresPixelAndPhysicalPolylineLengths(testCase)
            x = [0; 3; 6];
            y = [0; 4; 8];
            pixel = curvature.analysisRun.computeLengthFromOptions(x, y, ...
                struct("referencePx", NaN, "referenceLength", 0, "scaleUnit", "um"));
            physical = curvature.analysisRun.computeLengthFromOptions(x, y, ...
                struct("referencePx", 5, "referenceLength", 1, "scaleUnit", "mm"));

            testCase.verifyEqual(pixel.length_px, 10, AbsTol=1e-12);
            testCase.verifyEqual(pixel.unitLen, 'px');
            testCase.verifyEqual(physical.length_show, 2, AbsTol=1e-12);
            testCase.verifyEqual(physical.unitLen, 'mm');
        end

        function usesTheVisibleCurvePathForDensificationAndTaskIdentity(testCase)
            anchors = [0 0; 10 0; 20 0];
            path = [0 0; 10 10; 20 0];
            fit = curvature.analysisRun.computeFitFromOptions(anchors(:, 1), anchors(:, 2), ...
                struct("referencePx", NaN, "referenceLength", 0, "scaleUnit", "um", ...
                "doDensify", true, "denseN", 5, "fitPathX", path(:, 1), ...
                "fitPathY", path(:, 2)));
            calibration = curvature.analysisRun.normalizeScaleCalibration( ...
                10, 2, 'mm', struct("referenceLine", [0 0; 10 0]));
            initial = curvature.analysisRun.fitTask(anchors, path, calibration, ...
                struct("doDensify", true, "denseN", 25));
            changed = curvature.analysisRun.fitTask(anchors, path, calibration, ...
                struct("doDensify", false, "denseN", 25));
            lengthTask = curvature.analysisRun.lengthTask(anchors, path, calibration);
            changedAnchors = curvature.analysisRun.lengthTask( ...
                anchors + [0 1], path, calibration);
            changedPath = curvature.analysisRun.lengthTask(anchors, anchors, calibration);

            testCase.verifyEqual(numel(fit.xFit), 5);
            testCase.verifyGreaterThan(max(fit.yFit), 0);
            testCase.verifyEqual(fit.curveLength_px, 2 .* hypot(10, 10), AbsTol=1e-9);
            testCase.verifyNotEqual(initial.fingerprint, changed.fingerprint);
            testCase.verifyNotEqual(lengthTask.fingerprint, changedAnchors.fingerprint);
            testCase.verifyNotEqual(lengthTask.fingerprint, changedPath.fingerprint);
            testCase.verifyEqual(lengthTask.lengthPath, path);
        end

        function rejectsDegenerateFitsAndSinglePointLengths(testCase)
            options = struct("referencePx", NaN, "referenceLength", 0, ...
                "scaleUnit", "um", "doDensify", false);

            testCase.verifyError(@() curvature.analysisRun.computeFitFromOptions( ...
                [5; 5; 5], [7; 7; 7], options), ...
                "labkit_CurvatureMeasurement_app:NotEnoughPoints");
            testCase.verifyError(@() curvature.analysisRun.computeFitFromOptions( ...
                [1; 2], [3; 4], options), ...
                "labkit_CurvatureMeasurement_app:NotEnoughPoints");
            testCase.verifyError(@() curvature.analysisRun.computeLengthFromOptions( ...
                1, 3, options), "labkit_CurvatureMeasurement_app:NotEnoughLengthPoints");
        end
    end
end
