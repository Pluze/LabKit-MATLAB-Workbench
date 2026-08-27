classdef CropRoiPresentationSpec < matlab.unittest.TestCase
    % CROPROIPRESENTATIONSPEC Regression: crop ROI visibly exposes both drag targets.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rendersAnUnambiguousCenterAndBodyDragAffordance(testCase)
            figureValue = figure(Visible="off");
            cleanup = onCleanup(@() close(figureValue));
            axesValue = axes(Parent=figureValue);
            model = struct( ...
                "imageData", uint8(zeros(80, 120)), ...
                "xData", [1 120], "yData", [1 80], ...
                "center", [60 40], ...
                "cropRectangle", [35.5 25.5 50 30], ...
                "scaleBar", [], "title", "Crop preview");

            batch_crop.cropPreview.draw(struct("main", axesValue), model);

            centerMarker = findall(axesValue, Type="line", Marker="o");
            labels = string({findall(axesValue, Type="text").String});
            testCase.verifyNumElements(centerMarker, 1);
            testCase.verifyEqual(centerMarker.XData, 60);
            testCase.verifyEqual(centerMarker.YData, 40);
            testCase.verifyTrue(any(contains(labels, "Crop center")));
            testCase.verifyTrue(any( ...
                labels == "Crop ROI — drag center or inside box"));
            testCase.verifyEqual(string(centerMarker.HitTest), "off");
            testCase.verifyEqual(string(centerMarker.PickableParts), "none");
            clear cleanup
        end

        function refitsOnlyForSourceOrCanvasTransformChanges(testCase)
            item = batch_crop.cropTasks.emptyTask();
            item.sourceId = "image-a";
            geometry = struct("canvas", zeros(80, 120));
            base = batch_crop.cropPreview.viewportRevision(item, geometry);

            transformed = item;
            transformed.angleDeg = 15;
            replacement = item;
            replacement.sourceId = "image-b";

            testCase.verifyEqual( ...
                batch_crop.cropPreview.viewportRevision(item, geometry), base);
            testCase.verifyNotEqual( ...
                batch_crop.cropPreview.viewportRevision( ...
                    transformed, geometry), base);
            testCase.verifyNotEqual( ...
                batch_crop.cropPreview.viewportRevision( ...
                    replacement, geometry), base);
            testCase.verifyNotEqual( ...
                batch_crop.cropPreview.viewportRevision( ...
                    item, struct("canvas", zeros(90, 120))), base);
        end
    end
end
