classdef FocusStackScientificSpec < matlab.unittest.TestCase
    %FOCUSSTACKSCIENTIFICSPEC Specify focus selection and registration behavior.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function selectsTheSharpSliceAcrossComplementaryRegions(testCase)
            [nearImage, farImage, midpoint] = syntheticFocusPair();
            result = focus_stack.analysisRun.computeFocusStack( ...
                {nearImage, farImage}, struct("focusWindow", 5, ...
                "smoothRadius", 0, "minConfidence", 0));
            index = double(result.focusIndex);
            margin = 8;

            testCase.verifyTrue(result.ok);
            testCase.verifyEqual(sum(result.focusCoverage), 1, AbsTol=1e-12);
            testCase.verifyGreaterThan(mean(index(:, 1:midpoint-margin) == 1, "all"), .80);
            testCase.verifyGreaterThan(mean(index(:, midpoint+margin:end) == 2, "all"), .80);
            testCase.verifyTrue(all(result.fused >= 0 & result.fused <= 1, "all"));
        end

        function reducesSyntheticRegistrationDriftAndFingerprintsOptions(testCase)
            reference = syntheticRegistrationImage();
            moving = integerTranslate(reference, -3, 4, median(reference(:)));
            [aligned, lines] = focus_stack.analysisRun.alignImages({moving, reference});
            before = mean((labkit.image.im2double(moving(:)) - ...
                labkit.image.im2double(reference(:))) .^ 2);
            after = mean((labkit.image.im2double(aligned{1}(:)) - ...
                labkit.image.im2double(reference(:))) .^ 2);
            [nearImage, farImage] = syntheticFocusPair();
            options = struct("focusWindow", 5, "smoothRadius", 1, "minConfidence", .05);
            base = focus_stack.analysisRun.runTask(["near.png"; "far.png"], ...
                {nearImage, farImage}, options, false);
            registered = focus_stack.analysisRun.runTask(["near.png"; "far.png"], ...
                {nearImage, farImage}, options, true);

            testCase.verifyLessThan(after, before);
            testCase.verifySubstring(strjoin(string(lines), " "), "reference image: 2");
            testCase.verifyNotEqual(base.fingerprint, registered.fingerprint);
        end
    end
end

function [nearImage, farImage, midpoint] = syntheticFocusPair()
heightPx = 72;
widthPx = 104;
[x, y] = meshgrid(1:widthPx, 1:heightPx);
sharp = min(max(.5 + .25 .* sin(.75 .* x) + .25 .* cos(.65 .* y), 0), 1);
blurred = boxBlur(sharp, 13);
midpoint = floor(widthPx / 2);
near = blurred;
far = blurred;
near(:, 1:midpoint) = sharp(:, 1:midpoint);
far(:, midpoint+1:end) = sharp(:, midpoint+1:end);
nearImage = cat(3, near, .85 .* near, .65 .* near);
farImage = cat(3, far, .85 .* far, .65 .* far);
end

function image = syntheticRegistrationImage()
[x, y] = meshgrid(1:96, 1:72);
image = .2 + .5 .* exp(-((x - 48).^2 + (y - 36).^2) ./ 300);
image(abs(sqrt((x - 48).^2 + (y - 36).^2) - 18) < 2) = 1;
image(abs(y - .55 .* x - 8) < 1.5) = .85;
image = uint8(255 .* min(max(image, 0), 1));
end

function output = integerTranslate(input, rowShift, colShift, fill)
output = zeros(size(input), class(input));
output(:) = cast(fill, class(input));
rows = size(input, 1); cols = size(input, 2);
destinationRows = max(1, 1 + rowShift):min(rows, rows + rowShift);
destinationCols = max(1, 1 + colShift):min(cols, cols + colShift);
sourceRows = max(1, 1 - rowShift):min(rows, rows - rowShift);
sourceCols = max(1, 1 - colShift):min(cols, cols - colShift);
output(destinationRows, destinationCols, :) = input(sourceRows, sourceCols, :);
end

function output = boxBlur(input, sizePx)
kernel = ones(sizePx, sizePx);
output = conv2(input, kernel, 'same') ./ conv2(ones(size(input)), kernel, 'same');
end
