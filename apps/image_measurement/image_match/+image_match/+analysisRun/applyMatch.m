% Expected caller: image_match.analysisRun.applyStep and tests. Inputs are a source
% image, a reference image, and a match step with method/strength fields.
% Output is a display-ready RGB double image in [0, 1].
function outputImage = applyMatch(inputImage, referenceImage, step)

    inputImage = labkit.image.ensureRgb(labkit.image.im2double(inputImage));
    inputImage = min(max(inputImage, 0), 1);
    if isempty(referenceImage)
        outputImage = inputImage;
        return;
    end

    referenceImage = labkit.image.ensureRgb(labkit.image.im2double(referenceImage));
    referenceImage = min(max(referenceImage, 0), 1);
    strength = clamp01(double(step.amount) / 100);
    toneStrength = clamp01(double(step.secondary) / 100);
    colorStrength = clamp01(double(step.colorStrength) / 100);
    method = normalizeKind(step.matchMethod);
    if method == ""
        method = "balanced";
    end

    switch method
        case "whitebalance"
            matched = whiteBalanceMatch(inputImage, referenceImage);
        case "toneonly"
            matched = labToneMatch(inputImage, referenceImage, 1);
        case "protectedtone"
            matched = protectedToneMatch(inputImage, referenceImage, ...
                toneStrength, colorStrength);
        case "labstyle"
            matched = labStyleMatch(inputImage, referenceImage, ...
                toneStrength, colorStrength);
        case "histogram"
            matched = labHistogramMatch(inputImage, referenceImage, ...
                toneStrength, colorStrength);
        otherwise
            balanced = whiteBalanceMatch(inputImage, referenceImage);
            matched = labStyleMatch(balanced, referenceImage, ...
                toneStrength, colorStrength);
    end

    outputImage = min(max((1 - strength) .* inputImage + strength .* matched, 0), 1);
end

function outputImage = whiteBalanceMatch(inputImage, referenceImage)
    sourceWhite = robustWhitePoint(inputImage);
    referenceWhite = robustWhitePoint(referenceImage);
    gains = reshape(referenceWhite ./ max(sourceWhite, eps), 1, 1, 3);
    gains = gains ./ mean(gains(:));
    outputImage = min(max(inputImage .* gains, 0), 1);
end

function whitePoint = robustWhitePoint(imageData)
    luminance = mean(imageData, 3);
    chromaSpread = max(imageData, [], 3) - min(imageData, [], 3);
    brightMask = luminance >= percentileValue(luminance(:), 70);
    if any(brightMask(:))
        neutralLimit = percentileValue(chromaSpread(brightMask), 60);
        mask = brightMask & chromaSpread <= neutralLimit;
    else
        mask = true(size(luminance));
    end
    if nnz(mask) < 16
        mask = brightMask;
    end
    if nnz(mask) < 16
        mask = true(size(luminance));
    end

    pixels = reshape(imageData, [], 3);
    whitePoint = median(pixels(mask(:), :), 1);
    if any(~isfinite(whitePoint)) || any(whitePoint <= eps)
        whitePoint = squeeze(mean(imageData, [1 2])).';
    end
end

function outputImage = labToneMatch(inputImage, referenceImage, toneStrength)
    labImage = rgbToLab(inputImage);
    referenceLab = rgbToLab(referenceImage);
    matchedL = quantileMatch(labImage(:, :, 1), referenceLab(:, :, 1));
    labImage(:, :, 1) = (1 - toneStrength) .* labImage(:, :, 1) + ...
        toneStrength .* matchedL;
    outputImage = labToRgb(labImage);
end

