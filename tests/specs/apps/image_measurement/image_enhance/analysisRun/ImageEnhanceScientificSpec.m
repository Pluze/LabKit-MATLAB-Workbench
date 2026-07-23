classdef ImageEnhanceScientificSpec < matlab.unittest.TestCase
    %IMAGEENHANCESCIENTIFICSPEC Specify reproducible enhancement transforms.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function appliesBrightnessContrastAndSharpeningWithinDisplayRange(testCase)
            image = syntheticImage();
            steps = [ ...
                image_enhance.analysisRun.makeStep("Brightness/contrast", 10, 25, 0); ...
                image_enhance.analysisRun.makeStep("Sharpen", 40, 1.5, 0)];

            output = image_enhance.analysisRun.applyPipeline({image}, steps);

            testCase.verifySize(output{1}, size(image));
            testCase.verifyTrue(all(output{1} >= 0 & output{1} <= 1, "all"));
            testCase.verifyGreaterThan(mean(output{1}, "all"), mean(image, "all"));
        end

        function whiteBalanceReducesAChannelCast(testCase)
            gray = repmat(linspace(.2, .8, 64), 48, 1);
            cast = cat(3, .55 .* gray, .8 .* gray, 1.25 .* gray);
            step = image_enhance.analysisRun.makeStep("White balance", 100, 0, 0);

            output = image_enhance.analysisRun.applyStep(cast, step, []);

            testCase.verifyLessThan(channelSpread(output), .25 .* channelSpread(cast));
        end
    end
end

function image = syntheticImage()
[x, y] = meshgrid(linspace(0, 1, 80), linspace(0, 1, 60));
image = cat(3, x, y, .5 .* (x + y));
end

function value = channelSpread(image)
means = squeeze(mean(image, [1 2]));
value = max(means) - min(means);
end
