classdef ImageMatchTest < matlab.unittest.TestCase
    %IMAGEMATCHTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_imageMatch(testCase)
            setupLabKitTestPath();
            verify_imageMatch();
        end
    end
end

function verify_imageMatch()
%TEST_IMAGEMATCH Verify reference image matching calculations and exports.

    checkWhiteBalanceMatchMovesChannelRatiosTowardReference();
    checkToneOnlyMatchMovesBrightnessWithoutChangingColorStrongly();
    checkLabStyleMatchMovesColorTowardReference();
    checkHistogramMatchPreservesDisplayRange();
    checkManifestAndExportContract();
end

function checkWhiteBalanceMatchMovesChannelRatiosTowardReference()
    base = syntheticGradientImage();
    source = tintImage(base, [0.62 0.86 1.25]);
    reference = tintImage(base, [1.18 0.96 0.72]);
    beforeDistance = channelRatioDistance(source, reference);

    step = image_match.ops.makeStep(2, 'White balance', 100, 100, 100);
    processed = image_match.ops.applyPipeline({source; reference}, step);
    afterDistance = channelRatioDistance(processed{1}, reference);

    assert(afterDistance < beforeDistance * 0.55, ...
        'White-balance matching should move source channel ratios toward the reference.');
end

function checkToneOnlyMatchMovesBrightnessWithoutChangingColorStrongly()
    base = syntheticGradientImage();
    source = 0.38 .* base + 0.10;
    reference = min(1, 1.18 .* base + 0.18);
    sourceRatio = channelRatios(source);

    step = image_match.ops.makeStep(2, 'Tone only', 100, 100, 0);
    processed = image_match.ops.applyPipeline({source; reference}, step);
    out = processed{1};

    assert(mean(out(:)) > mean(source(:)), ...
        'Tone-only matching should move source brightness toward a brighter reference.');
    assert(norm(channelRatios(out) - sourceRatio) < 0.12, ...
        'Tone-only matching should not strongly alter average color ratios.');
end

function checkLabStyleMatchMovesColorTowardReference()
    [source, reference] = syntheticColorPair();
    beforeDistance = meanChannelDistance(source, reference);

    step = image_match.ops.makeStep(2, 'Lab style', 100, 80, 100);
    processed = image_match.ops.applyPipeline({source; reference}, step);
    afterDistance = meanChannelDistance(processed{1}, reference);

    assert(afterDistance < beforeDistance * 0.60, ...
        'Lab style matching should move source channel means toward the reference.');
end

function checkHistogramMatchPreservesDisplayRange()
    [source, reference] = syntheticColorPair();
    step = image_match.ops.makeStep(2, 'Histogram', 75, 100, 100);
    processed = image_match.ops.applyPipeline({source; reference}, step);
    out = processed{1};

    assert(isequal(size(out), size(source)), ...
        'Histogram matching should preserve image size.');
    assert(all(out(:) >= 0 & out(:) <= 1), ...
        'Histogram matching should clamp output to display range.');
end

function checkManifestAndExportContract()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = string(fullfile(folder, 'sample.png'));
    referencePath = string(fullfile(folder, 'reference.png'));
    imwrite(uint8(120 * ones(10, 12, 3)), sourcePath);
    imwrite(uint8(180 * ones(10, 12, 3)), referencePath);
    imwrite(uint8(255 * ones(5, 5, 3)), fullfile(folder, 'sample_matched.png'));

    items = image_match.io.readImages([sourcePath; referencePath]);
    steps = image_match.ops.makeStep(2, 'Balanced', 100, 100, 100);
    payload = image_match.export.writeOutputs(items, steps, struct( ...
        'outputFolder', string(folder), ...
        'format', 'PNG'));

    assert(endsWith(payload.results(1).outputPath, "sample_matched_001.png"), ...
        'Batch export should avoid overwriting existing matched outputs.');
    assert(isfile(payload.results(1).outputPath), ...
        'Batch export should write matched image output.');
    assert(isfile(payload.manifestPath), ...
        'Batch export should write a manifest CSV.');

    T = image_match.export.buildManifest(payload.results);
    assert(isequal(T.Properties.VariableNames, expectedManifestColumns()), ...
        'Image match manifest columns changed.');
    assert(T.StepCount(1) == 1, 'Manifest should preserve step count.');
end

function img = syntheticGradientImage()
    [x, y] = meshgrid(linspace(0, 1, 72), linspace(0, 1, 48));
    img = cat(3, x, y, 0.5 .* x + 0.5 .* y);
end

function [source, reference] = syntheticColorPair()
    base = syntheticGradientImage();
    source = cat(3, 0.55 .* base(:, :, 1), 0.70 .* base(:, :, 2), ...
        1.10 .* base(:, :, 3));
    reference = cat(3, 0.80 .* base(:, :, 1) + 0.05, ...
        0.55 .* base(:, :, 2) + 0.10, 0.60 .* base(:, :, 3) + 0.20);
end

function imageData = tintImage(imageData, gains)
    imageData = min(max(imageData .* reshape(gains, 1, 1, 3), 0), 1);
end

function distance = channelRatioDistance(a, b)
    distance = norm(channelRatios(a) - channelRatios(b));
end

function ratios = channelRatios(img)
    means = squeeze(mean(img, [1 2])).';
    ratios = means ./ max(mean(means), eps);
end

function distance = meanChannelDistance(a, b)
    aMeans = squeeze(mean(a, [1 2]));
    bMeans = squeeze(mean(b, [1 2]));
    distance = norm(aMeans - bMeans);
end

function cols = expectedManifestColumns()
    cols = {'SourceImage', 'OutputImage', 'Status', 'Width_px', ...
        'Height_px', 'StepCount', 'Message'};
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
