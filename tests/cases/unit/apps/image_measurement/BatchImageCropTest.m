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
    checkReflectedPaddingPreservesSourceAndBlendsBoundary();
    checkPaddingFadesIntoReflectedTexture();
    checkPaddingDoesNotStretchDarkEdgePixels();
    checkPaddingAllowsLargeExtension();
    checkCoordinateTransformsRoundTripOriginalPoints();
    checkPreviewViewPreservesZoomAcrossPaddingRedraw();
    checkSourceCenterHelpersUseImageGeometry();
    checkPaddingDoesNotMoveCropCenterMetadata();
    checkRotatedCropKeepsRequestedSize();
    checkRotationBackgroundUsesWhiteFill();
    checkNewItemsDefaultToZeroPadding();
    checkReadItemsAcceptsFilePanelCellPaths();
    checkDuplicateItemCreatesIndependentCropTask();
    checkMergeChosenItemsPreservesDuplicateCropTasks();
    checkManifestContract();
    checkPerItemPaddingExportsIndependently();
    checkPhysicalScaleCropUsesUnifiedOutputPixels();
    checkPhysicalScaleUnitsAreConvertedWithoutMutatingCalibration();
    checkScalePlanWarnsButDoesNotBlockOutliers();
    checkMissingWorkflowPromptNamesAffectedFiles();
    checkFilePanelEntriesExposeWorkflowStatus();
    checkExportWritesUniqueOutputs();
    checkExportWritesUniqueOutputsForDuplicateSource();
    checkExportPlanFingerprintTracksItemsAndOptions();
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

function checkReflectedPaddingPreservesSourceAndBlendsBoundary()
    img = uint8(120 * ones(20, 20));
    img(:, 1) = 0;
    img(1, :) = 0;
    img(9:12, 9:12) = 200;
    [padded, padding] = batch_crop.ops.padImageEdges(img, 50);

    sourceBlock = padded((1:20) + padding.top, (1:20) + padding.left);
    assert(isequal(sourceBlock(9:12, 9:12), img(9:12, 9:12)), ...
        'Padding repair must not alter interior source-image pixels.');
    edgeValue = double(img(10, 1));
    insetValue = double(img(10, 2));
    firstPaddingValue = double(padded(padding.top + 10, padding.left));
    assert(abs(firstPaddingValue - insetValue) < abs(firstPaddingValue - edgeValue), ...
        'Padding should use inset edge texture instead of stretching the outermost edge pixel.');
end

function checkPaddingFadesIntoReflectedTexture()
    img = uint8(100 * ones(40, 40));
    img(:, 20:22) = 250;
    [padded, padding] = batch_crop.ops.padImageEdges(img, 50);

    leftPadding = double(padded(padding.top + 20, 1:padding.left));
    edgeValue = double(img(20, 1));
    reflectedTextureValue = double(img(20, 21));
    assert(abs(leftPadding(1) - reflectedTextureValue) < abs(leftPadding(1) - edgeValue), ...
        'Far padding should fade into reflected image texture.');
end

function checkPaddingDoesNotStretchDarkEdgePixels()
    img = uint8(180 * ones(20, 30));
    img(:, 1) = 0;
    [padded, padding] = batch_crop.ops.padImageEdges(img, 40);

    leftPadding = double(padded(padding.top + 10, 1:padding.left));
    sourceBlock = double(padded((1:20) + padding.top, (1:30) + padding.left));
    assert(sourceBlock(10, 1) > 120, ...
        'Border repair should replace dark outermost source-edge pixels with nearby texture.');
    assert(leftPadding(end) > 120, ...
        'The first padded pixel should use repaired edge texture.');
    assert(leftPadding(1) > 120, ...
        'Inset reflection should keep the far padding from becoming a stretched dark edge.');
    assert(~any(leftPadding < 60), ...
        'Dark edge pixels should not extend into the synthetic padding.');
end

function checkPaddingAllowsLargeExtension()
    img = uint8(ones(4, 5));
    [padded, padding] = batch_crop.ops.padImageEdges(img, 250);

    assert(padding.percent == 200, ...
        'Padding percent should clamp to the supported 200%% maximum.');
    assert(isequal(size(padded), [20 25]), ...
        '200%% padding should add two source widths/heights on each side.');
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