function outputImage = protectedToneMatch(inputImage, referenceImage, toneStrength, colorStrength)
    labImage = rgbToLab(inputImage);
    referenceLab = rgbToLab(referenceImage);
    hsvImage = rgb2hsv(inputImage);
    sourceL = labImage(:, :, 1) ./ 100;
    referenceL = referenceLab(:, :, 1) ./ 100;
    sourceStats = luminanceStats(sourceL);
    referenceStats = luminanceStats(referenceL);

    scale = (referenceStats.high - referenceStats.low) ./ ...
        max(sourceStats.high - sourceStats.low, eps);
    scale = min(1.22, max(0.90, scale));
    matchedL = (sourceL - sourceStats.mid) .* scale + sourceStats.mid;
    medianShift = min(0.15, max(-0.04, referenceStats.mid - sourceStats.mid));
    matchedL = matchedL + 0.85 .* medianShift;

    sourceBackground = backgroundMask(inputImage);
    referenceBackground = backgroundMask(referenceImage);
    if nnz(sourceBackground > 0.45) >= 16 && nnz(referenceBackground > 0.45) >= 16
        sourceBackgroundLevel = weightedMean(matchedL, sourceBackground);
        referenceBackgroundLevel = weightedMean(referenceL, referenceBackground);
        lift = min(0.22, max(-0.04, referenceBackgroundLevel - sourceBackgroundLevel));
    else
        lift = min(0.14, max(-0.03, referenceStats.mid - sourceStats.mid));
    end

    brightMask = smoothstep(0.18, 0.74, sourceL);
    saturationGuard = 1 - 0.42 .* smoothstep(0.18, 0.58, hsvImage(:, :, 2));
    matchedL = matchedL + lift .* (0.35 + 0.65 .* brightMask) .* saturationGuard;
    matchedL = min(max(0.72 .* matchedL + 0.28 .* sourceL, 0), 1);
    detail = matchedL - labkit.image.meanFilter2(matchedL, 3);
    matchedL = matchedL + (0.08 + 0.05 .* double(sourceStats.contrast < 0.24)) .* detail;
    shadowMask = smoothstep(0.24, 0.08, sourceL);
    highlightMask = smoothstep(0.88, 0.99, matchedL);
    matchedL = matchedL .* (1 - 0.55 .* shadowMask) + sourceL .* (0.55 .* shadowMask);
    matchedL = matchedL .* (1 - 0.40 .* highlightMask) + min(matchedL, 0.965) .* (0.40 .* highlightMask);
    matchedL = min(max(matchedL, 0.015), 0.99);

    labOut = labImage;
    labOut(:, :, 1) = ((1 - toneStrength) .* sourceL + toneStrength .* matchedL) .* 100;
    labOut = protectedBackgroundColorMatch(labOut, referenceLab, ...
        sourceBackground, referenceBackground, colorStrength);
    outputImage = labToRgb(labOut);
end

function outputImage = labStyleMatch(inputImage, referenceImage, toneStrength, colorStrength)
    labImage = rgbToLab(inputImage);
    referenceLab = rgbToLab(referenceImage);
    matchedL = quantileMatch(labImage(:, :, 1), referenceLab(:, :, 1));
    matchedAb = covarianceMatch(labImage(:, :, 2:3), referenceLab(:, :, 2:3));
    labImage(:, :, 1) = (1 - toneStrength) .* labImage(:, :, 1) + ...
        toneStrength .* matchedL;
    labImage(:, :, 2:3) = (1 - colorStrength) .* labImage(:, :, 2:3) + ...
        colorStrength .* matchedAb;
    outputImage = labToRgb(labImage);
end

function outputImage = labHistogramMatch(inputImage, referenceImage, toneStrength, colorStrength)
    labImage = rgbToLab(inputImage);
    referenceLab = rgbToLab(referenceImage);
    matchedLab = labImage;
    matchedLab(:, :, 1) = quantileMatch(labImage(:, :, 1), referenceLab(:, :, 1));
    matchedLab(:, :, 2) = quantileMatch(labImage(:, :, 2), referenceLab(:, :, 2));
    matchedLab(:, :, 3) = quantileMatch(labImage(:, :, 3), referenceLab(:, :, 3));
    labImage(:, :, 1) = (1 - toneStrength) .* labImage(:, :, 1) + ...
        toneStrength .* matchedLab(:, :, 1);
    labImage(:, :, 2:3) = (1 - colorStrength) .* labImage(:, :, 2:3) + ...
        colorStrength .* matchedLab(:, :, 2:3);
    outputImage = labToRgb(labImage);
end

function labImage = protectedBackgroundColorMatch(labImage, referenceLab, ...
        sourceBackground, referenceBackground, colorStrength)
    if colorStrength <= 0 || nnz(sourceBackground > 0.35) < 16 || ...
            nnz(referenceBackground > 0.35) < 16
        return;
    end
    sourceA = weightedMean(labImage(:, :, 2), sourceBackground);
    sourceB = weightedMean(labImage(:, :, 3), sourceBackground);
    referenceA = weightedMean(referenceLab(:, :, 2), referenceBackground);
    referenceB = weightedMean(referenceLab(:, :, 3), referenceBackground);
    shiftA = min(2.2, max(-2.2, referenceA - sourceA));
    shiftB = min(2.2, max(-2.2, referenceB - sourceB));
    correction = 0.55 .* colorStrength .* sourceBackground;
    labImage(:, :, 2) = labImage(:, :, 2) + correction .* shiftA;
    labImage(:, :, 3) = labImage(:, :, 3) + correction .* shiftB;
end

function mask = backgroundMask(imageData)
    hsvImage = rgb2hsv(imageData);
    value = luma(imageData);
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

function matched = covarianceMatch(sourceLab, referenceLab)
    sourceSize = size(sourceLab);
    sourcePixels = reshape(sourceLab, [], sourceSize(3));
    referencePixels = reshape(referenceLab, [], sourceSize(3));
    sourceMean = mean(sourcePixels, 1);
    referenceMean = mean(referencePixels, 1);
    sourceCov = cov(sourcePixels) + 1e-6 .* eye(sourceSize(3));
    referenceCov = cov(referencePixels) + 1e-6 .* eye(sourceSize(3));
    transform = real(sqrtm(referenceCov)) / real(sqrtm(sourceCov));
    matchedPixels = (sourcePixels - sourceMean) * transform.' + referenceMean;
    matched = reshape(matchedPixels, sourceSize);
