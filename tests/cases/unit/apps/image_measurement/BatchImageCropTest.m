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
    checkCropCenterAvoidsInvalidRotatedMaskRegions();
    checkReflectedPaddingPreservesSourceAndBlendsBoundary();
    checkPaddingFadesIntoReflectedTexture();
    checkPaddingDoesNotStretchDarkEdgePixels();
    checkPaddingAllowsLargeExtension();
    checkCropCenterShiftsMinimallyToCanvasBounds();
    checkCoordinateTransformsRoundTripOriginalPoints();
    checkPreviewGeometryDownsamplesBeforeRotationAndKeepsOriginalCoordinates();
    checkPreviewViewPreservesZoomAcrossPaddingRedraw();
    checkPreviewViewPreservesOriginalRoiAcrossPreviewScaleChanges();
    checkPreviewRenderDataDownsamplesWithoutChangingCoordinates();
    checkSourceCenterHelpersUseImageGeometry();
    checkPaddingKeepsShiftedCropOnValidRotatedMask();
    checkRotatedCropKeepsRequestedSize();
    checkRotationBackgroundUsesWhiteFill();
    checkNewItemsDefaultToZeroPadding();
    checkTasksForSourceIdsExcludeImagePixels();
    checkReadItemsAcceptsFilePanelCellPaths();
    checkDuplicateItemCreatesIndependentCropTask();
    checkV2ProjectPresentationAndScaleBarGeometry();
end

function checkV2ProjectPresentationAndScaleBarGeometry()
    definition = batch_crop.definition();
    assert(definition.contractVersion == 2, ...
        'Batch crop definition should use the V2 runtime contract.');
    project = definition.project.Create();
    assert(definition.project.Version == 2 && ...
        isa(definition.project.Migrate, 'function_handle'), ...
        'Batch crop should migrate v1 pixel-owning projects to v2 tasks.');
    assert(definition.project.Validate(project), ...
        'Fresh batch crop projects should satisfy the app validator.');
    item = batch_crop.sourceFiles.emptyItem();
    item.path = "synthetic.png";
    item.image = uint8(reshape(1:120, 10, 12));
    item.centerXY = [6.5 5.5];
    item.centerSet = true;
    item.scaleCalibration = labkit.ui.interaction.scaleBarCalibration( ...
        40, 10, "um", struct('defaultUnit', 'um', ...
        'referenceLine', [2 2; 42 2]));
    legacyProject = project;
    legacyProject.inputs.items = item;
    migrated = definition.project.Migrate(legacyProject, 1);
    assert(~isfield(migrated.inputs.items, 'image') && ...
        ~isfield(migrated.inputs.items, 'path') && ...
        migrated.inputs.items.sourceId == "image1" && ...
        labkit.ui.runtime.sourcePaths( ...
            migrated.inputs.sources(1)) == "synthetic.png", ...
        'The v1 migration should replace embedded pixels and paths with a source id.');
    task = rmfield(item, {'path', 'image'});
    task.sourceId = "image1";
    project.inputs.sources = labkit.ui.runtime.sourceRecord( ...
        "image1", "cropSource", "synthetic.png", true);
    project.inputs.items = orderfields( ...
        task, batch_crop.cropTasks.emptyTask());
    session = definition.createSession(definition.project.Create());
    session.selection.currentIndex = 1;
    session.cache.images{1} = item.image;
    state = struct("project", project, "session", session);
    view = definition.present(state);
    assert(isfield(view, 'interactions') && ...
        isfield(view.interactions, 'cropCenter') && ...
        view.interactions.cropCenter.Kind == "pointSlots" && ...
        view.interactions.cropCenter.Event == "cropCenterEdited" && ...
        view.interactions.cropCenter.Options.placeSelectedOnBackground, ...
        'Batch crop should use a draggable center with one-click placement.');
    assert(~contains(evalc('disp(state)'), 'matlab.ui'), ...
        'Batch crop canonical state should contain no live UI handles.');
    geometry = labkit.ui.interaction.scaleBarGeometry( ...
        size(item.image), item.scaleCalibration, 0.1, "Bottom center", "White");
    assert(size(geometry.line, 1) == 2 && ...
        isequal(geometry.color, [1 1 1]) && geometry.barLength == 0.1, ...
        'Scale-bar geometry should be deterministic and serializable.');
end

