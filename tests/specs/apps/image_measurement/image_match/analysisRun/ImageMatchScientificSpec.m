classdef ImageMatchScientificSpec < matlab.unittest.TestCase
    %IMAGEMATCHSCIENTIFICSPEC Specify reference-guided color and tone matching.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function acceptsSinglePixelSourcesAndReferences(testCase)
            source = reshape([.2 .4 .6], 1, 1, 3);
            for method = ["Balanced", "White balance", "Tone only", ...
                    "Protected tone", "Lab style", "Histogram"]
                step = image_match.analysisRun.makeStep(method, 100, 100, 100);
                output = image_match.analysisRun.applyMatch(source, source, step);
                testCase.verifySize(output, [1 1 3]);
                testCase.verifyTrue(all(isfinite(output), "all"));
                testCase.verifyTrue(all(output >= 0 & output <= 1, "all"));
            end
        end

        function whiteBalanceMovesSourceChannelRatiosTowardTheReference(testCase)
            base = gradientImage();
            source = tint(base, [.62 .86 1.25]);
            reference = tint(base, [1.18 .96 .72]);
            step = image_match.analysisRun.makeStep("White balance", 100, 100, 100);

            output = image_match.analysisRun.applyPipeline({source}, step, reference);

            testCase.verifyLessThan(ratioDistance(output{1}, reference), ...
                .55 .* ratioDistance(source, reference));
        end

        function toneOnlyRaisesBrightnessWithoutStrongColorDrift(testCase)
            base = gradientImage();
            source = .38 .* base + .10;
            reference = min(1, 1.18 .* base + .18);
            step = image_match.analysisRun.makeStep("Tone only", 100, 100, 0);

            output = image_match.analysisRun.applyPipeline({source}, step, reference);

            testCase.verifyGreaterThan(mean(output{1}, "all"), mean(source, "all"));
            testCase.verifyLessThan(norm(ratios(output{1}) - ratios(source)), .12);
        end

        function protectedToneMovesOnlyTheBackgroundTowardTheReference(testCase)
            [source, reference, background] = protectedTonePair();
            step = image_match.analysisRun.makeStep( ...
                "Protected tone", 100, 100, 100);

            output = image_match.analysisRun.applyPipeline({source}, step, reference);

            outputPixels = reshape(output{1}, [], 3);
            sourcePixels = reshape(source, [], 3);
            referencePixels = reshape(reference, [], 3);
            background = background(:);

            testCase.verifyLessThan( ...
                abs(mean(luma(outputPixels(background, :)), "all") - ...
                mean(luma(referencePixels(background, :)), "all")), ...
                abs(mean(luma(sourcePixels(background, :)), "all") - ...
                mean(luma(referencePixels(background, :)), "all")));
            testCase.verifyLessThan( ...
                hueDistance(outputPixels(~background, :), sourcePixels(~background, :)), .035);
        end

        function labStyleAndHistogramKeepImageShapeAndMoveColorTowardReference(testCase)
            [source, reference] = colorPair();
            labStyle = image_match.analysisRun.makeStep("Lab style", 100, 80, 100);
            histogram = image_match.analysisRun.makeStep("Histogram", 75, 100, 100);

            styled = image_match.analysisRun.applyPipeline({source}, labStyle, reference);
            histogrammed = image_match.analysisRun.applyPipeline({source}, histogram, reference);

            testCase.verifyLessThan(channelDistance(styled{1}, reference), .60);
            testCase.verifySize(histogrammed{1}, size(source));
            testCase.verifyGreaterThanOrEqual(min(histogrammed{1}, [], "all"), 0);
            testCase.verifyLessThanOrEqual(max(histogrammed{1}, [], "all"), 1);
        end

        function referenceStaysSeparateFromTheSourceBatch(testCase)
            [source, reference] = colorPair();
            steps = [ ...
                image_match.analysisRun.makeStep("White balance", 100, 100, 100); ...
                image_match.analysisRun.makeStep("Tone only", 100, 100, 0)];

            processed = image_match.analysisRun.applyPipeline({source}, steps, reference);

            testCase.verifyNumElements(processed, 1);
            testCase.verifySize(processed{1}, size(source));
        end
    end
end

function image = gradientImage()
[x, y] = meshgrid(linspace(0, 1, 72), linspace(0, 1, 48));
image = cat(3, x, y, .5 .* (x + y));
end

function image = tint(image, gains)
image = min(max(image .* reshape(gains, 1, 1, 3), 0), 1);
end

function [source, reference, background] = protectedTonePair()
source = .50 .* ones(48, 72, 3);
source(:, :, 1) = .96 .* source(:, :, 1);
source(:, :, 2) = 1.06 .* source(:, :, 2);
source(:, :, 3) = 1.02 .* source(:, :, 3);
background = true(48, 72);
background(18:35, 24:52) = false;
source(repmat(~background, 1, 1, 3)) = repmat( ...
    reshape([.70 .42 .16], 1, 1, 3), nnz(~background), 1);
reference = .86 .* ones(48, 72, 3);
reference = tint(reference, [1.01 1 .99]);
reference(repmat(~background, 1, 1, 3)) = source(repmat(~background, 1, 1, 3));
end

function [source, reference] = colorPair()
[x, y] = meshgrid(linspace(0, 1, 72), linspace(0, 1, 48));
source = cat(3, .55 .* x, .70 .* y, 1.10 .* (.5 .* (x + y)));
reference = cat(3, .80 .* x + .05, .55 .* y + .10, ...
    .60 .* (.5 .* (x + y)) + .20);
source = min(max(source, 0), 1);
reference = min(max(reference, 0), 1);
end

function values = luma(image)
if ismatrix(image) && size(image, 2) == 3
    values = .2126 .* image(:, 1) + .7152 .* image(:, 2) + .0722 .* image(:, 3);
else
    values = .2126 .* image(:, :, 1) + .7152 .* image(:, :, 2) + .0722 .* image(:, :, 3);
end
end

function value = hueDistance(first, second)
first = reshape(first, [], 3);
second = reshape(second, [], 3);
first = first ./ max(sum(first, 2), eps);
second = second ./ max(sum(second, 2), eps);
value = mean(vecnorm(first - second, 2, 2));
end

function value = channelDistance(first, second)
value = norm(squeeze(mean(first, [1 2])) - squeeze(mean(second, [1 2])));
end

function value = ratioDistance(first, second)
value = norm(ratios(first) - ratios(second));
end

function value = ratios(image)
means = squeeze(mean(image, [1 2])).';
value = means ./ max(mean(means), eps);
end
