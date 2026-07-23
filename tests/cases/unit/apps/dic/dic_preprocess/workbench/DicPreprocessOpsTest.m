classdef DicPreprocessOpsTest < matlab.unittest.TestCase
    %DICPREPROCESSOPSTEST Verify GUI-free DIC preprocess mask operations.

    methods (Test, TestTags = {'Unit'})
        function maskFromCurveHandlesEmptyCurve(testCase)
            setupLabKitTestPath();

            mask = dic_preprocess.analysisRun.maskFromCurve([], [4 5]);

            testCase.verifyClass(mask, 'uint8');
            testCase.verifySize(mask, [4 5]);
            testCase.verifyEqual(mask, zeros(4, 5, 'uint8'));
        end


        function maskFromCurveRasterizesPolygonWithBaseMatlab(testCase)
            setupLabKitTestPath();
            curve = [2 2; 5 2; 5 4; 2 4; 2 2];

            mask = dic_preprocess.analysisRun.maskFromCurve(curve, [6 7]);

            testCase.verifyClass(mask, 'uint8');
            testCase.verifyEqual(mask(3, 3), uint8(255));
            testCase.verifyEqual(mask(1, 1), uint8(0));
        end

        function straightLineBoundaryClosesAndClampsPoints(testCase)
            setupLabKitTestPath();

            points = [-10 -10; 20 1; 3 20];

            curve = dic_preprocess.analysisRun.maskBoundaryCurve(points, [10 12], ...
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

            curve = dic_preprocess.analysisRun.maskBoundaryCurve(points, [12 12], 'Curve');
            mask = dic_preprocess.analysisRun.boundaryMaskImage(points, [12 12], 'Curve');

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

            [missing, okMissing] = dic_preprocess.analysisRun.boundaryMaskFromEditor( ...
                points(1:2, :), [12 12], 'Curve', []);
            [mask, ok] = dic_preprocess.analysisRun.boundaryMaskFromEditor( ...
                points, [12 12], 'Straight lines', []);

            testCase.verifyFalse(okMissing);
            testCase.verifyEmpty(missing);
            testCase.verifyTrue(ok);
            testCase.verifyClass(mask, 'uint8');
            testCase.verifyGreaterThan(nnz(mask), 0);
        end

        function boundaryMaskFromEditorPrefersLiveEditorPoints(testCase)
            setupLabKitTestPath();

            stalePoints = zeros(0, 2);
            editorPoints = [3 3; 9 3; 9 9; 3 9];
            editor = struct( ...
                'getPoints', @() editorPoints, ...
                'curvePoints', @() [editorPoints; editorPoints(1, :)]);

            [mask, ok] = dic_preprocess.analysisRun.boundaryMaskFromEditor( ...
                stalePoints, [12 12], 'Straight lines', editor);

            testCase.verifyTrue(ok);
            testCase.verifyClass(mask, 'uint8');
            testCase.verifyGreaterThan(nnz(mask), 0);
        end

        function boundaryMaskFromEditorToleratesPointOnlyEditor(testCase)
            setupLabKitTestPath();

            stalePoints = zeros(0, 2);
            editorPoints = [3 3; 9 3; 9 9; 3 9];
            editor = struct('getPoints', @() editorPoints);

            [mask, ok] = dic_preprocess.analysisRun.boundaryMaskFromEditor( ...
                stalePoints, [12 12], 'Curve', editor);

            testCase.verifyTrue(ok);
            testCase.verifyClass(mask, 'uint8');
            testCase.verifyGreaterThan(nnz(mask), 0);
        end

        function squareCropGeometryStaysInsideImage(testCase)
            setupLabKitTestPath();

            defaultRect = dic_preprocess.analysisRun.defaultSquareRect([100 80 3]);
            clampedRect = dic_preprocess.analysisRun.squareRectInsideImage( ...
                [-20 90 75 20], [100 80]);

            testCase.verifyEqual(defaultRect, [21 31 40 40]);
            testCase.verifyEqual(clampedRect(3), clampedRect(4));
            testCase.verifyGreaterThanOrEqual(clampedRect(1), 1);
            testCase.verifyGreaterThanOrEqual(clampedRect(2), 1);
            testCase.verifyLessThanOrEqual(clampedRect(1) + clampedRect(3), 80);
            testCase.verifyLessThanOrEqual(clampedRect(2) + clampedRect(4), 100);
        end

        function cropImageUsesInclusiveImcropRectangleContract(testCase)
            setupLabKitTestPath();
            imageData = reshape(uint8(1:60), 5, 6, 2);

            cropped = dic_preprocess.analysisRun.cropImage( ...
                imageData, [2 2 3 2]);

            testCase.verifySize(cropped, [3 4 2]);
            testCase.verifyEqual(cropped, imageData(2:4, 2:5, :));
        end

        function falseColorAndMaskPreviewsPreserveImageShape(testCase)
            setupLabKitTestPath();

            reference = uint8([0 10; 20 30]);
            moving = uint8([30 20; 10 0]);
            mask = uint8([0 255; 255 0]);

            overlay = dic_preprocess.analysisRun.makeFalseColorOverlay(reference, moving);
            rgb = dic_preprocess.analysisRun.maskRgb(mask);

            testCase.verifySize(overlay, [2 2 3]);
            testCase.verifyEqual(overlay(:, :, 3), zeros(2));
            testCase.verifySize(rgb, [2 2 3]);
            testCase.verifyEqual(rgb(:, :, 1), mask);
            testCase.verifyEqual(rgb(:, :, 2), mask);
            testCase.verifyEqual(rgb(:, :, 3), mask);
        end

        function autoAlignUsesToolboxFreeTranslation(testCase)
            setupLabKitTestPath();

            reference = zeros(16, 18);
            reference(5:8, 7:11) = 1;
            moving = zeros(size(reference));
            moving(7:10, 4:8) = 1;

            [aligned, tform, method] = ...
                dic_preprocess.analysisRun.autoAlignMovingToReference( ...
                reference, moving);

            testCase.verifyEqual(aligned, reference, ...
                'Toolbox-free auto alignment should recover integer translation.');
            testCase.verifyEqual(tform, [1 0 0; 0 1 0; 3 -2 1]);
            testCase.verifyTrue(contains(method, 'toolbox-free'));
        end

        function manualAlignmentUsesRowVectorRotationConvention(testCase)
            setupLabKitTestPath();
            movingPoints = [4 3; 14 5; 7 18; 20 16];
            angle = pi / 7;
            expectedRotation = [cos(angle) sin(angle); ...
                -sin(angle) cos(angle)];
            expectedTranslation = [11 -6];
            fixedPoints = movingPoints * expectedRotation + ...
                expectedTranslation;
            reference = zeros(32, 40);
            moving = zeros(size(reference));

            [~, transform] = ...
                dic_preprocess.analysisRun.alignMovingToReference( ...
                reference, moving, fixedPoints, movingPoints);

            transformedPoints = [movingPoints ones(size(movingPoints, 1), 1)] ...
                * transform;
            testCase.verifyEqual(transform(1:2, 1:2), expectedRotation, ...
                'AbsTol', 1e-12, ...
                'Manual alignment must use the row-vector rotation convention.');
            testCase.verifyEqual(transformedPoints(:, 1:2), fixedPoints, ...
                'AbsTol', 1e-11, ...
                'The fitted transform must map every moving point to its reference match.');
        end
    end
end
