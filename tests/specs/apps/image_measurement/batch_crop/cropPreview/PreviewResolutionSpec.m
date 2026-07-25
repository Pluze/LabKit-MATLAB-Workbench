classdef PreviewResolutionSpec < matlab.unittest.TestCase
    % PREVIEWRESOLUTIONSPEC Regression: ordinary previews retain app-owned resolution.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function retainsAnOrdinaryCanvasWithoutASecondSamplingPass(testCase)
            canvas = uint8(zeros(901, 1501));
            geometry = struct("canvas", canvas);
            placement = struct("xData", [1 1501], "yData", [1 901]);

            render = batch_crop.cropPreview.renderData(geometry, placement);

            testCase.verifyEqual(render.imageData, canvas);
            testCase.verifyEqual(render.scaleFactor, 1);
            testCase.verifyEqual(render.xData, [1 1501]);
            testCase.verifyEqual(render.yData, [1 901]);
        end
    end
end
