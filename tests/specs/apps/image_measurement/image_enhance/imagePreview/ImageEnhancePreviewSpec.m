classdef ImageEnhancePreviewSpec < matlab.unittest.TestCase
    %IMAGEENHANCEPREVIEWSPEC Guard before/after preview composition.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function grayscaleInputsBecomeOneRgbComparisonImage(testCase)
            original = zeros(4, 5);
            enhanced = ones(4, 5);

            preview = ...
                image_enhance.imagePreview.presentationData.beforeAfterImage( ...
                original, enhanced);

            testCase.verifySize(preview, [4 16 3]);
            testCase.verifyEqual(preview(:, 1:5, 1), original);
            testCase.verifyEqual(preview(:, 12:16, 3), enhanced);
        end
    end
end
