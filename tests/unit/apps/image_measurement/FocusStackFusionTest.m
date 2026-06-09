classdef FocusStackFusionTest < matlab.unittest.TestCase
    %FOCUSSTACKFUSIONTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_focusStackFusion(testCase)
            setupLabKitTestPath();
            verify_focusStackFusion();
        end
    end
end

function verify_focusStackFusion()
%TEST_FOCUSSTACKFUSION Verify focus-stack fusion app calculations.

    checkSyntheticFocusSelection();
    checkSummaryTableContract();
    checkFolderDiscovery();
    checkSelectedFileSelection();
    checkRegistrationImprovesSyntheticDrift();
    checkInvalidInputs();
end

function checkSyntheticFocusSelection()
    [nearImage, farImage, mid] = syntheticFocusPair();
    opts = struct('focusWindow', 5, 'smoothRadius', 0, 'minConfidence', 0);

    result = focus_stack.ops.computeFocusStack({nearImage, farImage}, opts);

    assert(result.ok, 'Focus stack should succeed for a two-image synthetic stack.');
    assert(result.inputCount == 2, 'Input image count changed.');
    assert(result.imageHeight == size(nearImage, 1), 'Fused image height changed.');
    assert(result.imageWidth == size(nearImage, 2), 'Fused image width changed.');
    assert(result.channelCount == 3, 'RGB channel handling changed.');
    assert(abs(sum(result.focusCoverage) - 1) < 1e-12, ...
        'Focus coverage should sum to one.');

    idx = double(result.focusIndex);
    margin = 8;
    leftRegion = idx(:, 1:(mid - margin));
    rightRegion = idx(:, (mid + margin):end);
    leftNearFraction = mean(leftRegion(:) == 1);
    rightFarFraction = mean(rightRegion(:) == 2);

    assert(leftNearFraction > 0.80, ...
        'Left sharp region should mostly select the first image.');
    assert(rightFarFraction > 0.80, ...
        'Right sharp region should mostly select the second image.');
    assert(all(result.fused(:) >= 0 & result.fused(:) <= 1), ...
        'Fused image should stay in displayable double range.');
end

function checkSummaryTableContract()
    [nearImage, farImage] = syntheticFocusPair();
    result = focus_stack.ops.computeFocusStack({nearImage, farImage}, ...
        struct('focusWindow', 5, 'smoothRadius', 1, 'minConfidence', 0.05));

    T = focus_stack.export.buildSummaryTable( ...
        result, ["slice_a.png"; "slice_b.png"]);

    assert(isequal(T.Properties.VariableNames, expectedSummaryColumns()), ...
        'Focus stack summary columns changed.');
    assert(height(T) == 2, 'Summary table should include one row per source image.');
    assert(T.SourceImage(1) == "slice_a.png", ...
        'Summary table should preserve source image display names.');
    assert(T.DetailScale_px(1) == result.focusWindow, ...
        'Summary table should preserve detail-scale option.');
    assert(T.BlendRadius_px(1) == result.smoothRadius, ...
        'Summary table should preserve blend-radius option.');
end

function checkFolderDiscovery()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    imwrite(uint8(255 * ones(8, 8)), fullfile(folder, 'slice_b.png'));
    imwrite(uint8(128 * ones(8, 8)), fullfile(folder, 'slice_a.jpg'));
    fid = fopen(fullfile(folder, 'notes.txt'), 'w');
    fprintf(fid, 'not an image fixture');
    fclose(fid);

    paths = focus_stack.io.findImages(folder);
    names = cell(numel(paths), 1);
    for k = 1:numel(paths)
        [~, base, ext] = fileparts(char(paths(k)));
        names{k} = [base ext];
    end

    assert(isequal(names, {'slice_a.jpg'; 'slice_b.png'}), ...
        'Image folder discovery should filter image files and sort by name.');
end

function checkSelectedFileSelection()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    paths = focus_stack.io.selectedImagePaths( ...
        {'frame_b.png', 'frame_a.tif'}, folder);
    names = fileNames(paths);
    assert(isequal(names, {'frame_a.tif'; 'frame_b.png'}), ...
        'Selected image files should be normalized and sorted by name.');

    onePath = focus_stack.io.selectedImagePaths('frame_c.jpg', folder);
    assert(numel(onePath) == 1 && endsWith(onePath, "frame_c.jpg"), ...
        'Single-file selection should be accepted for preview before stacking.');

    assertThrows(@() focus_stack.io.selectedImagePaths('notes.txt', folder), ...
        'labkit_FocusStack_app:UnsupportedImageFile', ...
        'Manual selection should reject unsupported file types.');