function checkPreviewViewPreservesZoomAcrossPaddingRedraw()
    img = uint8(zeros(20, 30));
    geometry = batch_crop.ops.prepareCropCanvas(img, struct( ...
        'angleDeg', 0, ...
        'paddingPercent', 40));
    placement = batch_crop.view.previewPlacement(geometry);
    fig = figure('Visible', 'off');
    cleanup = onCleanup(@() close(fig));
    ax = axes(fig);
    ax.XLim = [5, 12];
    ax.YLim = [4, 10];

    state = batch_crop.view.capturePreviewView(ax, geometry, placement);
    ax.XLim = placement.xData + [-0.5, 0.5];
    ax.YLim = placement.yData + [-0.5, 0.5];
    batch_crop.view.restorePreviewView(ax, state, geometry, placement);

    assert(abs(diff(ax.XLim) - state.xSpan) < 1e-9 && ...
        abs(diff(ax.YLim) - state.ySpan) < 1e-9, ...
        'Preview redraw should preserve zoom span after padding or center updates.');
    restoredCenter = batch_crop.ops.canvasToOriginal(geometry, ...
        [mean(ax.XLim), mean(ax.YLim)] - placement.offset);
    assert(max(abs(restoredCenter - state.centerOriginal)) < 1e-9, ...
        'Preview redraw should preserve the visible source-coordinate center.');
end

function checkSourceCenterHelpersUseImageGeometry()
    img = uint8(zeros(7, 9, 3));
    assert(isequal(batch_crop.ops.sourceCenterXY(img), [5, 4]), ...
        'Source center helper should return one-based [x y] image coordinates.');
    assert(isequal(batch_crop.ops.sourceCenterFromSize(10, 12), [5.5, 6.5]), ...
        'Source size helper should preserve half-pixel centers for even image sizes.');
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

function checkNewItemsDefaultToZeroPadding()
    item = batch_crop.state.emptyItem();
    assert(item.paddingPercent == 0 && batch_crop.state.itemPaddingPercent(item) == 0, ...
        'New batch-crop items should default to no repaired padding.');
end

function checkReadItemsAcceptsFilePanelCellPaths()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = fullfile(folder, 'frame_a.png');
    imwrite(uint8(42 * ones(6, 7)), sourcePath);

    items = batch_crop.state.readItems({sourcePath});
    assert(numel(items) == 1, ...
        'Batch crop reader should accept filePanel cell-array paths.');
    assert(items(1).path == string(sourcePath), ...
        'Batch crop reader should preserve the selected source path.');
    assert(isequal(size(items(1).image), [6 7]), ...
        'Batch crop reader should load image data from filePanel paths.');
end

function checkDuplicateItemCreatesIndependentCropTask()
    item = batch_crop.state.emptyItem();
    item.path = "source.png";
    item.image = uint8(ones(5, 6));
    item.angleDeg = 12;
    item.centerXY = [3, 4];
    item.centerSet = true;
    item.paddingPercent = 25;
    item.scaleCalibration = labkit.ui.tool.scaleBarCalibration(80, 20, "um", ...
        struct('defaultUnit', 'um'));

    duplicated = batch_crop.state.duplicateItem(item);
    assert(duplicated.path == item.path, ...
        'Duplicated crop task should preserve the source image path.');
    assert(isequal(duplicated.image, item.image), ...
        'Duplicated crop task should reuse the loaded image data.');
    assert(duplicated.angleDeg == item.angleDeg, ...
        'Duplicated crop task should preserve rotation.');
    assert(~duplicated.centerSet && all(isnan(duplicated.centerXY)), ...
        'Duplicated crop task should require a new crop center.');
    duplicated.paddingPercent = 50;
    assert(item.paddingPercent == 25 && duplicated.paddingPercent == 50, ...
        'Duplicated crop tasks should keep independent padding settings after creation.');
    assert(duplicated.scaleCalibration.isCalibrated && ...
        duplicated.scaleCalibration.pixelsPerUnit == item.scaleCalibration.pixelsPerUnit, ...
        'Duplicated crop task should preserve source-image scale calibration.');
