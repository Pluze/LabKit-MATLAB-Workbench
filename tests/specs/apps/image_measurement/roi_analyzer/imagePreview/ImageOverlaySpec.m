classdef ImageOverlaySpec < matlab.unittest.TestCase
    % IMAGEOVERLAYSPEC Invariant: preview scaling changes overlay coordinates but not stored full-resolution geometry.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function provesImageOverlay(testCase)
            state = struct("session", struct("cache", struct( ...
                "previewScale", 0.5, "preview", zeros(20, 30), ...
                "name", "synthetic.png"), ...
                "selection", struct("roiIndex", 1)));
            roi = struct("id", "roi-1", "name", "Signal", ...
                "templateId", "template-1", ...
                "centerXY", [20 14], "shape", "Rectangle", ...
                "size", [9 7], "position", [16 11 9 7]);
            original = roi;

            model = roi_analyzer.imagePreview.model(state, roi, struct());

            testCase.verifyEqual(model.rois.position, [8.25 5.75 4.5 3.5]);
            testCase.verifyEqual(roi, original);
            testCase.verifyEqual(model.selectedRois, 1);
        end
    end
end
