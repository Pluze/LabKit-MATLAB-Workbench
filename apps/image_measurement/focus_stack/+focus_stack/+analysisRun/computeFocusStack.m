% App-owned image measurement package helper. Expected caller: owning app callbacks
% and package tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function result = computeFocusStack(images, opts)
%COMPUTEFOCUSSTACK Fuse focus-stack images for labkit_FocusStack_app.
%
% Expected caller:
%   labkit_FocusStack_app run callback and package tests.
%
% Inputs/outputs:
%   Cell array or numeric stack of images plus fusion options. Returns the
%   app-owned result struct with fused image, focus map, coverage, and option
%   metadata.
%
% Side effects:
%   None. This helper performs GUI-free fusion only.

    if nargin < 2
        opts = struct();
    end
    images = focus_stack.analysisRun.normalizeImageCell(images);
    if numel(images) < 2
        error('labkit_FocusStack_app:NotEnoughImages', ...
            'Focus stacking requires at least two images.');
    end

    focusWindow = oddWindow(optionValue(opts, 'focusWindow', 31), 3);
    smoothRadius = max(0, round(optionValue(opts, 'smoothRadius', 4)));
    minConfidence = optionValue(opts, 'minConfidence', 0.05);
    validateattributes(minConfidence, {'numeric'}, ...
        {'scalar', 'finite', 'nonnegative', '<=', 1});

    [stack, resizedCount] = stackImagesAsDouble(images);
    [heightPx, widthPx, channels, imageCount] = size(stack);
    pyramidLevels = max(1, min( ...
        max(1, round(optionValue(opts, 'pyramidLevels', 4))), ...
        maximumPyramidLevels([heightPx widthPx])));

    [fused, focusIndex, confidence] = laplacianPyramidFocusFusion( ...
        stack, focusWindow, smoothRadius, minConfidence, pyramidLevels);
    if channels == 1
        fused = fused(:, :, 1);
    end

    coverage = zeros(1, imageCount);
    for k = 1:imageCount
        coverage(k) = mean(focusIndex(:) == k);
    end

    result = focus_stack.appState.emptyResult();
    result.ok = true;
    result.message = '';
    result.fused = fused;
    result.focusIndex = uint16(focusIndex);
    result.confidence = confidence;
    result.focusCoverage = coverage;
    result.inputCount = imageCount;
    result.imageHeight = heightPx;
    result.imageWidth = widthPx;
    result.channelCount = channels;
    result.focusWindow = focusWindow;
    result.smoothRadius = smoothRadius;
    result.minConfidence = minConfidence;
    result.meanConfidence = mean(confidence(:));
    result.method = 'Laplacian pyramid focus fusion';
    result.resizedCount = resizedCount;
    result.pyramidLevels = pyramidLevels;
end

function [fused, focusIndex, confidence] = laplacianPyramidFocusFusion(stack, focusWindow, smoothRadius, minConfidence, pyramidLevels)
    [heightPx, widthPx, channels, imageCount] = size(stack);
    gaussPyramids = cell(imageCount, 1);
    lapPyramids = cell(imageCount, 1);
    for k = 1:imageCount
        [gaussPyramids{k}, lapPyramids{k}] = buildLaplacianPyramid( ...
            stack(:, :, :, k), pyramidLevels);
    end

    fusedLap = cell(pyramidLevels, 1);
    focusIndex = ones(heightPx, widthPx);
    confidence = zeros(heightPx, widthPx);
    for level = 1:pyramidLevels
        levelScores = focusScoreStack(lapPyramids, level, focusWindow);
        [levelIndex, bestScore, secondScore] = bestFocusIndex(levelScores);
        levelConfidence = focusConfidence(bestScore, secondScore);
        if level == 1
            focusIndex = levelIndex;
            confidence = levelConfidence;
        end

        levelSmooth = max(0, round(smoothRadius / (2 ^ (level - 1))));
        levelWeights = focusWeightsFromScores(levelScores, levelIndex, ...
            levelConfidence, minConfidence, levelSmooth);
        fusedLap{level} = weightedPyramidLevel(lapPyramids, level, levelWeights, channels);
    end

    baseScores = baseFocusScoreStack(gaussPyramids, pyramidLevels + 1);
    [baseIndex, baseBest, baseSecond] = bestFocusIndex(baseScores);
    baseConfidence = focusConfidence(baseBest, baseSecond);
    baseSmooth = max(1, round(smoothRadius / (2 ^ pyramidLevels)));
    baseWeights = focusWeightsFromScores(baseScores, baseIndex, ...
        baseConfidence, minConfidence, baseSmooth);
    fused = weightedPyramidLevel(gaussPyramids, pyramidLevels + 1, baseWeights, channels);

    for level = pyramidLevels:-1:1
        fused = focus_stack.analysisRun.resizeImageToSize(fused, size(fusedLap{level})) + fusedLap{level};
    end
    fused = min(max(fused, 0), 1);