end

function checkMergeChosenItemsPreservesDuplicateCropTasks()
    itemA = physicalItem("source_a.png", uint8(40 * ones(10, 12)), 4);
    itemA.centerXY = [3, 4];
    duplicateA = batch_crop.state.duplicateItem(itemA);
    duplicateA.centerXY = [8, 7];
    duplicateA.centerSet = true;
    duplicateA.scaleCalibration = labkit.ui.tool.scaleBarCalibration(80, 10, "um", ...
        struct('defaultUnit', 'um', 'referenceLine', [1 1; 81 1]));

    loadedA = batch_crop.state.emptyItem();
    loadedA.path = "source_a.png";
    loadedA.image = uint8(90 * ones(10, 12));
    loadedB = batch_crop.state.emptyItem();
    loadedB.path = "source_b.png";
    loadedB.image = uint8(120 * ones(8, 9));

    merged = batch_crop.state.mergeChosenItems([itemA; duplicateA], [loadedA; loadedB]);
    assert(numel(merged) == 3, ...
        'Choosing additional files should preserve duplicate crop tasks and append new images.');
    assert(all([merged(1:2).path] == "source_a.png") && merged(3).path == "source_b.png", ...
        'Merged crop tasks should keep existing duplicate-source tasks before new source items.');
    assert(isequal(merged(1).centerXY, itemA.centerXY) && isequal(merged(2).centerXY, duplicateA.centerXY), ...
        'Merged crop tasks should preserve each duplicate task crop center.');
    assert(merged(1).scaleCalibration.pixelsPerUnit == 4 && ...
        merged(2).scaleCalibration.pixelsPerUnit == 8, ...
        'Merged duplicate crop tasks should keep independent per-task scale calibrations.');
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
    assert(strcmp(T.ScaleMode(1), "Pixels") && T.OutputWidth_px(1) == 3 && T.OutputHeight_px(1) == 4, ...
        'Pixel-mode manifest scale columns should preserve identity output metadata.');
end

function checkPerItemPaddingExportsIndependently()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    itemA = batch_crop.state.emptyItem();
    itemA.path = string(fullfile(folder, 'pad_a.png'));
    itemA.image = uint8(40 * ones(8, 8));
    itemA.centerXY = [4, 4];
    itemA.centerSet = true;
    itemA.paddingPercent = 0;
    itemB = itemA;
    itemB.path = string(fullfile(folder, 'pad_b.png'));
    itemB.paddingPercent = 40;

    payload = batch_crop.export.writeOutputs([itemA; itemB], struct( ...
        'outputFolder', string(folder), ...
        'format', 'PNG', ...
        'cropWidth', 6, ...
        'cropHeight', 6, ...
        'paddingPercent', 0));

    assert(payload.results(1).paddingPercent == 0 && ...
        payload.results(2).paddingPercent == 40, ...
        'Batch export should use each item padding instead of one global padding value.');
    assert(isequal(payload.manifest.PaddingPercent, [0; 40]), ...
        'Manifest should record per-item padding percentages.');
end

