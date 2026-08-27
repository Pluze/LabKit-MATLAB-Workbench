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
                "showDensePoints", false, "showStaticCurve", true, ...
                "scaleBar", []);

            curvature.curvePreview.draw(struct("image", ax), model);

            images = findobj(ax, Type="image");
            testCase.verifyNumElements(images, 1);
            testCase.verifySize(images.CData, [4 5]);
            clear cleanup
        end

        function editingUsesOnlyTheManagedCurveOverlay(testCase)
            figureValue = figure(Visible="off");
            cleanup = onCleanup(@() delete(figureValue));
            ax = axes(figureValue);
            points = [10 30; 30 10; 50 30];
            fit = curvature.analysisRun.emptyFitResult();
            editing = curvature.curvePreview.model( ...
                zeros(40, 60), points, fit, false, [], true);

            curvature.curvePreview.draw(struct("image", ax), editing);

            testCase.verifyEmpty(findobj(ax, DisplayName="curve"));
            testCase.verifyEmpty(findobj(ax, DisplayName="anchors"));

            inactive = curvature.curvePreview.model( ...
                zeros(40, 60), points, fit, false, [], false);
            curvature.curvePreview.draw(struct("image", ax), inactive);
            testCase.verifyNumElements(findobj(ax, DisplayName="curve"), 1);
            testCase.verifyNumElements(findobj(ax, DisplayName="anchors"), 1);
            clear cleanup
        end

        function refitsForNewImageIdentityOrCanvasSize(testCase)
            source = labkit.app.source.record( ...
                "image-a", "image", "synthetic-a.png");
            base = curvature.curvePreview.viewportRevision( ...
                source, zeros(40, 60));

            testCase.verifyEqual( ...
                curvature.curvePreview.viewportRevision( ...
                    source, ones(40, 60)), base);
            testCase.verifyNotEqual( ...
                curvature.curvePreview.viewportRevision( ...
                    source, zeros(41, 60)), base);
            replacement = labkit.app.source.record( ...
                "image-b", "image", "synthetic-b.png");
            testCase.verifyNotEqual( ...
                curvature.curvePreview.viewportRevision( ...
                    replacement, zeros(40, 60)), base);
        end
    end
end
