classdef BatchImageCropTest < matlab.unittest.TestCase
    %BATCHIMAGECROPTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_batchImageCrop(testCase)
            setupLabKitTestPath();
            verify_batchImageCrop();
        end
    end
end

function verify_batchImageCrop()
%TEST_BATCHIMAGECROP Verify batch microscope crop calculations and exports.

    checkFixedPixelCropPreservesClassAndSize();
    checkOutOfBoundsCropUsesWhiteBackground();
    checkReflectedPaddingPreservesSourceAndSoftensEdge();
    checkCoordinateTransformsRoundTripOriginalPoints();
    checkPaddingDoesNotMoveCropCenterMetadata();
    checkRotatedCropKeepsRequestedSize();
    checkRotationBackgroundUsesWhiteFill();
    checkSelectedFileNormalization();
    checkReadItemsAcceptsPathPanelCellPaths();
    checkDuplicateItemCreatesIndependentCropTask();
    checkManifestContract();
    checkExportWritesUniqueOutputs();
    checkExportWritesUniqueOutputsForDuplicateSource();
end

function checkFixedPixelCropPreservesClassAndSize()
    img = uint8(reshape(1:100, 10, 10));
    result = batch_crop.ops.cropImage(img, struct( ...
        'cropWidth', 4, ...
        'cropHeight', 3, ...
        'centerXY', [5, 6], ...
        'angleDeg', 0, ...
        'paddingPercent', 0));

    assert(result.ok, 'Crop should succeed.');
    assert(isa(result.image, 'uint8'), 'Crop should preserve image class.');
    assert(isequal(size(result.image), [3 4]), ...
        'Crop output size should be exactly height-by-width pixels.');
    assert(result.cropWidth == 4 && result.cropHeight == 3, ...
        'Crop metadata should preserve requested size.');
end

function checkOutOfBoundsCropUsesWhiteBackground()
    img = uint8(10 * ones(5, 5));
    result = batch_crop.ops.cropImage(img, struct( ...
        'cropWidth', 4, ...
        'cropHeight', 4, ...
        'centerXY', [1, 1], ...
        'angleDeg', 0, ...
        'paddingPercent', 0));

    assert(isequal(size(result.image), [4 4]), ...
        'Out-of-bounds crops should still use the requested output size.');
    assert(result.image(1, 1) == intmax('uint8'), ...
        'Out-of-bounds crop area should use the fixed white background.');
    assert(result.image(end, end) == 10, ...
        'In-bounds crop area should preserve source pixels.');
end

function checkReflectedPaddingPreservesSourceAndSoftensEdge()
    img = uint8(repmat([10 40 80 120], 4, 1));
    [padded, padding] = batch_crop.ops.padImageEdges(img, 50);

    sourceBlock = padded((1:4) + padding.top, (1:4) + padding.left);
    assert(isequal(sourceBlock, img), ...
        'Padding must not alter source-image pixels.');
    edgeValue = double(padded(padding.top + 1, padding.left + 1));
    firstPaddingValue = double(padded(padding.top + 1, padding.left));
    rawReflectedValue = double(img(1, 2));
    assert(abs(firstPaddingValue - edgeValue) < abs(rawReflectedValue - edgeValue), ...
        'Padding should blend reflected pixels near the edge to avoid a hard seam.');
end

function checkCoordinateTransformsRoundTripOriginalPoints()
    img = uint8(zeros(6, 8));
    geometry = batch_crop.ops.prepareCropCanvas(img, struct( ...
        'angleDeg', 27, ...
        'paddingPercent', 25));
    originalXY = [2.75, 4.25];

    canvasXY = batch_crop.ops.originalToCanvas(geometry, originalXY);
    recoveredXY = batch_crop.ops.canvasToOriginal(geometry, canvasXY);

    assert(max(abs(recoveredXY - originalXY)) < 1e-9, ...
        'Canvas/original coordinate transforms should preserve source coordinates.');
end