function checkPhysicalScaleCropUsesUnifiedOutputPixels()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    itemA = physicalItem(fullfile(folder, 'source_a.png'), uint8(80 * ones(120, 120)), 4);
    itemB = physicalItem(fullfile(folder, 'source_b.png'), uint8(160 * ones(160, 160)), 8);

    payload = batch_crop.export.writeOutputs([itemA; itemB], struct( ...
        'outputFolder', string(folder), ...
        'format', 'PNG', ...
        'cropWidth', 10, ...
        'cropHeight', 10, ...
        'paddingPercent', 0, ...
        'scaleMode', 'Physical', ...
        'physicalWidth', 10, ...
        'physicalHeight', 5, ...
        'scaleUnit', 'um', ...
        'targetPixelsPerUnit', 0, ...
        'maxUpsamplePercent', 15));

    exportedA = imread(payload.results(1).outputPath);
    exportedB = imread(payload.results(2).outputPath);
    assert(isequal(size(exportedA), [30 60]) && isequal(size(exportedB), [30 60]), ...
        'Physical scale mode should export a unified output pixel size.');
    assert(payload.results(1).nativeCropWidth == 40 && payload.results(1).nativeCropHeight == 20, ...
        'Physical export should crop the first image at its native calibrated pixel size.');
    assert(payload.results(2).nativeCropWidth == 80 && payload.results(2).nativeCropHeight == 40, ...
        'Physical export should crop the second image at its native calibrated pixel size.');
    assert(payload.results(1).targetPixelsPerUnit == 6 && payload.results(2).targetPixelsPerUnit == 6, ...
        'Auto target pixels/unit should use the representative calibrated density.');
    assert(contains(payload.results(1).scaleWarning, "upsample") && ...
        strlength(payload.results(2).scaleWarning) == 0, ...
        'Physical export should warn on large upsampling while still saving outputs.');
    assert(height(payload.manifest) == 2 && all(payload.manifest.OutputWidth_px == 60) && ...
        all(payload.manifest.OutputHeight_px == 30), ...
        'Physical export manifest should record unified output dimensions.');
end

function checkPhysicalScaleUnitsAreConvertedWithoutMutatingCalibration()
    item = physicalItem("source_mm.png", uint8(80 * ones(120, 120)), 4);
    item.scaleCalibration = labkit.ui.tool.scaleBarCalibration(40, 10, "mm", ...
        struct('defaultUnit', 'mm', 'referenceLine', [1 1; 41 1]));

    plan = batch_crop.ops.scalePlan(item, struct( ...
        'physicalWidth', 1000, ...
        'physicalHeight', 500, ...
        'scaleUnit', 'um', ...
        'targetPixelsPerUnit', 0, ...
        'maxUpsamplePercent', 15));

    assert(strcmp(item.scaleCalibration.unit, 'mm'), ...
        'Planning a crop in um should not mutate the per-image calibration unit.');
    assert(plan.nativeCropWidth == 4 && plan.nativeCropHeight == 2, ...
        'Physical crop dimensions should convert requested units to the calibration density.');
    assert(plan.outputWidth == 4 && plan.outputHeight == 2, ...
        'Auto target density should use converted px/requested-unit values.');

    pixelsPerMm = batch_crop.ops.pixelsPerUnitForUnit(item.scaleCalibration, "mm");
    pixelsPerUm = batch_crop.ops.pixelsPerUnitForUnit(item.scaleCalibration, "um");
    assert(pixelsPerMm == 4 && abs(pixelsPerUm - 0.004) < 1e-12, ...
        'Calibration density conversion should preserve independent source and crop units.');
end

function checkScalePlanWarnsButDoesNotBlockOutliers()
    itemA = physicalItem("a.png", uint8(ones(20, 20)), 5);
    itemB = physicalItem("b.png", uint8(ones(80, 80)), 20);

    plan = batch_crop.ops.scalePlan([itemA; itemB], struct( ...
        'physicalWidth', 2, ...
        'physicalHeight', 3, ...
        'scaleUnit', 'um', ...
        'targetPixelsPerUnit', 20, ...
        'maxUpsamplePercent', 10));

    assert(plan.outputWidth == 40 && plan.outputHeight == 60, ...
        'Manual target pixels/unit should define the common physical output size.');
    assert(contains(plan.warnings(1), "upsample") && strlength(plan.warnings(2)) == 0, ...
        'Scale planning should label large resampling differences without rejecting the plan.');
end

function checkMissingWorkflowPromptNamesAffectedFiles()
    items = [physicalItem("ready.png", uint8(ones(10, 10)), 4); ...
        physicalItem("needs_center.png", uint8(ones(10, 10)), 4); ...
        physicalItem("needs_scale.png", uint8(ones(10, 10)), 4)];
    items(2).centerSet = false;
    items(2).centerXY = [NaN, NaN];
    items(3).scaleCalibration = batch_crop.state.emptyScaleCalibration("um");

    centerText = batch_crop.view.missingWorkflowItemsText(items, "center");
    scaleText = batch_crop.view.missingWorkflowItemsText(items, "scale");

    assert(contains(centerText, "needs_center.png") && ~contains(centerText, "ready.png"), ...
        'Missing-center prompt should name only items without confirmed centers.');
    assert(contains(scaleText, "needs_scale.png") && ~contains(scaleText, "ready.png"), ...
        'Missing-scale prompt should name only items without scale calibration.');