end

function [gaussPyramid, lapPyramid] = buildLaplacianPyramid(imageData, levels)
    gaussPyramid = cell(levels + 1, 1);
    lapPyramid = cell(levels, 1);
    gaussPyramid{1} = imageData;
    for level = 1:levels
        blurred = gaussianBlurImage(gaussPyramid{level}, 1);
        gaussPyramid{level + 1} = focus_stack.analysisRun.resizeImageToSize( ...
            blurred, max(1, round([size(blurred, 1), size(blurred, 2)] .* 0.5)));
        expanded = focus_stack.analysisRun.resizeImageToSize(gaussPyramid{level + 1}, size(gaussPyramid{level}));
        lapPyramid{level} = gaussPyramid{level} - expanded;
    end
end

function scoreStack = focusScoreStack(pyramids, level, focusWindow)
    imageCount = numel(pyramids);
    sample = pyramids{1}{level};
    scoreStack = zeros(size(sample, 1), size(sample, 2), imageCount);
    levelWindow = oddWindow(max(3, round(focusWindow / (2 ^ (level - 1)))), 3);
    for k = 1:imageCount
        scoreStack(:, :, k) = focusDetailEnergy(pyramids{k}{level}, levelWindow);
    end
end

function score = focusDetailEnergy(detailImage, focusWindow)
    gray = grayImage(detailImage);
    score = labkit.image.meanFilter2(gray .^ 2, focusWindow);
    score(~isfinite(score)) = 0;
    score = max(score, 0);
end

function scoreStack = baseFocusScoreStack(pyramids, level)
    imageCount = numel(pyramids);
    sample = pyramids{1}{level};
    scoreStack = zeros(size(sample, 1), size(sample, 2), imageCount);
    for k = 1:imageCount
        scoreStack(:, :, k) = localVarianceScore(focus_stack.analysisRun.normalizeGray(pyramids{k}{level}), 5);
    end
end

function score = localVarianceScore(gray, windowSize)
    meanValue = labkit.image.meanFilter2(gray, windowSize);
    score = labkit.image.meanFilter2(gray .^ 2, windowSize) - meanValue .^ 2;
    score(~isfinite(score)) = 0;
    score = max(score, 0);
end

function weights = focusWeightsFromScores(scoreStack, focusIndex, confidence, minConfidence, smoothRadius)
    [heightPx, widthPx, imageCount] = size(scoreStack);
    weights = zeros(heightPx, widthPx, imageCount);
    lowConfidence = confidence < minConfidence;
    scoreSum = sum(scoreStack, 3);
    zeroScore = scoreSum <= eps;

    for k = 1:imageCount
        w = double(focusIndex == k);
        if any(lowConfidence(:))
            scoreWeight = scoreStack(:, :, k) ./ max(scoreSum, eps);
            w(lowConfidence) = scoreWeight(lowConfidence);
            w(lowConfidence & zeroScore) = 1 / imageCount;
        end
        if smoothRadius > 0
            w = labkit.image.meanFilter2(w, 2 * smoothRadius + 1);
        end
        weights(:, :, k) = w;
    end

    weightSum = sum(weights, 3);
    zeroWeight = weightSum <= eps;
    for k = 1:imageCount
        w = weights(:, :, k) ./ max(weightSum, eps);
        w(zeroWeight) = 1 / imageCount;
        weights(:, :, k) = w;
    end
