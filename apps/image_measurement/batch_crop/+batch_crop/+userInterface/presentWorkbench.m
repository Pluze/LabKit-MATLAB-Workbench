% Expected caller: the LabKit V2 runtime. Input is canonical Batch Crop
% state. Output is a deterministic control, summary, preview, and controlled
% interaction presentation without UI registry access.
function view = presentWorkbench(state)
    items = batch_crop.appState.workingItems( ...
        state.project.inputs.items, state.session.cache.images, ...
        state.project.inputs.sources);
    parameters = state.project.parameters;
    index = currentIndex(state);
    hasImage = hasCurrentImage(state);
    physicalMode = strcmpi(parameters.scaleMode, "Physical");
    cropSize = batch_crop.appState.currentCropSize(state);
    padding = currentPadding(state);

    view = struct();
    view.controls.images = imageListSpec(items, index, parameters.scaleMode);
    view.controls.imageSource = valueSpec(currentPath(items, index));
    view.controls.imageStatus = valueSpec(imageStatus(items, physicalMode));
    view.controls.duplicateImage = enabledSpec(hasImage);
    view.controls.previousImage = enabledSpec(hasImage && index > 1);
    view.controls.nextImage = enabledSpec(hasImage && index < numel(items));
    view.controls.rotation = controlSpec(hasImage, currentAngle(items, index));
    view.controls.paddingPercent = controlSpec(hasImage, padding);
    view.controls.centerX = coordinateSpec(hasImage, state, 1);
    view.controls.centerY = coordinateSpec(hasImage, state, 2);
    view.controls.useImageCenter = enabledSpec(hasImage);
    view.controls.useImageXCenter = enabledSpec(hasImage);
    view.controls.useImageYCenter = enabledSpec(hasImage);
    view.controls.cropWidth = sizeSpec(hasImage && ~physicalMode, ...
        parameters.cropWidth, cropLimit(items, index));
    view.controls.cropHeight = sizeSpec(hasImage && ~physicalMode, ...
        parameters.cropHeight, cropLimit(items, index));
    view.controls.scaleUnit = enabledSpec(physicalMode);
    view.controls.physicalWidth = enabledSpec(hasImage && physicalMode);
    view.controls.physicalHeight = enabledSpec(hasImage && physicalMode);
    view.controls.targetPixelsPerUnit = enabledSpec(hasImage && physicalMode);
    view.controls.maxUpsamplePercent = enabledSpec(hasImage && physicalMode);
    view.controls.outputFolder = valueSpec(parameters.outputFolder);
    view.controls.exportCrops = enabledSpec(hasImage);
    view.controls.scaleStatus = valueSpec(batch_crop.userInterface.scaleStatusText( ...
        state, index, parameters.scaleMode, ...
        [parameters.physicalWidth, parameters.physicalHeight], ...
        parameters.scaleUnit));
    view.controls.resultTable = struct();
    view.controls.resultTable.Data = ...
        batch_crop.userInterface.summaryTableData(state, index, ...
        cropSize(1), cropSize(2), padding, parameters.format);
    view.controls.details = valueSpec(batch_crop.userInterface.detailLines( ...
        state, index, cropSize(1), cropSize(2), padding));
    view = scaleControlPresentation(view, state, hasImage, physicalMode);

    model = emptyPreviewModel();
    if hasImage
        [geometry, render] = previewGeometry(state);
        item = items(index);
        model.imageData = render.imageData;
        model.xData = [1 size(geometry.canvas, 2)];
        model.yData = [1 size(geometry.canvas, 1)];
        model.center = batch_crop.cropGeometry.originalToCanvas( ...
            geometry, item.centerXY);
        model.cropRectangle = cropRectanglePosition( ...
            geometry, item.centerXY, cropSize);
        model.scaleBar = scaleBarOnCanvas(geometry, state.session.view.scaleBar);
        if state.session.workflow.scaleReferenceEditing
            view.interactions.scaleReference = scaleReferenceSpec(geometry, item);
        else
            view.interactions.cropCenter = cropCenterSpec( ...
                geometry, item.centerXY);
        end
    end
    view.previews.preview = struct("Renderer", "cropPreview", "Model", model);
