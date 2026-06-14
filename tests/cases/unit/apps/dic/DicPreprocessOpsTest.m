classdef DicPreprocessOpsTest < matlab.unittest.TestCase
    %DICPREPROCESSOPSTEST Verify GUI-free DIC preprocess mask operations.

    methods (Test, TestTags = {'Unit'})
        function maskFromCurveHandlesEmptyCurve(testCase)
            setupLabKitTestPath();

            mask = dic_preprocess.ops.maskFromCurve([], [4 5]);

            testCase.verifyClass(mask, 'uint8');
            testCase.verifySize(mask, [4 5]);
            testCase.verifyEqual(mask, zeros(4, 5, 'uint8'));
        end

        function straightLineBoundaryClosesAndClampsPoints(testCase)
            setupLabKitTestPath();

            points = [-10 -10; 20 1; 3 20];

            curve = dic_preprocess.ops.maskBoundaryCurve(points, [10 12], ...
                'Straight lines');

            testCase.verifySize(curve, [4 2]);
            testCase.verifyEqual(curve(1, :), curve(end, :));
            testCase.verifyGreaterThanOrEqual(curve(:, 1), 0.5);
            testCase.verifyLessThanOrEqual(curve(:, 1), 12.5);
            testCase.verifyGreaterThanOrEqual(curve(:, 2), 0.5);
            testCase.verifyLessThanOrEqual(curve(:, 2), 10.5);
        end

        function curveBoundaryBuildsSampledClosedMask(testCase)
            setupLabKitTestPath();

            points = [3 3; 9 3; 9 9; 3 9];

            curve = dic_preprocess.ops.maskBoundaryCurve(points, [12 12], 'Curve');
            mask = dic_preprocess.ops.boundaryMaskImage(points, [12 12], 'Curve');

            testCase.verifyGreaterThan(size(curve, 1), size(points, 1));
            testCase.verifyEqual(curve(1, :), curve(end, :), 'AbsTol', 1e-12);
            testCase.verifyClass(mask, 'uint8');
            testCase.verifySize(mask, [12 12]);
            testCase.verifyGreaterThan(nnz(mask), 0);
            testCase.verifyEqual(max(mask, [], 'all'), uint8(255));
        end

        function boundaryMaskFromEditorUsesPointFallback(testCase)
            setupLabKitTestPath();

            points = [3 3; 9 3; 9 9; 3 9];

            [missing, okMissing] = dic_preprocess.ops.boundaryMaskFromEditor( ...
                points(1:2, :), [12 12], 'Curve', []);
            [mask, ok] = dic_preprocess.ops.boundaryMaskFromEditor( ...
                points, [12 12], 'Straight lines', []);

            testCase.verifyFalse(okMissing);
            testCase.verifyEmpty(missing);
            testCase.verifyTrue(ok);
            testCase.verifyClass(mask, 'uint8');
            testCase.verifyGreaterThan(nnz(mask), 0);
        end

        function squareCropGeometryStaysInsideImage(testCase)
            setupLabKitTestPath();

            defaultRect = dic_preprocess.ops.defaultSquareRect([100 80 3]);
            clampedRect = dic_preprocess.ops.squareRectInsideImage( ...
                [-20 90 75 20], [100 80]);

            testCase.verifyEqual(defaultRect, [21 31 40 40]);
            testCase.verifyEqual(clampedRect(3), clampedRect(4));
            testCase.verifyGreaterThanOrEqual(clampedRect(1), 1);
            testCase.verifyGreaterThanOrEqual(clampedRect(2), 1);
            testCase.verifyLessThanOrEqual(clampedRect(1) + clampedRect(3), 80);
            testCase.verifyLessThanOrEqual(clampedRect(2) + clampedRect(4), 100);
        end

        function falseColorAndMaskPreviewsPreserveImageShape(testCase)
            setupLabKitTestPath();

            reference = uint8([0 10; 20 30]);
            moving = uint8([30 20; 10 0]);
            mask = uint8([0 255; 255 0]);

            overlay = dic_preprocess.ops.makeFalseColorOverlay(reference, moving);
            rgb = dic_preprocess.ops.maskRgb(mask);

            testCase.verifySize(overlay, [2 2 3]);
            testCase.verifyEqual(overlay(:, :, 3), zeros(2));
            testCase.verifySize(rgb, [2 2 3]);
            testCase.verifyEqual(rgb(:, :, 1), mask);
            testCase.verifyEqual(rgb(:, :, 2), mask);
            testCase.verifyEqual(rgb(:, :, 3), mask);
        end
    end
end