function checkCropCenterAvoidsInvalidRotatedMaskRegions()
    img = uint8(ones(6, 8));
    geometry = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 0, ...
        'paddingPercent', 0));
    geometry.mask = false(size(geometry.mask));
    geometry.mask(2:5, 3:7) = true;

    centerXY = batch_crop.cropGeometry.clampCropCenterToCanvas(geometry, [1 1], [3 2]);

    assert(isequal(centerXY, [4 2.5]), ...
        'Center adjustment should keep the complete ROI inside the valid image mask, not just the canvas.');
end

function checkCropCenterShiftsMinimallyToCanvasBounds()
    img = uint8(ones(8, 10));
    geometry = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 0, ...
        'paddingPercent', 0));
    centerXY = batch_crop.cropGeometry.clampCropCenterToCanvas(geometry, [9 2], [6 4]);

    assert(isequal(centerXY, [7.5 2.5]), ...
        'Center adjustment should use the smallest x/y shift that keeps the crop on the canvas.');
end

function checkFixedPixelCropPreservesClassAndSize()
    img = uint8(reshape(1:100, 10, 10));
    result = batch_crop.cropGeometry.cropImage(img, struct( ...
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
    result = batch_crop.cropGeometry.cropImage(img, struct( ...
        'cropWidth', 4, ...
        'cropHeight', 4, ...
        'centerXY', [1, 1], ...
        'angleDeg', 0, ...
        'paddingPercent', 0));

    assert(isequal(size(result.image), [4 4]), ...
        'Out-of-bounds crops should still use the requested output size.');
    assert(all(result.image == 10, "all"), ...
        'Out-of-bounds crop centers should shift minimally so the ROI stays on the image.');
    assert(result.centerX == 2.5 && result.centerY == 2.5, ...
        'Crop metadata should expose the minimally shifted center.');
end

function checkReflectedPaddingPreservesSourceAndBlendsBoundary()
    img = uint8(120 * ones(20, 20));
    img(:, 1) = 0;
    img(1, :) = 0;
    img(9:12, 9:12) = 200;
    [padded, padding] = batch_crop.cropGeometry.padImageEdges(img, 50);

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
    [padded, padding] = batch_crop.cropGeometry.padImageEdges(img, 50);

    leftPadding = double(padded(padding.top + 20, 1:padding.left));
    edgeValue = double(img(20, 1));
    reflectedTextureValue = double(img(20, 21));
    assert(abs(leftPadding(1) - reflectedTextureValue) < abs(leftPadding(1) - edgeValue), ...
        'Far padding should fade into reflected image texture.');
end

function checkPaddingDoesNotStretchDarkEdgePixels()
    img = uint8(180 * ones(20, 30));
    img(:, 1) = 0;
    [padded, padding] = batch_crop.cropGeometry.padImageEdges(img, 40);

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
    [padded, padding] = batch_crop.cropGeometry.padImageEdges(img, 250);

    assert(padding.percent == 200, ...
        'Padding percent should clamp to the supported 200%% maximum.');
    assert(isequal(size(padded), [20 25]), ...
        '200%% padding should add two source widths/heights on each side.');
end

function checkCoordinateTransformsRoundTripOriginalPoints()
    img = uint8(zeros(6, 8));
    geometry = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 27, ...
        'paddingPercent', 25));
    originalXY = [2.75, 4.25];

    canvasXY = batch_crop.cropGeometry.originalToCanvas(geometry, originalXY);
    recoveredXY = batch_crop.cropGeometry.canvasToOriginal(geometry, canvasXY);

    assert(max(abs(recoveredXY - originalXY)) < 1e-9, ...
        'Canvas/original coordinate transforms should preserve source coordinates.');
end

function checkPreviewGeometryDownsamplesBeforeRotationAndKeepsOriginalCoordinates()
    img = uint8(zeros(120, 160, 3));
    geometry = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 35, ...
        'paddingPercent', 200, ...
        'maxCanvasPixels', 4000));
    assert(geometry.coordinateScale < 1, ...
        'Large padded preview canvases should downsample before padding and rotation.');
    assert(size(geometry.canvas, 1) * size(geometry.canvas, 2) < ...
        5 * size(img, 1) * size(img, 2), ...
        'Preview geometry should avoid constructing the full padded high-resolution canvas.');

    originalXY = [73.25, 44.75];
    recoveredXY = batch_crop.cropGeometry.canvasToOriginal(geometry, ...
        batch_crop.cropGeometry.originalToCanvas(geometry, originalXY));
    assert(max(abs(recoveredXY - originalXY)) < 1e-9, ...
        'Preview geometry coordinate transforms should still report original-image coordinates.');
end

