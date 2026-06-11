% Expected caller: image_match.ops.applyStep and tests. Inputs are a source
% image, a reference image, and a match step with method/strength fields.
% Output is a display-ready RGB double image in [0, 1].
function outputImage = applyMatch(inputImage, referenceImage, step)

    inputImage = normalizeImage(inputImage);
    if isempty(referenceImage)
        outputImage = inputImage;
        return;
    end

    referenceImage = normalizeImage(referenceImage);
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
    labImage = rgb2lab(inputImage);
    referenceLab = rgb2lab(referenceImage);
    matchedL = quantileMatch(labImage(:, :, 1), referenceLab(:, :, 1));
    labImage(:, :, 1) = (1 - toneStrength) .* labImage(:, :, 1) + ...
        toneStrength .* matchedL;
    outputImage = labToRgb(labImage);
end

function outputImage = labStyleMatch(inputImage, referenceImage, toneStrength, colorStrength)
    labImage = rgb2lab(inputImage);
    referenceLab = rgb2lab(referenceImage);
    matchedL = quantileMatch(labImage(:, :, 1), referenceLab(:, :, 1));
    matchedAb = covarianceMatch(labImage(:, :, 2:3), referenceLab(:, :, 2:3));
    labImage(:, :, 1) = (1 - toneStrength) .* labImage(:, :, 1) + ...
        toneStrength .* matchedL;
    labImage(:, :, 2:3) = (1 - colorStrength) .* labImage(:, :, 2:3) + ...
        colorStrength .* matchedAb;
    outputImage = labToRgb(labImage);
end

function outputImage = labHistogramMatch(inputImage, referenceImage, toneStrength, colorStrength)
    labImage = rgb2lab(inputImage);
    referenceLab = rgb2lab(referenceImage);
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
    imageData = im2double(imageData);
    if ndims(imageData) == 2
        imageData = repmat(imageData, 1, 1, 3);
    elseif size(imageData, 3) > 3
        imageData = imageData(:, :, 1:3);
    end
    imageData = min(max(imageData, 0), 1);
end

function outputImage = labToRgb(labImage)
    outputImage = min(max(lab2rgb(labImage), 0), 1);
end

function value = clamp01(value)
    value = min(max(value, 0), 1);
end

function key = normalizeKind(kind)
    key = string(lower(regexprep(char(string(kind)), '[^a-zA-Z0-9]', '')));
end
