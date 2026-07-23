classdef ImageMatchScientificSpec < matlab.unittest.TestCase
    %IMAGEMATCHSCIENTIFICSPEC Specify reference-guided color and tone matching.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
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
    end
end

function image = gradientImage()
[x, y] = meshgrid(linspace(0, 1, 72), linspace(0, 1, 48));
image = cat(3, x, y, .5 .* (x + y));
end

function image = tint(image, gains)
image = min(max(image .* reshape(gains, 1, 1, 3), 0), 1);
end

function value = ratioDistance(first, second)
value = norm(ratios(first) - ratios(second));
end

function value = ratios(image)
means = squeeze(mean(image, [1 2])).';
value = means ./ max(mean(means), eps);
end