end

function checkFilePanelEntriesExposeWorkflowStatus()
    items = [physicalItem("ready.png", uint8(ones(10, 10)), 4); ...
        physicalItem("needs_center.png", uint8(ones(10, 10)), 4); ...
        physicalItem("needs_scale.png", uint8(ones(10, 10)), 4)];
    items(2).centerSet = false;
    items(2).centerXY = [NaN, NaN];
    items(3).scaleCalibration = batch_crop.state.emptyScaleCalibration("um");

    pixelEntries = batch_crop.view.filePanelEntries(items, "Pixels");
    physicalEntries = batch_crop.view.filePanelEntries(items, "Physical");

    assert(isequal(string({pixelEntries.status}).', ...
        ["ready"; "needs center"; "ready"]), ...
        'Pixel-mode file list should mark missing centers and ready items.');
    assert(isequal(string({physicalEntries.status}).', ...
        ["ready"; "needs center"; "needs scale"]), ...
        'Physical-mode file list should mark files that still need scale calibration.');
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

function checkExportPlanFingerprintTracksItemsAndOptions()
    item = batch_crop.state.emptyItem();
    item.path = "shared_source.png";
    item.image = uint8(20 * ones(8, 8));
    item.angleDeg = 0;
    item.centerXY = [3, 3];
    item.centerSet = true;
    opts = struct( ...
        'outputFolder', "out_a", ...
        'format', 'PNG', ...
        'cropWidth', 4, ...
        'cropHeight', 4, ...
        'paddingPercent', 0, ...
        'scaleMode', 'Pixels');

    base = batch_crop.state.exportPlan(item, opts);
    repeated = batch_crop.state.exportPlan(item, opts);
    moved = opts;
    moved.outputFolder = "out_b";
    movedPlan = batch_crop.state.exportPlan(item, moved);
    shifted = item;
    shifted.centerXY = [5, 5];
    shiftedPlan = batch_crop.state.exportPlan(shifted, opts);
    padded = item;
    padded.paddingPercent = 40;
    paddedPlan = batch_crop.state.exportPlan(padded, opts);

    assert(base.fingerprint == repeated.fingerprint, ...
        'Identical batch-crop export plans should have stable fingerprints.');
    assert(base.fingerprint ~= movedPlan.fingerprint, ...
        'Changing the crop output folder should change the plan fingerprint.');
    assert(base.fingerprint ~= shiftedPlan.fingerprint, ...
        'Changing a crop center should change the plan fingerprint.');
    assert(base.fingerprint ~= paddedPlan.fingerprint, ...
        'Changing one item padding should change the plan fingerprint.');
end

function cols = expectedManifestColumns()
    cols = {'SourceImage', 'OutputImage', 'Status', 'RotationDeg', ...
        'PaddingPercent', 'CenterX_px', 'CenterY_px', 'CropWidth_px', ...
        'CropHeight_px', 'SourceWidth_px', 'SourceHeight_px', 'ScaleMode', ...
        'ScaleUnit', 'SourcePixelsPerUnit', 'TargetPixelsPerUnit', ...
        'ResampleFactor', 'NativeCropWidth_px', 'NativeCropHeight_px', ...
        'OutputWidth_px', 'OutputHeight_px', 'ScaleWarning', 'Message'};
end

function item = physicalItem(pathValue, imageData, pixelsPerUnit)
    item = batch_crop.state.emptyItem();
    item.path = string(pathValue);
    item.image = imageData;
    item.angleDeg = 0;
    item.centerXY = [(size(imageData, 2) + 1) / 2, (size(imageData, 1) + 1) / 2];
    item.centerSet = true;
    item.scaleCalibration = labkit.ui.tool.scaleBarCalibration(pixelsPerUnit, 1, "um", ...
        struct('defaultUnit', 'um', 'referenceLine', [1 1; 1 + pixelsPerUnit, 1]));
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
