% Expected caller: image_enhance.ops.applyPipeline and focused tests. Inputs
% are one RGB double source image, a normalized step, and an optional reference
% image for match-reference steps. Output is RGB double image data in [0, 1].
function outputImage = applyStep(inputImage, step, referenceImage)

    inputImage = labkit.image.toRgbDouble(inputImage);
    key = normalizeKind(step.kind);
    switch key
        case 'brightnesscontrast'
            outputImage = labkit.image.adjustBrightnessContrast(inputImage, ...
                step.amount, step.secondary);
        case 'localcontrast'
            outputImage = labkit.image.localContrast(inputImage, ...
                step.amount, step.secondary);
        case 'sharpen'
            outputImage = labkit.image.sharpen(inputImage, ...
                step.amount, step.secondary);
        case 'huesaturation'
            outputImage = labkit.image.adjustHueSaturation(inputImage, ...
                step.amount, step.secondary);
        case 'whitebalance'
            outputImage = labkit.image.grayWorldWhiteBalance(inputImage, ...
                step.amount, step.secondary);
        case 'whiteroicalibration'
            outputImage = protectedBackgroundEnhance(inputImage, step, referenceImage, true);
        case 'subjectpreservingenhance'
            outputImage = protectedBackgroundEnhance(inputImage, step, [], false);
        otherwise
            error('labkit_ImageEnhance_app:UnknownEnhancementStep', ...
                'Unknown image enhancement step: %s', char(step.kind));
    end
    outputImage = min(max(outputImage, 0), 1);
end

function outputImage = protectedBackgroundEnhance(inputImage, step, context, requireRoi)
    strength = clamp01(double(step.amount) / 100);
    targetWhite = min(max(double(step.secondary) / 100, 0.70), 0.98);
    backgroundMask = backgroundMaskFromContext(inputImage, context, requireRoi);

    if exist('rgb2lab', 'file') ~= 2 || exist('lab2rgb', 'file') ~= 2
        outputImage = protectedRgbFallback(inputImage, strength, targetWhite, backgroundMask);
        return;
    end

    labImage = rgb2lab(inputImage);
    sourceL = labImage(:, :, 1) ./ 100;
    hsvImage = rgb2hsv(inputImage);
    sat = hsvImage(:, :, 2);
    stats = luminanceStats(sourceL);

    contrastScale = min(1.18, max(0.92, 0.30 ./ max(stats.contrast, 0.08)));
    tonedL = (sourceL - stats.mid) .* contrastScale + stats.mid;
    backgroundLevel = weightedMean(tonedL, backgroundMask);
    maxLift = 0.22 + 0.23 .* double(requireRoi);
    sourceBlend = 0.28 - 0.20 .* double(requireRoi);
    lift = min(maxLift, max(0, targetWhite - backgroundLevel));
    brightMask = smoothstep(0.18, 0.74, sourceL);
    saturationGuard = 1 - 0.42 .* smoothstep(0.18, 0.58, sat);
    tonedL = tonedL + lift .* (0.35 + 0.65 .* brightMask) .* saturationGuard;
    tonedL = min(max((1 - sourceBlend) .* tonedL + sourceBlend .* sourceL, 0), 1);

    detail = tonedL - labkit.image.meanFilter2(tonedL, 3);
    tonedL = tonedL + (0.08 + 0.05 .* double(stats.contrast < 0.24)) .* detail;
    shadowMask = smoothstep(0.24, 0.08, sourceL);
    highlightMask = smoothstep(0.88, 0.99, tonedL);
    tonedL = tonedL .* (1 - 0.55 .* shadowMask) + sourceL .* (0.55 .* shadowMask);
    tonedL = tonedL .* (1 - 0.40 .* highlightMask) + min(tonedL, 0.965) .* (0.40 .* highlightMask);
    tonedL = min(max(tonedL, 0.015), 0.99);

    labOut = labImage;
    labOut(:, :, 1) = ((1 - strength) .* sourceL + strength .* tonedL) .* 100;
    labOut = correctBackgroundLabCast(labOut, backgroundMask, strength);
    outputImage = lab2rgb(labOut, 'OutputType', 'double');
    finishLift = 0.08 + 0.14 .* double(requireRoi);
    outputImage = finishBackgroundLuma(outputImage, inputImage, ...
        backgroundMask, targetWhite, strength, finishLift);
    outputImage = min(max(outputImage, 0), 1);
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

