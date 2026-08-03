classdef DicPreprocessScientificSpec < matlab.unittest.TestCase
    %DICPREPROCESSSCIENTIFICSPEC Specify DIC alignment and mask geometry.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function rasterizesCurvesAndClampsTheirBoundaryToTheImage(testCase)
            points = [-10 -10; 20 1; 3 20];
            line = dic_preprocess.analysisRun.maskBoundaryCurve( ...
                points, [10 12], 'Straight lines');
            curvePoints = [3 3; 9 3; 9 9; 3 9];
            curve = dic_preprocess.analysisRun.maskBoundaryCurve( ...
                curvePoints, [12 12], 'Curve');
            mask = dic_preprocess.analysisRun.boundaryMaskImage( ...
                curvePoints, [12 12], 'Curve');

            testCase.verifyEqual(line(1, :), line(end, :));
            testCase.verifyGreaterThanOrEqual(line(:, 1), .5);
            testCase.verifyLessThanOrEqual(line(:, 1), 12.5);
            testCase.verifyGreaterThan(size(curve, 1), size(curvePoints, 1));
            testCase.verifyEqual(curve(1, :), curve(end, :), AbsTol=1e-12);
            testCase.verifyClass(mask, 'uint8');
            testCase.verifyGreaterThan(nnz(mask), 0);
        end

        function cropsAndBuildsPreviewImagesWithTheDeclaredPixelGeometry(testCase)
            image = reshape(uint8(1:60), 5, 6, 2);
            cropped = dic_preprocess.analysisRun.cropImage(image, [2 2 3 2]);
            rectangle = dic_preprocess.analysisRun.squareRectInsideImage( ...
                [-20 90 75 20], [100 80]);
            overlay = dic_preprocess.analysisRun.makeFalseColorOverlay( ...
                uint8([0 10; 20 30]), uint8([30 20; 10 0]));
            rgb = dic_preprocess.analysisRun.maskRgb(uint8([0 255; 255 0]));

            testCase.verifyEqual(cropped, image(2:4, 2:5, :));
            testCase.verifyEqual(rectangle(3), rectangle(4));
            testCase.verifyGreaterThanOrEqual(rectangle(1), 1);
            testCase.verifySize(overlay, [2 2 3]);
            testCase.verifyEqual(overlay(:, :, 3), zeros(2));
            testCase.verifyEqual(rgb(:, :, 1), uint8([0 255; 255 0]));
        end

        function alignsIntegerTranslationsWithoutAnOptionalToolbox(testCase)
            reference = zeros(16, 18);
            reference(5:8, 7:11) = 1;
            moving = zeros(size(reference));
            moving(7:10, 4:8) = 1;

            [aligned, transform, method] = ...
                dic_preprocess.analysisRun.autoAlignMovingToReference(reference, moving);

            testCase.verifyEqual(aligned, reference);
            testCase.verifyEqual(transform, [1 0 0; 0 1 0; 3 -2 1]);
            testCase.verifySubstring(method, 'toolbox-free');
        end

        function reducesControlledRotationAndTranslationWithoutAToolbox(testCase)
            [x, y] = meshgrid(1:96, 1:80);
            reference = sin(x / 4) + cos(y / 7) + ...
                2 * exp(-((x - 29).^2 + (y - 23).^2) / 90) + ...
                3 * exp(-((x - 68).^2 + (y - 57).^2) / 55);
            angle = 7 * pi / 180;
            rotation = [cos(angle) sin(angle); -sin(angle) cos(angle)];
            center = ([size(reference, 2), size(reference, 1)] + 1) / 2;
            expected = [rotation [0; 0]; ...
                center - center * rotation + [4 -3], 1];
            moving = dic_preprocess.analysisRun.applyRigidTransform( ...
                reference, reference, inv(expected));

            [aligned, transform, method] = ...
                dic_preprocess.analysisRun.autoAlignMovingToReference( ...
                reference, moving);

            initialError = norm(reference - moving, "fro");
            alignedError = norm(reference - aligned, "fro");
            testCase.verifyLessThan(alignedError, .45 * initialError);
            testCase.verifyLessThan(norm(transform(1:2, 1:2) - ...
                expected(1:2, 1:2), "fro"), .05);
            testCase.verifySubstring(method, 'rigid');
        end
    end
end