end

function view = scaleControlPresentation(view, state, hasImage, physicalMode)
    editing = state.session.workflow.scaleReferenceEditing;
    cal = batch_crop.appState.emptyScaleCalibration(state.project.parameters.scaleUnit);
    if hasImage
        cal = state.project.inputs.items(currentIndex(state)).scaleCalibration;
    end
    referencePixels = cal.referencePixels;
    referenceReadout = "-";
    if isfinite(referencePixels)
        referenceReadout = sprintf('%.6g', referencePixels);
    else
        referencePixels = 0;
    end
    pixelsReadout = "-";
    if cal.pixelsPerUnit > 0
        pixelsReadout = sprintf('%.6g px/%s', cal.pixelsPerUnit, cal.unit);
    end
    inputsEnabled = hasImage && physicalMode && ~editing;
    view.controls.measureScaleReference = struct( ...
        "Enabled", hasImage && physicalMode, ...
        "Text", batch_crop.userInterface.ternary(editing, ...
        "Finish reference edit", "Measure reference pixels"));
    view.controls.scaleReferencePixels = controlSpec(inputsEnabled, referencePixels);
    view.controls.scaleReferenceLength = controlSpec( ...
        hasImage && physicalMode, cal.referenceLength);
    view.controls.scaleCalibrationUnit = controlSpec( ...
        hasImage && physicalMode, cal.unit);
    view.controls.scaleBarLength = enabledSpec(hasImage && physicalMode);
    view.controls.scaleBarPosition = enabledSpec(hasImage && physicalMode);
    view.controls.scaleBarColor = enabledSpec(hasImage && physicalMode);
    view.controls.placeScaleBar = enabledSpec(hasImage && physicalMode && ...
        cal.isCalibrated && ~editing);
    view.controls.scaleReferenceReadout = valueSpec(referenceReadout);
    view.controls.pixelsPerUnitReadout = valueSpec(pixelsReadout);
end

function spec = imageListSpec(items, index, mode)
    files = batch_crop.userInterface.filePanelEntries(items, mode);
    for k = 1:numel(files)
        files(k).id = "item" + string(k);
    end
    selection = strings(0, 1);
    if index >= 1 && index <= numel(items)
        selection = "item" + string(index);
    end
    spec = struct("Files", files, "Selection", selection, ...
        "Status", imageStatus(items, strcmpi(mode, "Physical")));
end

function value = imageStatus(items, physicalMode)
    if isempty(items)
        value = "No images loaded";
        return;
    end
    if physicalMode
        summary = batch_crop.appState.scaleCalibrationSummary(items);
        value = sprintf('Images: %d | centers: %d | scales: %d', ...
            numel(items), batch_crop.appState.countConfirmedCenters(items), ...
            summary.calibratedCount);
    else
        value = sprintf('Images: %d | confirmed centers: %d', ...
            numel(items), batch_crop.appState.countConfirmedCenters(items));
    end
end

function position = cropRectanglePosition(geometry, center, cropSize)
    scale = batch_crop.cropGeometry.geometryScale(geometry);
    width = max(1, double(cropSize(1)) * scale);
    height = max(1, double(cropSize(2)) * scale);
    canvasCenter = batch_crop.cropGeometry.originalToCanvas(geometry, center);
    position = [round(canvasCenter(1) - (width - 1) / 2) - 0.5, ...
        round(canvasCenter(2) - (height - 1) / 2) - 0.5, width, height];
end

function spec = cropCenterSpec(geometry, center)
    canvasCenter = batch_crop.cropGeometry.originalToCanvas(geometry, center);
    value = struct("points", canvasCenter, "selectedIndex", 1, ...
        "locked", false);
    spec = struct("Kind", "pointSlots", "Targets", "preview", ...
        "Value", value, "Event", "cropCenterEdited", ...
        "ImageSize", size(geometry.canvas), ...
        "ChangePolicy", "commit", ...
        "Options", struct("color", [0.05 0.45 0.95], ...
        "selectedColor", [1 0.9 0.15], ...
        "placeSelectedOnBackground", true));
end