end

function fusedLevel = weightedPyramidLevel(pyramids, level, weights, channels)
    sample = pyramids{1}{level};
    fusedLevel = zeros(size(sample, 1), size(sample, 2), channels);
    for k = 1:numel(pyramids)
        img = pyramids{k}{level};
        w = weights(:, :, k);
        for c = 1:channels
            fusedLevel(:, :, c) = fusedLevel(:, :, c) + img(:, :, c) .* w;
        end
    end
end

function confidence = focusConfidence(bestScore, secondScore)
    confidence = (bestScore - secondScore) ./ max(bestScore, eps);
    confidence(~isfinite(confidence)) = 0;
    confidence = min(max(confidence, 0), 1);
end

function [stack, resizedCount] = stackImagesAsDouble(images)
    refSize = size(images{1});
    heightPx = refSize(1);
    widthPx = refSize(2);
    channels = maxImageChannels(images);
    imageCount = numel(images);
    stack = zeros(heightPx, widthPx, channels, imageCount);
    resizedCount = 0;

    for k = 1:imageCount
        img = images{k};
        if ~isequal(size(img, 1), heightPx) || ~isequal(size(img, 2), widthPx)
            img = focus_stack.analysisRun.resizeImageToReference(img, refSize);
            resizedCount = resizedCount + 1;
        end
        img = convertChannels(labkit.image.im2double(img), channels);
        stack(:, :, :, k) = img;
    end
end

function channels = maxImageChannels(images)
    channels = 1;
    for k = 1:numel(images)
        if ndims(images{k}) == 3 && size(images{k}, 3) >= 3
            channels = 3;
            return;
        end
    end
end

function img = convertChannels(img, channels)
    if channels == 1
        if ndims(img) == 3
            img = focus_stack.analysisRun.normalizeGray(img);
        end
        return;
    end
    if ndims(img) == 2 || size(img, 3) == 1
        img = repmat(img(:, :, 1), [1 1 3]);
    elseif size(img, 3) > 3
        img = img(:, :, 1:3);
    end
end

function [focusIndex, bestScore, secondScore] = bestFocusIndex(scoreStack)
    [heightPx, widthPx, imageCount] = size(scoreStack);
    bestScore = -inf(heightPx, widthPx);
    secondScore = -inf(heightPx, widthPx);
    focusIndex = ones(heightPx, widthPx);
    for k = 1:imageCount
        score = scoreStack(:, :, k);
        better = score > bestScore;
        secondScore(better) = bestScore(better);
        bestScore(better) = score(better);
        focusIndex(better) = k;

        notBetter = ~better;
        secondScore(notBetter) = max(secondScore(notBetter), score(notBetter));
    end
    secondScore(~isfinite(secondScore)) = 0;
    bestScore(~isfinite(bestScore)) = 0;
end

function gray = grayImage(imageData)
    if ismatrix(imageData) || size(imageData, 3) == 1
        gray = imageData(:, :, 1);
    else
        gray = labkit.image.rgb2gray(labkit.image.ensureRgb(imageData));
    end
end

function imageOut = gaussianBlurImage(imageIn, sigma)
    radius = max(1, ceil(3 * sigma));
    x = -radius:radius;
    kernel = exp(-(x .^ 2) ./ (2 * sigma ^ 2));
    kernel = kernel ./ sum(kernel);
    imageOut = zeros(size(imageIn));
    for c = 1:size(imageIn, 3)
        tmp = conv2(imageIn(:, :, c), kernel, 'same');
        imageOut(:, :, c) = conv2(tmp, kernel.', 'same');
    end
end

function levels = maximumPyramidLevels(imageSize)
    levels = 1;
    rows = imageSize(1);
    cols = imageSize(2);
    while min(rows, cols) >= 96 && levels < 5
        rows = ceil(rows / 2);
        cols = ceil(cols / 2);
        levels = levels + 1;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function window = oddWindow(value, minimum)
    validateattributes(value, {'numeric'}, {'scalar', 'finite', 'positive'});
    window = max(minimum, round(value));
    if mod(window, 2) == 0
        window = window + 1;
    end
end
