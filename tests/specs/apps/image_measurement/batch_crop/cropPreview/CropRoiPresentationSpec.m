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
            testCase.verifyTrue(any(contains(labels, "drag center or inside box")));
            clear cleanup
        end
    end
end
