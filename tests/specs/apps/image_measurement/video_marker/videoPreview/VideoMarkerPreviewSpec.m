classdef VideoMarkerPreviewSpec < matlab.unittest.TestCase
    %VIDEOMARKERPREVIEWSPEC Guard grayscale frame rendering.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function grayscaleFramesRenderAsOneImage(testCase)
            figureValue = figure(Visible="off");
            cleanup = onCleanup(@() delete(figureValue));
            ax = axes(figureValue);
            model = struct( ...
                "image", reshape(1:20, 4, 5), ...
                "title", "Synthetic frame", ...
                "skeleton", struct( ...
                    "edges", zeros(0, 2), ...
                    "pointNames", strings(0, 1)), ...
                "points", zeros(0, 2), ...
                "scaleBar", []);

            video_marker.videoPreview.draw(struct("video", ax), model);

            images = findobj(ax, Type="image");
            testCase.verifyNumElements(images, 1);
            testCase.verifySize(images.CData, [4 5]);
            clear cleanup
        end
    end
end