function checkPaddingDoesNotMoveCropCenterMetadata()
    img = uint8(zeros(7, 9));
    result = batch_crop.ops.cropImage(img, struct( ...
        'cropWidth', 3, ...
        'cropHeight', 3, ...
        'centerXY', [2, 5], ...
        'angleDeg', 33, ...
        'paddingPercent', 40));

    assert(result.centerX == 2 && result.centerY == 5, ...
        'Crop result metadata should keep original-image center coordinates.');
    assert(result.sourceWidth == 9 && result.sourceHeight == 7, ...
        'Crop result metadata should expose source dimensions, not padded canvas size.');
    assert(result.paddingPercent == 40, ...
        'Crop result metadata should preserve the selected padding percent.');
end

function checkRotatedCropKeepsRequestedSize()
    img = uint8(zeros(8, 12, 3));
    img(:, 4:8, 1) = 200;
    result = batch_crop.ops.cropImage(img, struct( ...
        'cropWidth', 6, ...
        'cropHeight', 5, ...
        'angleDeg', 35, ...
        'paddingPercent', 15));
    geometry = batch_crop.ops.prepareCropCanvas(img, struct( ...
        'angleDeg', 35, ...
        'paddingPercent', 15));

    assert(isequal(size(result.image), [5 6 3]), ...
        'Rotated crop output size should remain fixed.');
    assert(size(geometry.canvas, 2) > size(img, 2) || size(geometry.canvas, 1) > size(img, 1), ...
        'Padded loose rotation should expand the internal preview canvas.');
end

function checkRotationBackgroundUsesWhiteFill()
    img = uint8(zeros(5, 5));
    result = batch_crop.ops.cropImage(img, struct( ...
        'cropWidth', 9, ...
        'cropHeight', 9, ...
        'centerXY', [3, 3], ...
        'angleDeg', 45, ...
        'paddingPercent', 0));

    assert(max(result.image(:)) == intmax('uint8'), ...
        'Rotation and crop regions outside the source canvas should use white background fill.');
end

function checkSelectedFileNormalization()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    paths = batch_crop.io.selectedImagePaths( ...
        {'frame_b.png', 'frame_a.tif'}, folder);
    names = fileNames(paths);
    assert(isequal(names, {'frame_a.tif'; 'frame_b.png'}), ...
        'Selected batch crop images should be sorted by filename.');

    assertThrows(@() batch_crop.io.selectedImagePaths('notes.txt', folder), ...
        'labkit_BatchImageCrop_app:UnsupportedImageFile', ...
        'Manual selection should reject unsupported file types.');
end

function checkReadItemsAcceptsPathPanelCellPaths()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = fullfile(folder, 'frame_a.png');
    imwrite(uint8(42 * ones(6, 7)), sourcePath);

    items = batch_crop.state.readItems({sourcePath});
    assert(numel(items) == 1, ...
        'Batch crop reader should accept pathPanel cell-array paths.');
    assert(items(1).path == string(sourcePath), ...
        'Batch crop reader should preserve the selected source path.');
    assert(isequal(size(items(1).image), [6 7]), ...
        'Batch crop reader should load image data from pathPanel paths.');
end

function checkDuplicateItemCreatesIndependentCropTask()
    item = batch_crop.state.emptyItem();
    item.path = "source.png";
    item.image = uint8(ones(5, 6));
    item.angleDeg = 12;
    item.centerXY = [3, 4];
    item.centerSet = true;

    duplicated = batch_crop.state.duplicateItem(item);
    assert(duplicated.path == item.path, ...
        'Duplicated crop task should preserve the source image path.');
    assert(isequal(duplicated.image, item.image), ...
        'Duplicated crop task should reuse the loaded image data.');
    assert(duplicated.angleDeg == item.angleDeg, ...
        'Duplicated crop task should preserve rotation.');
    assert(~duplicated.centerSet && all(isnan(duplicated.centerXY)), ...
        'Duplicated crop task should require a new crop center.');
end

