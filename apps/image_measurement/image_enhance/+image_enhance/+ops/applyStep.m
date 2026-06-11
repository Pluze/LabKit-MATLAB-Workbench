% Expected caller: image_enhance.ops.applyPipeline and focused tests. Inputs
% are one RGB double source image, a normalized step, and an optional reference
% image for match-reference steps. Output is RGB double image data in [0, 1].
function outputImage = applyStep(inputImage, step, referenceImage)

    inputImage = normalizeImage(inputImage);
    key = normalizeKind(step.kind);
    switch key
        case 'brightnesscontrast'
            outputImage = adjustBrightnessContrast(inputImage, ...
                step.amount, step.secondary);
        case 'localcontrast'
            outputImage = localContrast(inputImage, step.amount, step.secondary);
        case 'sharpen'
            outputImage = sharpenImage(inputImage, step.amount, step.secondary);
        case 'huesaturation'
            outputImage = adjustHueSaturation(inputImage, ...
                step.amount, step.secondary);
        case 'whitebalance'
            outputImage = whiteBalance(inputImage, step.amount, step.secondary);
        otherwise
            error('labkit_ImageEnhance_app:UnknownEnhancementStep', ...
                'Unknown image enhancement step: %s', char(step.kind));
    end
    outputImage = min(max(outputImage, 0), 1);
end

function imageData = normalizeImage(imageData)
    imageData = im2double(imageData);
    if ndims(imageData) == 2
        imageData = repmat(imageData, 1, 1, 3);
    elseif size(imageData, 3) > 3
        imageData = imageData(:, :, 1:3);
    end
    imageData = min(max(imageData, 0), 1);
end

function outputImage = adjustBrightnessContrast(inputImage, brightnessPct, contrastPct)
    brightness = double(brightnessPct) / 100;
    contrastScale = max(0, 1 + double(contrastPct) / 100);
    outputImage = (inputImage - 0.5) .* contrastScale + 0.5 + brightness;
end

function outputImage = localContrast(inputImage, amountPct, radiusPx)
    amount = max(0, double(amountPct)) / 100;
    radius = max(1, round(double(radiusPx)));
    hsvImage = rgb2hsv(inputImage);
    valueChannel = hsvImage(:, :, 3);
    blurred = boxBlur(valueChannel, 2 * radius + 1);
    hsvImage(:, :, 3) = valueChannel + amount .* 1.5 .* (valueChannel - blurred);
    outputImage = hsv2rgb(hsvImage);
end

function outputImage = sharpenImage(inputImage, amountPct, radiusPx)
    amount = max(0, double(amountPct)) / 100;
    radius = max(0.5, double(radiusPx));
    windowSize = max(3, 2 * round(radius) + 1);
    blurred = zeros(size(inputImage));
    for channel = 1:size(inputImage, 3)
        blurred(:, :, channel) = boxBlur(inputImage(:, :, channel), windowSize);
    end
    outputImage = inputImage + amount .* 2.0 .* (inputImage - blurred);
end

function outputImage = adjustHueSaturation(inputImage, hueDeg, saturationPct)
    hsvImage = rgb2hsv(inputImage);
    hsvImage(:, :, 1) = mod(hsvImage(:, :, 1) + double(hueDeg) / 360, 1);
    hsvImage(:, :, 2) = hsvImage(:, :, 2) .* (1 + double(saturationPct) / 100);
    outputImage = hsv2rgb(hsvImage);
end

function outputImage = whiteBalance(inputImage, strengthPct, temperaturePct)
    strength = min(max(double(strengthPct) / 100, 0), 1);
    channelMean = squeeze(mean(inputImage, [1 2]));
    grayMean = mean(channelMean);
    gains = grayMean ./ max(channelMean, eps);
    gains = reshape(gains, 1, 1, []);
    balanced = inputImage .* gains;

    temperature = double(temperaturePct) / 100;
    balanced(:, :, 1) = balanced(:, :, 1) + 0.08 * temperature;
    balanced(:, :, 3) = balanced(:, :, 3) - 0.08 * temperature;
    outputImage = (1 - strength) .* inputImage + strength .* balanced;
end

function outputImage = boxBlur(inputImage, windowSize)
    windowSize = max(1, round(windowSize));
    kernel = ones(windowSize, windowSize);
    outputImage = conv2(inputImage, kernel, 'same') ./ ...
        conv2(ones(size(inputImage)), kernel, 'same');
end

function key = normalizeKind(kind)
    key = lower(regexprep(char(string(kind)), '[^a-zA-Z0-9]', ''));
end