function mask = backgroundMaskFromContext(inputImage, context, requireRoi)
    roi = roiFromContext(context);
    if requireRoi && isempty(roi)
        error('labkit_ImageEnhance_app:MissingWhiteRoi', ...
            'White ROI calibration requires a white background ROI for each image.');
    end
    if ~isempty(roi)
        roi = clampRoi(roi, size(inputImage));
        mask = zeros(size(inputImage, 1), size(inputImage, 2));
        mask(roi(2):(roi(2) + roi(4) - 1), ...
            roi(1):(roi(1) + roi(3) - 1)) = 1;
        mask = labkit.image.meanFilter2(mask, ...
            max(9, 2 * round(max(roi(3:4)) / 5) + 1));
        mask = min(max(mask, 0), 1);
        return;
    end

    hsvImage = rgb2hsv(inputImage);
    value = rgb2gray(inputImage);
    sat = hsvImage(:, :, 2);
    mask = smoothstep(0.22, 0.03, sat) .* smoothstep(0.30, 0.78, value);
    if nnz(mask > 0.45) < 100
        mask = smoothstep(0.30, 0.06, sat) .* smoothstep(0.20, 0.86, value);
    end
    if nnz(mask > 0.20) < 16
        mask = ones(size(value));
    end
    mask = min(max(labkit.image.meanFilter2(mask, 7), 0), 1);
end

function labImage = correctBackgroundLabCast(labImage, backgroundMask, strength)
    if nnz(backgroundMask > 0.35) < 16
        return;
    end
    meanA = weightedMean(labImage(:, :, 2), backgroundMask);
    meanB = weightedMean(labImage(:, :, 3), backgroundMask);
    shiftA = min(2.2, max(-2.2, -meanA));
    shiftB = min(2.2, max(-2.2, -meanB));
    correction = 0.55 .* strength .* backgroundMask;
    labImage(:, :, 2) = labImage(:, :, 2) + correction .* shiftA;
    labImage(:, :, 3) = labImage(:, :, 3) + correction .* shiftB;
end

function outputImage = protectedRgbFallback(inputImage, strength, targetWhite, backgroundMask)
    luma = rgb2gray(inputImage);
    stats = luminanceStats(luma);
    contrastScale = min(1.12, max(0.92, 0.28 ./ max(stats.contrast, 0.08)));
    toned = (luma - stats.mid) .* contrastScale + stats.mid;
    lift = min(0.16, max(0, targetWhite - weightedMean(toned, backgroundMask)));
    toned = min(max(toned + lift .* (0.35 + 0.65 .* smoothstep(0.18, 0.74, luma)), 0), 1);
    ratio = min(1.18, max(0.88, toned ./ max(luma, 0.04)));
    outputImage = (1 - strength) .* inputImage + strength .* (inputImage .* ratio);
end

function outputImage = finishBackgroundLuma(outputImage, inputImage, backgroundMask, targetWhite, strength, maxLift)
    luma = rgb2gray(outputImage);
    backgroundLevel = weightedMean(luma, backgroundMask);
    lift = min(maxLift, max(0, targetWhite - backgroundLevel));
    if lift <= 0
        return;
    end
    hsvImage = rgb2hsv(inputImage);
    sourceLuma = rgb2gray(inputImage);
    saturationGuard = 1 - 0.58 .* smoothstep(0.18, 0.58, hsvImage(:, :, 2));
    brightMask = smoothstep(0.18, 0.74, sourceLuma);
    correction = strength .* lift .* (0.35 + 0.65 .* brightMask) .* saturationGuard;
    outputImage = outputImage + repmat(correction, 1, 1, 3);
end

function stats = luminanceStats(value)
    values = sort(double(value(isfinite(value))));
    stats = struct('low', 0, 'mid', 0, 'high', 0, 'contrast', 0);
    if isempty(values)
        return;
    end
    stats.low = percentileFromSorted(values, 1);
    stats.mid = percentileFromSorted(values, 50);
    stats.high = percentileFromSorted(values, 99);
    stats.contrast = percentileFromSorted(values, 90) - percentileFromSorted(values, 10);
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

function out = weightedMean(values, weights)
    values = double(values(:));
    weights = double(weights(:));
    valid = isfinite(values) & isfinite(weights) & weights > 0;
    if ~any(valid)
        out = mean(values(isfinite(values)), 'omitnan');
        return;
    end
    out = sum(values(valid) .* weights(valid)) ./ sum(weights(valid));
end

function y = smoothstep(edge0, edge1, x)
    t = (x - edge0) ./ max(edge1 - edge0, eps);
    t = min(max(t, 0), 1);
    y = t .* t .* (3 - 2 .* t);
end

function value = clamp01(value)
    value = min(max(value, 0), 1);
end

function key = normalizeKind(kind)
    key = lower(regexprep(char(string(kind)), '[^a-zA-Z0-9]', ''));
end