function checkManifestContract()
    result = batch_crop.ops.cropImage(uint8(ones(5, 6)), struct( ...
        'cropWidth', 3, ...
        'cropHeight', 4, ...
        'centerXY', [3, 3], ...
        'angleDeg', 0));
    result.sourcePath = "source.png";
    result.outputPath = "source_crop.png";
    result.status = "saved";
    result.message = "Saved";

    T = batch_crop.export.buildManifest(result);
    assert(isequal(T.Properties.VariableNames, expectedManifestColumns()), ...
        'Batch crop manifest columns changed.');
    assert(height(T) == 1, 'Manifest should include one row per crop result.');
    assert(T.CropWidth_px(1) == 3 && T.CropHeight_px(1) == 4, ...
        'Manifest should preserve fixed crop size metadata.');
    assert(T.PaddingPercent(1) == 0 && T.SourceWidth_px(1) == 6 && T.SourceHeight_px(1) == 5, ...
        'Manifest should expose padding percent and source dimensions.');
end

function checkExportWritesUniqueOutputs()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));
    imwrite(uint8(zeros(4, 4)), fullfile(folder, 'sample_crop.png'));

    item = struct( ...
        'path', string(fullfile(folder, 'sample.png')), ...
        'image', uint8(20 * ones(6, 6)), ...
        'angleDeg', 0, ...
        'centerXY', [3, 3], ...
        'centerSet', true);

    payload = batch_crop.export.writeOutputs(item, struct( ...
        'outputFolder', string(folder), ...
        'format', 'PNG', ...
        'cropWidth', 4, ...
        'cropHeight', 4, ...
        'paddingPercent', 0));

    outputPath = payload.results(1).outputPath;
    assert(endsWith(outputPath, "sample_crop_001.png"), ...
        'Batch export should avoid overwriting existing crop outputs.');
    assert(isfile(outputPath), 'Batch export should write cropped image output.');
    assert(isfile(payload.manifestPath), 'Batch export should write a manifest CSV.');
end

function checkExportWritesUniqueOutputsForDuplicateSource()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = string(fullfile(folder, 'shared_source.png'));
    item = struct( ...
        'path', sourcePath, ...
        'image', uint8(20 * ones(8, 8)), ...
        'angleDeg', 0, ...
        'centerXY', [3, 3], ...
        'centerSet', true);
    items = [item; item];
    items(2).centerXY = [6, 6];

    payload = batch_crop.export.writeOutputs(items, struct( ...
        'outputFolder', string(folder), ...
        'format', 'PNG', ...
        'cropWidth', 4, ...
        'cropHeight', 4, ...
        'paddingPercent', 0));

    outputPaths = string({payload.results.outputPath});
    assert(numel(unique(outputPaths)) == 2, ...
        'Duplicate-source crop tasks should write unique output files.');
    assert(endsWith(outputPaths(1), "shared_source_crop.png"), ...
        'First duplicate-source crop should use the base crop filename.');
    assert(endsWith(outputPaths(2), "shared_source_crop_001.png"), ...
        'Second duplicate-source crop should use a numbered crop filename.');
    assert(height(payload.manifest) == 2, ...
        'Manifest should keep one row per duplicate-source crop task.');
end

function cols = expectedManifestColumns()
    cols = {'SourceImage', 'OutputImage', 'Status', 'RotationDeg', ...
        'PaddingPercent', 'CenterX_px', 'CenterY_px', 'CropWidth_px', ...
        'CropHeight_px', 'SourceWidth_px', 'SourceHeight_px', 'Message'};
end

function names = fileNames(paths)
    names = cell(numel(paths), 1);
    for k = 1:numel(paths)
        [~, base, ext] = fileparts(char(paths(k)));
        names{k} = [base ext];
    end
end

function assertThrows(fcn, expectedId, message)
    try
        fcn();
    catch ME
        assert(strcmp(ME.identifier, expectedId), ...
            'Expected error %s, got %s.', expectedId, ME.identifier);
        return;
    end
    error(message);
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
