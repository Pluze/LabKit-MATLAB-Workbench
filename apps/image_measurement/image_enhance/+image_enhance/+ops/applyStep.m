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
        case 'whiteroicalibration'
            outputImage = whiteRoiCalibration(inputImage, step, referenceImage);
        otherwise
            error('labkit_ImageEnhance_app:UnknownEnhancementStep', ...
                'Unknown image enhancement step: %s', char(step.kind));
    end
    outputImage = min(max(outputImage, 0), 1);
end

function outputImage = whiteRoiCalibration(inputImage, step, context)
    roi = roiFromContext(context);
    if isempty(roi)
        error('labkit_ImageEnhance_app:MissingWhiteRoi', ...
            'White ROI calibration requires a white background ROI for each image.');
    end

    roi = clampRoi(roi, size(inputImage));
    patch = inputImage(roi(2):(roi(2) + roi(4) - 1), ...
        roi(1):(roi(1) + roi(3) - 1), :);
    strength = min(max(double(step.amount) / 100, 0), 1);
    targetWhite = min(max(double(step.secondary) / 100, 0.75), 0.98);

    patchMean = squeeze(mean(patch, [1 2])).';
    backgroundLuma = rgb2gray(reshape(patchMean, 1, 1, 3));
    gains = backgroundLuma ./ max(patchMean, eps);
    gains = 1 + 0.35 .* (gains - 1);
    gains = min(max(gains, 0.85), 1.18);
    balanced = inputImage .* reshape(gains, 1, 1, []);

    luma = rgb2gray(min(max(balanced, 0), 1));
    foreground = foregroundMask(inputImage, patchMean, luma);
    highTarget = min(0.98, targetWhite + 0.06);
    lowTarget = 0.025;
    roiLuma = rgb2gray(min(max(patch .* reshape(gains, 1, 1, []), 0), 1));
    tonedLuma = autoToneLuma(luma, roiLuma, lowTarget, highTarget);
    tonedLuma = compressHighlights(tonedLuma, min(0.96, highTarget));
    tonedLuma = addLocalContrast(tonedLuma, 0.10 + 0.18 * strength);

    hsvImage = rgb2hsv(min(max(balanced, 0), 1));
    hsvImage(:, :, 3) = max(hsvImage(:, :, 3), tonedLuma);
    hsvImage(:, :, 2) = hsvImage(:, :, 2) .* (0.15 + 0.85 .* foreground);
    calibrated = hsv2rgb(hsvImage);
    calibrated = enhanceForegroundVibrance(calibrated, foreground, 0.05 * strength);
    outputImage = (1 - strength) .* inputImage + strength .* calibrated;
end

function mask = foregroundMask(inputImage, patchMean, luma)
    delta = sqrt(sum((inputImage - reshape(patchMean, 1, 1, [])).^2, 3));
    lumaDelta = abs(luma - mean(luma(:)));
    mask = min(1, max(0, (delta - 0.08) ./ 0.22 + 0.3 .* lumaDelta));
end

function out = autoToneLuma(luma, roiLuma, lowTarget, highTarget)
    values = sort(luma(:));
    if isempty(values)
        out = luma;
        return;
    end
    low = percentileFromSorted(values, 1.0);
    roiWhite = median(roiLuma(:));
    high = max(percentileFromSorted(values, 95.0), roiWhite);
    if high <= low + 0.01
        out = luma;
        return;
    end
    out = (luma - low) ./ (high - low);
    out = min(max(out, 0), 1);
    out = lowTarget + out .* (highTarget - lowTarget);
end

function value = percentileFromSorted(values, pct)
    index = 1 + (numel(values) - 1) * pct / 100;
    lo = floor(index);
    hi = ceil(index);
    if lo == hi
        value = values(lo);
    else
        value = values(lo) .* (hi - index) + values(hi) .* (index - lo);
    end
end

function out = compressHighlights(luma, shoulder)
    shoulder = min(max(shoulder, 0.72), 0.96);
    over = max(0, luma - shoulder);
    out = luma;
    out(luma > shoulder) = shoulder + over(luma > shoulder) ./ ...
        (1 + 4 .* over(luma > shoulder));
end

function out = addLocalContrast(luma, amount)
    blurred = boxBlur(luma, 17);
    detail = luma - blurred;
    out = min(max(luma + amount .* detail, 0), 1);
end

function out = enhanceForegroundVibrance(inputImage, foreground, amount)
    hsvImage = rgb2hsv(min(max(inputImage, 0), 1));
    saturation = hsvImage(:, :, 2);
    boost = amount .* foreground .* (1 - saturation);
    hsvImage(:, :, 2) = min(1, saturation .* (1 + boost));
    out = hsv2rgb(hsvImage);
end

function roi = roiFromContext(context)
    roi = [];
    if isstruct(context) && isfield(context, 'whiteRoi')
        roi = double(context.whiteRoi);
    elseif isstruct(context) && isfield(context, 'item') && ...
            isfield(context.item, 'whiteRoi')
        roi = double(context.item.whiteRoi);
    end
    if numel(roi) ~= 4 || any(~isfinite(roi)) || any(roi(3:4) <= 0)
        roi = [];
    end
end

function roi = clampRoi(roi, imageSize)
    x1 = max(1, min(imageSize(2), round(roi(1))));
    y1 = max(1, min(imageSize(1), round(roi(2))));
    x2 = max(x1, min(imageSize(2), round(roi(1) + roi(3) - 1)));
    y2 = max(y1, min(imageSize(1), round(roi(2) + roi(4) - 1)));
    roi = [x1 y1 x2 - x1 + 1 y2 - y1 + 1];
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