function checkPreviewViewPreservesZoomAcrossPaddingRedraw()
    img = uint8(zeros(20, 30));
    geometry = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 0, ...
        'paddingPercent', 40));
    placement = batch_crop.userInterface.previewPlacement(geometry);
    fig = figure('Visible', 'off');
    cleanup = onCleanup(@() close(fig));
    ax = axes(fig);
    ax.XLim = [5, 12];
    ax.YLim = [4, 10];

    state = batch_crop.userInterface.capturePreviewView(ax, geometry, placement);
    ax.XLim = placement.xData + [-0.5, 0.5];
    ax.YLim = placement.yData + [-0.5, 0.5];
    batch_crop.userInterface.restorePreviewView(ax, state, geometry, placement);

    assert(abs(diff(ax.XLim) - state.xSpan) < 1e-9 && ...
        abs(diff(ax.YLim) - state.ySpan) < 1e-9, ...
        'Preview redraw should preserve zoom span after padding or center updates.');
    restoredCenter = batch_crop.cropGeometry.canvasToOriginal(geometry, ...
        [mean(ax.XLim), mean(ax.YLim)] - placement.offset);
    assert(max(abs(restoredCenter - state.centerOriginal)) < 1e-9, ...
        'Preview redraw should preserve the visible source-coordinate center.');
end

function checkPreviewViewPreservesOriginalRoiAcrossPreviewScaleChanges()
    img = uint8(zeros(120, 160));
    geometryA = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 0, ...
        'paddingPercent', 20));
    placementA = batch_crop.userInterface.previewPlacement(geometryA);
    geometryB = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 0, ...
        'paddingPercent', 200, ...
        'maxCanvasPixels', 5000));
    placementB = batch_crop.userInterface.previewPlacement(geometryB);
    assert(geometryB.coordinateScale < geometryA.coordinateScale, ...
        'Test setup should force a changed preview coordinate scale.');

    fig = figure('Visible', 'off');
    cleanup = onCleanup(@() close(fig));
    ax = axes(fig);
    ax.XLim = [30, 70];
    ax.YLim = [25, 65];

    state = batch_crop.userInterface.capturePreviewView(ax, geometryA, placementA);
    batch_crop.userInterface.restorePreviewView(ax, state, geometryB, placementB);
    restored = restoredOriginalLimits(ax, geometryB, placementB);

    assert(max(abs(restored.x - state.originalXLim)) < 1e-9 && ...
        max(abs(restored.y - state.originalYLim)) < 1e-9, ...
        'Preview redraw should preserve the same original-image ROI when preview scale changes.');
end

function checkPreviewRenderDataDownsamplesWithoutChangingCoordinates()
    img = uint8(zeros(30, 40, 3));
    geometry = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 0, ...
        'paddingPercent', 0));
    placement = batch_crop.userInterface.previewPlacement(geometry);
    render = batch_crop.userInterface.previewRenderData(geometry, placement, ...
        struct('MaxPreviewPixels', 200));

    assert(render.scaleFactor > 1, ...
        'Large preview canvases should be downsampled for display.');
    assert(size(render.imageData, 1) < size(geometry.canvas, 1) && ...
        size(render.imageData, 2) < size(geometry.canvas, 2), ...
        'Preview CData should have fewer displayed pixels after downsampling.');
    assert(isequal(render.xData, placement.xData) && ...
        isequal(render.yData, placement.yData), ...
        'Preview downsampling must preserve full-resolution canvas coordinates.');
end

function limits = restoredOriginalLimits(ax, geometry, placement)
    xCanvas = ax.XLim - placement.offset(1);
    yCanvas = ax.YLim - placement.offset(2);
    leftTop = batch_crop.cropGeometry.canvasToOriginal(geometry, [xCanvas(1), yCanvas(1)]);
    rightBottom = batch_crop.cropGeometry.canvasToOriginal(geometry, [xCanvas(2), yCanvas(2)]);
    limits = struct( ...
        'x', sort([leftTop(1), rightBottom(1)]), ...
        'y', sort([leftTop(2), rightBottom(2)]));
end

function checkSourceCenterHelpersUseImageGeometry()
    img = uint8(zeros(7, 9, 3));
    assert(isequal(batch_crop.cropGeometry.sourceCenterXY(img), [5, 4]), ...
        'Source center helper should return one-based [x y] image coordinates.');
    assert(isequal(batch_crop.cropGeometry.sourceCenterFromSize(10, 12), [5.5, 6.5]), ...
        'Source size helper should preserve half-pixel centers for even image sizes.');
end