end

function checkRegistrationImprovesSyntheticDrift()
    reference = syntheticRegistrationImage();
    moving = integerTranslateImage(reference, -3, 4, median(reference(:)));

    [aligned, lines] = focus_stack.ops.alignImages({moving, reference});

    beforeErr = mean((im2double(moving(:)) - im2double(reference(:))) .^ 2);
    afterErr = mean((im2double(aligned{1}(:)) - im2double(reference(:))) .^ 2);
    assert(afterErr < beforeErr, ...
        'Automatic registration should reduce synthetic alignment error.');
    assert(contains(strjoin(string(lines), " "), "reference image: 2"), ...
        'Registration should use the middle stack image as reference.');
end

function names = fileNames(paths)
    paths = string(paths(:));
    names = cell(numel(paths), 1);
    for k = 1:numel(paths)
        [~, base, ext] = fileparts(char(paths(k)));
        names{k} = [base ext];
    end
end

function checkInvalidInputs()
    assertThrows(@() focus_stack.ops.computeFocusStack({zeros(8, 8)}, struct()), ...
        'labkit_FocusStack_app:NotEnoughImages', ...
        'Single-image stacks should be rejected.');
    assertThrows(@() focus_stack.ops.computeFocusStack( ...
        {zeros(8, 8), zeros(8, 8)}, ...
        struct('focusWindow', 0)), ...
        'MATLAB:expectedPositive', ...
        'Invalid focus window should be rejected.');
end

function [nearImage, farImage, mid] = syntheticFocusPair()
    heightPx = 72;
    widthPx = 104;
    [x, y] = meshgrid(1:widthPx, 1:heightPx);
    sharp = 0.5 + 0.25 .* sin(0.75 .* x) + 0.25 .* cos(0.65 .* y);
    sharp = min(max(sharp, 0), 1);
    blurred = boxBlur(sharp, 13);

    mid = floor(widthPx / 2);
    nearMask = false(heightPx, widthPx);
    nearMask(:, 1:mid) = true;

    nearGray = blurred;
    farGray = blurred;
    nearGray(nearMask) = sharp(nearMask);
    farGray(~nearMask) = sharp(~nearMask);

    nearImage = cat(3, nearGray, 0.85 .* nearGray, 0.65 .* nearGray);
    farImage = cat(3, farGray, 0.85 .* farGray, 0.65 .* farGray);
end

function imageData = syntheticRegistrationImage()
    [x, y] = meshgrid(1:96, 1:72);
    base = 0.2 + 0.5 .* exp(-((x - 48) .^ 2 + (y - 36) .^ 2) ./ 300);
    ring = abs(sqrt((x - 48) .^ 2 + (y - 36) .^ 2) - 18) < 2;
    line = abs(y - 0.55 .* x - 8) < 1.5;
    imageData = base;
    imageData(ring) = 1;
    imageData(line) = 0.85;
    imageData = uint8(255 .* min(max(imageData, 0), 1));
end

function out = boxBlur(in, windowSize)
    kernel = ones(windowSize, windowSize);
    out = conv2(in, kernel, 'same') ./ conv2(ones(size(in)), kernel, 'same');
end

function out = integerTranslateImage(in, rowShift, colShift, fillValue)
    out = zeros(size(in), class(in));
    out(:) = cast(fillValue, class(in));

    rows = size(in, 1);
    cols = size(in, 2);
    dstRows = max(1, 1 + rowShift):min(rows, rows + rowShift);
    dstCols = max(1, 1 + colShift):min(cols, cols + colShift);
    srcRows = max(1, 1 - rowShift):min(rows, rows - rowShift);
    srcCols = max(1, 1 - colShift):min(cols, cols - colShift);
    if isempty(dstRows) || isempty(dstCols) || isempty(srcRows) || isempty(srcCols)
        return;
    end
    out(dstRows, dstCols, :) = in(srcRows, srcCols, :);
end

function columns = expectedSummaryColumns()
    columns = {'SourceImage', 'FocusIndex', ...
        'SelectedPixelFraction', 'SelectedPixelPercent', 'MeanConfidence', ...
        'Method', 'FusedHeight_px', 'FusedWidth_px', ...
        'DetailScale_px', 'BlendRadius_px', 'UncertainBlendFraction'};
end

function assertThrows(fn, expectedIdentifier, label)
    try
        fn();
    catch ME
        assert(strcmp(ME.identifier, expectedIdentifier), ...
            '%s Expected %s but caught %s.', ...
            label, expectedIdentifier, ME.identifier);
        return;
    end
    error('%s Expected an error with identifier %s.', label, expectedIdentifier);
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