function spec = scaleReferenceSpec(geometry, item)
    points = item.scaleCalibration.referenceLine;
    if ~isempty(points)
        for k = 1:size(points, 1)
            points(k, :) = batch_crop.cropGeometry.originalToCanvas( ...
                geometry, points(k, :));
        end
    end
    spec = struct("Kind", "scaleBarReference", "Targets", "preview", ...
        "Value", points, "Event", "scaleReferenceEdited", ...
        "ImageSize", size(geometry.canvas), ...
        "ChangePolicy", "commit", ...
        "Options", struct("color", [1 1 0]));
end

function [geometry, render] = previewGeometry(state)
    index = currentIndex(state);
    item = batch_crop.appState.workingItems( ...
        state.project.inputs.items(index), state.session.cache.images(index), ...
        state.project.inputs.sources);
    [geometry, ~] = batch_crop.appState.currentGeometry( ...
        state.session.cache.canvas, index, item, item.paddingPercent);
    placement = struct("offset", [0 0], ...
        "xData", [1 size(geometry.canvas, 2)], ...
        "yData", [1 size(geometry.canvas, 1)]);
    render = batch_crop.userInterface.previewRenderData(geometry, placement);
end

function value = scaleBarOnCanvas(geometry, scaleBar)
    value = scaleBar;
    if isempty(value)
        return;
    end
    for k = 1:size(value.line, 1)
        value.line(k, :) = batch_crop.cropGeometry.originalToCanvas( ...
            geometry, value.line(k, :));
    end
    value.labelPosition = batch_crop.cropGeometry.originalToCanvas( ...
        geometry, value.labelPosition);
end

function value = currentPadding(state)
    value = 0;
    if hasCurrentImage(state)
        value = state.project.inputs.items(currentIndex(state)).paddingPercent;
    end
end

function spec = coordinateSpec(enabled, state, dimension)
    value = 1;
    limits = [1 100000];
    if enabled
        item = state.project.inputs.items(currentIndex(state));
        value = item.centerXY(dimension);
        [geometry, ~] = previewGeometry(state);
        scale = batch_crop.cropGeometry.geometryScale(geometry);
        if dimension == 1
            limits = [1 - double(geometry.padding.left) / scale, ...
                double(geometry.sourceWidth) + double(geometry.padding.right) / scale];
        else
            limits = [1 - double(geometry.padding.top) / scale, ...
                double(geometry.sourceHeight) + double(geometry.padding.bottom) / scale];
        end
    end
    spec = struct("Enabled", enabled, "Value", value, "Limits", limits);
end

function value = cropLimit(items, index)
    value = 100000;
    if index >= 1 && index <= numel(items) && ~isempty(items(index).image)
        imageData = items(index).image;
        value = max(1, ceil(2 .* hypot(double(size(imageData, 2)), ...
            double(size(imageData, 1)))));
    end
end

function value = currentAngle(items, index)
    value = 0;
    if index >= 1 && index <= numel(items)
        value = items(index).angleDeg;
    end
end

function value = currentPath(items, index)
    value = "No images loaded";
    if index >= 1 && index <= numel(items)
        value = items(index).path;
    end
end

function spec = sizeSpec(enabled, value, upper)
    spec = struct("Enabled", enabled, "Value", value, ...
        "Limits", [1 upper]);
end

function spec = controlSpec(enabled, value)
    spec = struct("Enabled", enabled, "Value", value);
end

function spec = enabledSpec(enabled)
    spec = struct("Enabled", logical(enabled));
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function model = emptyPreviewModel()
    model = struct("imageData", [], "xData", [1 1], "yData", [1 1], ...
        "center", [1 1], "cropRectangle", [], "scaleBar", [], ...
        "title", "Padded rotation preview + fixed crop");
end

function index = currentIndex(state)
    index = state.session.selection.currentIndex;
end

function tf = hasCurrentImage(state)
    index = currentIndex(state);
    tf = ~isempty(state.project.inputs.items) && index >= 1 && ...
        index <= numel(state.project.inputs.items) && ...
        index <= numel(state.session.cache.images) && ...
        ~isempty(state.session.cache.images{index});
end
