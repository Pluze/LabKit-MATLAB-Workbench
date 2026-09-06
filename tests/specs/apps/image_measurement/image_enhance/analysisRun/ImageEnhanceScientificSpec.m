classdef ImageEnhanceScientificSpec < matlab.unittest.TestCase
    %IMAGEENHANCESCIENTIFICSPEC Specify reproducible enhancement transforms.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function neutralBackgroundAtTargetIsNotLiftedByASaturatedSubject(testCase)
            source = .9 * ones(60, 60, 3);
            source(31:60, :, :) = repmat(reshape([.8 .1 .1], 1, 1, 3), 30, 60);
            step = image_enhance.analysisRun.makeStep( ...
                "Subject-preserving enhance", 100, 90, 0);
            output = image_enhance.analysisRun.applyStep(source, step, []);
            % Neutral background already meets the target; allow only the
            % small influence of mask smoothing at the subject boundary.
            testCase.verifyLessThan(mean(output(1:10, :, :), "all"), .92);
        end

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

        function whiteRoiCalibrationSeparatesTheSubjectWithoutHueDrift(testCase)
            image = whiteCalibrationImage();
            output = image_enhance.analysisRun.applyStep(image, ...
                image_enhance.analysisRun.makeStep("White ROI calibration", 100, 92, 0), ...
                struct("whiteRoi", [2 2 18 14]));
            background = output(2:15, 2:19, :);
            subjectBefore = image(18:36, 24:56, :);
            subjectAfter = output(18:36, 24:56, :);

            testCase.verifyGreaterThan(mean(luma(background), "all"), .86);
            testCase.verifyLessThan(mean(luma(background), "all"), .985);
            testCase.verifyGreaterThan(norm(channelMeans(subjectAfter) - channelMeans(background)), ...
                norm(channelMeans(subjectBefore) - channelMeans(image(2:15, 2:19, :))));
            testCase.verifyGreaterThan(mean(subjectAfter(:, :, 1), "all"), ...
                mean(subjectAfter(:, :, 3), "all"));
            testCase.verifyLessThan(hueDistance(subjectBefore, subjectAfter), .035);
        end

        function subjectPreservingEnhanceLiftsBackgroundWithoutStrongHueDrift(testCase)
            image = calibratedSubjectImage();
            strong = image_enhance.analysisRun.applyStep(image, ...
                image_enhance.analysisRun.makeStep("Subject-preserving enhance", 85, 90, 0), []);
            weak = image_enhance.analysisRun.applyStep(image, ...
                image_enhance.analysisRun.makeStep("Subject-preserving enhance", 20, 70, 0), []);
            subjectBefore = image(18:35, 24:52, :);
            subjectAfter = strong(18:35, 24:52, :);

            testCase.verifyGreaterThan(mean(strong(1:12, 1:20, :), "all"), ...
                mean(image(1:12, 1:20, :), "all"));
            testCase.verifyGreaterThan(mean(strong(1:12, 1:20, :), "all"), ...
                mean(weak(1:12, 1:20, :), "all") + .03);
            testCase.verifyLessThan(hueDistance(subjectBefore, subjectAfter), .035);
        end

        function previewScalingKeepsPixelRadiusAndDisplayImageConsistent(testCase)
            image = syntheticImage();
            preview = image_enhance.imagePreview.presentationData.previewImage(image, 24);
            full = image_enhance.analysisRun.applyStep(image, ...
                image_enhance.analysisRun.makeStep("Local contrast", 50, 12, 0), []);
            scaled = image_enhance.analysisRun.applyStep(preview, ...
                image_enhance.analysisRun.makeStep("Local contrast", 50, 6, 0), []);
            expected = image_enhance.imagePreview.presentationData.previewImage(full, 24);

            testCase.verifyLessThan(mean(abs(expected(:) - scaled(:))), .04);
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

function image = calibratedSubjectImage()
image = .55 .* ones(48, 72, 3);
image(:, :, 1) = .96 .* image(:, :, 1);
image(:, :, 2) = 1.04 .* image(:, :, 2);
image(:, :, 3) = 1.02 .* image(:, :, 3);
image(18:36, 24:56, 1) = .72;
image(18:36, 24:56, 2) = .42;
image(18:36, 24:56, 3) = .14;
end

function image = whiteCalibrationImage()
[x, y] = meshgrid(linspace(0, 1, 72), linspace(0, 1, 48));
image = .72 + .04 .* cat(3, x, y, .5 .* (x + y));
image(:, :, 1) = 1.06 .* image(:, :, 1);
image(:, :, 3) = .93 .* image(:, :, 3);
image(18:36, 24:56, 1) = .62;
image(18:36, 24:56, 2) = .34;
image(18:36, 24:56, 3) = .15;
image = min(max(image, 0), 1);
end

function value = luma(image)
value = labkit.image.rgb2gray(image);
end

function value = channelMeans(image)
value = squeeze(mean(image, [1 2])).';
end

function value = hueDistance(before, after)
beforeHsv = rgb2hsv(before);
afterHsv = rgb2hsv(after);
delta = abs(mean(beforeHsv(:, :, 1), "all") - mean(afterHsv(:, :, 1), "all"));
value = min(delta, 1 - delta);
end