end

function matched = quantileMatch(sourceChannel, referenceChannel)
    pct = [0 1 5 10 25 50 75 90 95 99 100];
    sourceQ = percentileValues(sourceChannel(:), pct);
    referenceQ = percentileValues(referenceChannel(:), pct);
    [sourceQ, uniqueIdx] = unique(sourceQ, 'stable');
    referenceQ = referenceQ(uniqueIdx);
    if numel(sourceQ) < 2
        matched = sourceChannel;
        return;
    end
    matched = interp1(sourceQ, referenceQ, sourceChannel, 'linear', 'extrap');
end

function values = percentileValues(data, pct)
    data = sort(double(data(:)));
    if isempty(data)
        values = zeros(size(pct));
        return;
    end
    positions = 1 + (numel(data) - 1) .* double(pct) ./ 100;
    values = interp1(1:numel(data), data, positions, 'linear');
end

function value = percentileValue(data, pct)
    value = percentileValues(data, pct);
end

function imageData = normalizeImage(imageData)
    imageData = labkit.image.ensureRgb(labkit.image.im2double(imageData));
    imageData = min(max(imageData, 0), 1);
end

function gray = luma(imageData)
    gray = labkit.image.rgb2gray(imageData);
end

function outputImage = labToRgb(labImage)
    xyzImage = labToXyz(labImage);
    outputImage = xyzToRgb(xyzImage);
end

function labImage = rgbToLab(rgbImage)
    xyzImage = rgbToXyz(rgbImage);
    labImage = xyzToLab(xyzImage);
end

function xyzImage = rgbToXyz(rgbImage)
    rgbImage = min(max(double(rgbImage), 0), 1);
    linearRgb = rgbImage;
    lowMask = linearRgb <= 0.04045;
    linearRgb(lowMask) = linearRgb(lowMask) ./ 12.92;
    linearRgb(~lowMask) = ((linearRgb(~lowMask) + 0.055) ./ 1.055) .^ 2.4;

    transform = [ ...
        0.4124564 0.3575761 0.1804375; ...
        0.2126729 0.7151522 0.0721750; ...
        0.0193339 0.1191920 0.9503041];
    pixels = reshape(linearRgb, [], 3) * transform.';
    xyzImage = reshape(pixels, size(linearRgb));
end

function rgbImage = xyzToRgb(xyzImage)
    transform = [ ...
         3.2404542 -1.5371385 -0.4985314; ...
        -0.9692660  1.8760108  0.0415560; ...
         0.0556434 -0.2040259  1.0572252];
    linearPixels = reshape(double(xyzImage), [], 3) * transform.';
    linearRgb = reshape(linearPixels, size(xyzImage));
    linearRgb = min(max(linearRgb, 0), 1);

    rgbImage = linearRgb;
    lowMask = rgbImage <= 0.0031308;
    rgbImage(lowMask) = 12.92 .* rgbImage(lowMask);
    rgbImage(~lowMask) = 1.055 .* (rgbImage(~lowMask) .^ (1 / 2.4)) - 0.055;
    rgbImage = min(max(rgbImage, 0), 1);
end

function labImage = xyzToLab(xyzImage)
    white = reshape([0.95047 1.00000 1.08883], 1, 1, 3);
    scaled = double(xyzImage) ./ white;
    f = labPivotForward(scaled);

    labImage = zeros(size(xyzImage));
    labImage(:, :, 1) = 116 .* f(:, :, 2) - 16;
    labImage(:, :, 2) = 500 .* (f(:, :, 1) - f(:, :, 2));
    labImage(:, :, 3) = 200 .* (f(:, :, 2) - f(:, :, 3));
end

function xyzImage = labToXyz(labImage)
    white = reshape([0.95047 1.00000 1.08883], 1, 1, 3);
    fy = (double(labImage(:, :, 1)) + 16) ./ 116;
    fx = fy + double(labImage(:, :, 2)) ./ 500;
    fz = fy - double(labImage(:, :, 3)) ./ 200;

    scaled = cat(3, labPivotInverse(fx), labPivotInverse(fy), labPivotInverse(fz));
    xyzImage = scaled .* white;
end

function value = labPivotForward(value)
    delta = 6 / 29;
    highMask = value > delta ^ 3;
    value(highMask) = value(highMask) .^ (1 / 3);
    value(~highMask) = value(~highMask) ./ (3 * delta ^ 2) + 4 / 29;
end

function value = labPivotInverse(value)
    delta = 6 / 29;
    highMask = value > delta;
    value(highMask) = value(highMask) .^ 3;
    value(~highMask) = 3 * delta ^ 2 .* (value(~highMask) - 4 / 29);
end

function value = clamp01(value)
    value = min(max(value, 0), 1);
end

function key = normalizeKind(kind)
    key = string(lower(regexprep(char(string(kind)), '[^a-zA-Z0-9]', '')));
end
