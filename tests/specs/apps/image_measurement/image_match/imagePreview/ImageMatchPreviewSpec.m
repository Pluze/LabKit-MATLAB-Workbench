classdef ImageMatchPreviewSpec < matlab.unittest.TestCase
    %IMAGEMATCHPREVIEWSPEC Guard before/after preview composition.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function grayscaleInputsBecomeOneRgbComparisonImage(testCase)
            original = zeros(3, 4);
            matched = ones(3, 4);

            preview = ...
                image_match.imagePreview.presentationData.beforeAfterImage( ...
                original, matched);

            testCase.verifySize(preview, [3 14 3]);
            testCase.verifyEqual(preview(:, 1:4, 2), original);
            testCase.verifyEqual(preview(:, 11:14, 1), matched);
        end
    end
end
