classdef CurvaturePresentationSpec < matlab.unittest.TestCase
    %CURVATUREPRESENTATIONSPEC Specify initial curve measurement readouts.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsTheStableInitialMetricRows(testCase)
            rows = curvature.curvePreview.presentationData.initialResultTable();

            testCase.verifyTrue(iscell(rows));
            testCase.verifyEqual(rows{1, 1}, 'Curve length');
            testCase.verifyEqual(rows{end, 1}, 'Pixels/unit');
        end

        function grayscaleImagesUseTheScalarImageRenderingPath(testCase)
            figureValue = figure(Visible="off");
            cleanup = onCleanup(@() delete(figureValue));
            ax = axes(figureValue);
            model = struct( ...
                "imageData", reshape(1:20, 4, 5), ...
                "points", zeros(0, 2), "curve", zeros(0, 2), ...
                "fit", struct("ok", false), ...
                "showDensePoints", false, "scaleBar", []);

            curvature.curvePreview.draw(struct("image", ax), model);

            images = findobj(ax, Type="image");
            testCase.verifyNumElements(images, 1);
            testCase.verifySize(images.CData, [4 5]);
            clear cleanup
        end
    end
end