function checkPaddingKeepsShiftedCropOnValidRotatedMask()
    img = uint8(zeros(7, 9));
    result = batch_crop.cropGeometry.cropImage(img, struct( ...
        'cropWidth', 3, ...
        'cropHeight', 3, ...
        'centerXY', [2, 5], ...
        'angleDeg', 33, ...
        'paddingPercent', 40));

    assert(max(abs([result.centerX, result.centerY] - [1.9393, 4.7952])) < 1e-4, ...
        'Crop result metadata should expose the minimally shifted valid-mask center.');
    assert(max(result.image(:)) == 0, ...
        'A mask-adjusted rotated crop should avoid white outside-canvas fill when possible.');
    assert(result.sourceWidth == 9 && result.sourceHeight == 7, ...
        'Crop result metadata should expose source dimensions, not padded canvas size.');
    assert(result.paddingPercent == 40, ...
        'Crop result metadata should preserve the selected padding percent.');
end

function checkRotatedCropKeepsRequestedSize()
    img = uint8(zeros(8, 12, 3));
    img(:, 4:8, 1) = 200;
    result = batch_crop.cropGeometry.cropImage(img, struct( ...
        'cropWidth', 6, ...
        'cropHeight', 5, ...
        'angleDeg', 35, ...
        'paddingPercent', 15));
    geometry = batch_crop.cropGeometry.prepareCropCanvas(img, struct( ...
        'angleDeg', 35, ...
        'paddingPercent', 15));

    assert(isequal(size(result.image), [5 6 3]), ...
        'Rotated crop output size should remain fixed.');
    assert(size(geometry.canvas, 2) > size(img, 2) || size(geometry.canvas, 1) > size(img, 1), ...
        'Padded loose rotation should expand the internal preview canvas.');
end

function checkRotationBackgroundUsesWhiteFill()
    img = uint8(zeros(5, 5));
    result = batch_crop.cropGeometry.cropImage(img, struct( ...
        'cropWidth', 9, ...
        'cropHeight', 9, ...
        'centerXY', [3, 3], ...
        'angleDeg', 45, ...
        'paddingPercent', 0));

    assert(max(result.image(:)) == intmax('uint8'), ...
        'Rotation and crop regions outside the source canvas should use white background fill.');
end

function checkNewItemsDefaultToZeroPadding()
    item = batch_crop.sourceFiles.emptyItem();
    assert(item.paddingPercent == 0 && ...
        batch_crop.cropGeometry.itemPaddingPercent(item) == 0, ...
        'New batch-crop items should default to no repaired padding.');
end

function checkTasksForSourceIdsExcludeImagePixels()
    items = batch_crop.cropTasks.forSourceIds("image1");

    assert(numel(items) == 1, ...
        'Batch crop path items should preserve one task per selected file.');
    assert(items(1).sourceId == "image1", ...
        'Batch crop tasks should reference their source record by stable id.');
    assert(~isfield(items, 'image') && ~isfield(items, 'path'), ...
        'Durable crop tasks should not duplicate source paths or decoded pixels.');
    assert(~items(1).centerSet && all(isnan(items(1).centerXY)), ...
        'Deferred batch crop items should still require explicit crop-center confirmation.');
end

function checkReadItemsAcceptsFilePanelCellPaths()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = fullfile(folder, 'frame_a.png');
    imwrite(uint8(42 * ones(6, 7)), sourcePath);

    items = batch_crop.sourceFiles.readItems({sourcePath});
    assert(numel(items) == 1, ...
        'Batch crop reader should accept filePanel cell-array paths.');
    assert(items(1).path == string(sourcePath), ...
        'Batch crop reader should preserve the selected source path.');
    assert(isequal(size(items(1).image), [6 7]), ...
        'Batch crop reader should load image data from filePanel paths.');
end

function checkDuplicateItemCreatesIndependentCropTask()
    item = batch_crop.sourceFiles.emptyItem();
    item.path = "source.png";
    item.image = uint8(ones(5, 6));
    item.angleDeg = 12;
    item.centerXY = [3, 4];
    item.centerSet = true;
    item.paddingPercent = 25;
    item.scaleCalibration = labkit.ui.interaction.scaleBarCalibration(80, 20, "um", ...
        struct('defaultUnit', 'um'));

    duplicated = batch_crop.cropTasks.duplicateItem(item);
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

function item = physicalItem(pathValue, imageData, pixelsPerUnit)
    item = batch_crop.sourceFiles.emptyItem();
    item.path = string(pathValue);
    item.image = imageData;
    item.angleDeg = 0;
    item.centerXY = [(size(imageData, 2) + 1) / 2, (size(imageData, 1) + 1) / 2];
    item.centerSet = true;
    item.scaleCalibration = labkit.ui.interaction.scaleBarCalibration(pixelsPerUnit, 1, "um", ...
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
