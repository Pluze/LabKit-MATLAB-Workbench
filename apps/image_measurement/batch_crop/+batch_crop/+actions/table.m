% App-owned action table for Batch Image Crop. Expected caller is
% batch_crop.definition. Output maps semantic action ids to handlers used by
% labkit.ui.app.run. Handlers own file queue changes, crop state, scale
% calibration, and export side effects.
function actions = table()
    actions = struct( ...
        "startup", @onStartup, ...
        "imagesChosen", @onImagesChosen, ...
        "removeImages", @onRemoveImages, ...
        "clearImages", @onClearImages, ...
        "duplicateImage", @onDuplicateImage, ...
        "imageSelectionChanged", @onImageSelectionChanged, ...
        "previousImage", @onPreviousImage, ...
        "nextImage", @onNextImage, ...
        "cropGeometryChanged", @onCropGeometryChanged, ...
        "rotationChanged", @onRotationChanged, ...
        "paddingChanged", @onPaddingChanged, ...
        "centerChanged", @onCenterChanged, ...
        "useImageCenter", @onUseImageCenterXY, ...
        "useImageXCenter", @onUseImageCenterX, ...
        "useImageYCenter", @onUseImageCenterY, ...
        "scaleSettingChanged", @onScaleSettingChanged, ...
        "scaleCalibrationChanged", @onScaleCalibrationChanged, ...
        "scaleReferenceEditChanged", @onScaleReferenceEditChanged, ...
        "exportSettingChanged", @onExportSettingChanged, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "previewPointerDown", @onPreviewPointerDown, ...
        "exportCrops", @onExportCrops);
end

function state = onStartup(state, ~, services)
    ui = services.ui;
    fig = services.figure;
    debugLog = services.debug;
    previewAxes = ui.controls.preview.primaryAxes;
    imageRuntime = labkit.ui.tool.createRuntime(previewAxes, ...
        struct('figure', fig, 'onTrace', traceFcn(debugLog)));
    cropSession = imageRuntime.createSession(struct( ...
        'name', 'batchCropCenter', ...
        'onPointerDown', @(~, ~) services.dispatch("previewPointerDown"), ...
        'installScrollWheel', false));
    scaleTool = labkit.ui.tool.scaleBar(ui.controls.scaleBarHost.grid, 1, ...
        imageRuntime, struct( ...
        'title', 'Current Image Scale', ...
        'defaultUnit', 'um', ...
        'defaultReferenceLength', 100, ...
        'onCalibrationChanged', @(~, ~) services.dispatch("scaleCalibrationChanged"), ...
        'onReferenceEditChanged', @(~, ~) services.dispatch("scaleReferenceEditChanged"), ...
        'onError', @(titleText, message) showError(services, titleText, message), ...
        'onTrace', traceFcn(debugLog)));
    state.tools = struct('previewAxes', previewAxes, ...
        'imageRuntime', imageRuntime, ...
        'cropSession', cropSession, ...
        'scaleTool', scaleTool);
    if strlength(state.outputFolder) == 0
        state.outputFolder = string(labkit.ui.app.defaultDialogFolder("output"));
    end

    if isDebugEnabled(debugLog)
        debugLog.trace('Batch image crop debug trace enabled.');
        batch_crop.debug.writeAndLogSamplePack(debugLog, ...
            @(message) addLog(services, message));
    end
end

function state = onImagesChosen(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'Image file selection cancelled.');
        return;
    end
    items = batch_crop.state.itemsForPaths(paths);
    state.items = batch_crop.state.mergeChosenItems(state.items, items);
    state.currentIndex = min(max(state.currentIndex, 1), numel(state.items));
    state.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
        paths, "batch_crop", state.outputFolder));
    state = clearExportAndCanvas(state);
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state, services);
    end
    addLog(services, sprintf('Selected %d image file(s); crop tasks: %d.', ...
        numel(items), numel(state.items)));
end

function state = onClearImages(state, ~, services)
    state.items = repmat(batch_crop.state.emptyItem(), 0, 1);
    state.currentIndex = 0;
    state = clearExportAndCanvas(state);
    state.cropDefaultsInitialized = false;
    addLog(services, 'Cleared loaded images.');
end

function state = onRemoveImages(state, payload, services)
    event = payload.event;
    if isempty(state.items) || ~isfield(event, 'removedFiles') || ...
            isempty(event.removedFiles)
        return;
    end
    removeIdx = labkit.ui.view.fileIndices(event.removedFiles, ...
        numel(state.items));
    if isempty(removeIdx)
        return;
    end
    state.items(removeIdx) = [];
    if isempty(state.items)
        state.currentIndex = 0;
    else
        state.currentIndex = min(max(state.currentIndex, 1), ...
            numel(state.items));
    end
    state = clearExportAndCanvas(state);
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state, services);
    end
    addLog(services, sprintf('Removed %d crop task(s); remaining: %d.', ...
        numel(removeIdx), numel(state.items)));
end

function state = onDuplicateImage(state, ~, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    duplicated = batch_crop.state.duplicateItem(state.items(state.currentIndex));
    insertAt = state.currentIndex + 1;
    state.items = [state.items(1:state.currentIndex); ...
        duplicated; state.items(insertAt:end)];
    state.currentIndex = insertAt;
    state = clearExportAndCanvas(state);
    addLog(services, sprintf(['Duplicated image %d as crop task %d. ' ...
        'Pick a new crop center.'], insertAt - 1, insertAt));
end

function state = onImageSelectionChanged(state, payload, services)
    if isempty(state.items)
        return;
    end
    idx = labkit.ui.view.fileIndices(payload.event.selectedFiles, ...
        numel(state.items));
    if isempty(idx)
        return;
    end
    state.currentIndex = idx(1);
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state, services);
    end
end

function state = onPreviousImage(state, ~, services)
    if isempty(state.items)
        return;
    end
    state.currentIndex = max(1, state.currentIndex - 1);
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state, services);
    end
end

function state = onNextImage(state, ~, services)
    if isempty(state.items)
        return;
    end
    state.currentIndex = min(numel(state.items), state.currentIndex + 1);
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state, services);
    end
end

function state = onCropGeometryChanged(state, ~, services)
    ui = services.ui;
    labkit.ui.view.setValue(ui, "cropWidth", round(max(1, ...
        ui.controls.cropWidth.valueHandle.Value)));
    labkit.ui.view.setValue(ui, "cropHeight", round(max(1, ...
        ui.controls.cropHeight.valueHandle.Value)));
    state.cropDefaultsInitialized = true;
    [state, ok] = ensureCurrentReady(state, services);
    if ok
        state.previewView = capturePreviewView(state, services);
    end
    state = batch_crop.state.clearExportState(state);
end

function state = onRotationChanged(state, ~, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    state.previewView = capturePreviewView(state, services);
    state.items(state.currentIndex).angleDeg = ...
        services.ui.controls.rotation.valueHandle.Value;
    state = ensureCurrentCenter(state, services);
    state = clearExportAndCanvas(state);
    addLog(services, sprintf('Updated rotation for image %d: %.3g deg.', ...
        state.currentIndex, state.items(state.currentIndex).angleDeg));
end

function state = onPaddingChanged(state, ~, services)
    ui = services.ui;
    labkit.ui.view.setValue(ui, "paddingPercent", ...
        min(max(double(ui.controls.paddingPercent.valueHandle.Value), 0), 200));
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    state.previewView = capturePreviewView(state, services);
    state.items(state.currentIndex).paddingPercent = ...
        ui.controls.paddingPercent.valueHandle.Value;
    state = ensureCurrentCenter(state, services);
    state = clearExportAndCanvas(state);
    addLog(services, sprintf('Updated padding for image %d: %.3g%%.', ...
        state.currentIndex, state.items(state.currentIndex).paddingPercent));
end

function state = onCenterChanged(state, ~, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    state.previewView = capturePreviewView(state, services);
    centerXY = adjustedCropCenter(state, services, ...
        [services.ui.controls.centerX.valueHandle.Value, ...
        services.ui.controls.centerY.valueHandle.Value]);
    state.items(state.currentIndex).centerXY = centerXY;
    state.items(state.currentIndex).centerSet = true;
    labkit.ui.view.setValue(services.ui, "centerX", centerXY(1));
    labkit.ui.view.setValue(services.ui, "centerY", centerXY(2));
    state = batch_crop.state.clearExportState(state);
    addLog(services, sprintf('Set crop center for image %d: x=%.1f, y=%.1f.', ...
        state.currentIndex, centerXY(1), centerXY(2)));
end

function state = onUseImageCenterXY(state, payload, services)
    state = onUseImageCenter(state, payload, services, "xy");
end

function state = onUseImageCenterX(state, payload, services)
    state = onUseImageCenter(state, payload, services, "x");
end

function state = onUseImageCenterY(state, payload, services)
    state = onUseImageCenter(state, payload, services, "y");
end

function state = onUseImageCenter(state, ~, services, mode)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    state.previewView = capturePreviewView(state, services);
    current = state.items(state.currentIndex).centerXY;
    if isempty(current) || any(~isfinite(current))
        current = batch_crop.ops.sourceCenterXY(state.items(state.currentIndex).image);
    end
    sourceCenter = batch_crop.ops.sourceCenterXY( ...
        state.items(state.currentIndex).image);
    switch string(mode)
        case "x"
            current(1) = sourceCenter(1);
        case "y"
            current(2) = sourceCenter(2);
        otherwise
            current = sourceCenter;
    end
    state.items(state.currentIndex).centerXY = ...
        adjustedCropCenter(state, services, current);
    state.items(state.currentIndex).centerSet = true;
    labkit.ui.view.setValue(services.ui, "centerX", ...
        state.items(state.currentIndex).centerXY(1));
    labkit.ui.view.setValue(services.ui, "centerY", ...
        state.items(state.currentIndex).centerXY(2));
    state = batch_crop.state.clearExportState(state);
    addLog(services, sprintf('Set image %d crop %s center.', ...
        state.currentIndex, char(upper(string(mode)))));
end

function state = onScaleSettingChanged(state, ~, services)
    ui = services.ui;
    labkit.ui.view.setValue(ui, "physicalWidth", ...
        max(eps, double(ui.controls.physicalWidth.valueHandle.Value)));
    labkit.ui.view.setValue(ui, "physicalHeight", ...
        max(eps, double(ui.controls.physicalHeight.valueHandle.Value)));
    labkit.ui.view.setValue(ui, "targetPixelsPerUnit", ...
        max(0, double(ui.controls.targetPixelsPerUnit.valueHandle.Value)));
    labkit.ui.view.setValue(ui, "maxUpsamplePercent", ...
        max(0, double(ui.controls.maxUpsamplePercent.valueHandle.Value)));
    if strcmpi(string(ui.controls.scaleMode.valueHandle.Value), "Physical") && ...
            hasTools(state)
        state.tools.scaleTool.setEnabled(struct('hasImage', hasCurrentImage(state)));
    end
    state.previewView = capturePreviewView(state, services);
    state = batch_crop.state.clearExportState(state);
end

function state = onScaleCalibrationChanged(state, ~, services)
    if ~hasCurrentImage(state) || ~hasTools(state)
        return;
    end
    state.items(state.currentIndex).scaleCalibration = ...
        state.tools.scaleTool.calibration();
    state = batch_crop.state.clearExportState(state);
end

function state = onScaleReferenceEditChanged(state, ~, services)
    if hasTools(state) && state.tools.scaleTool.isReferenceEditActive()
        state.tools.cropSession.deactivate();
        return;
    end
    state.previewView = capturePreviewView(state, services);
    state = batch_crop.state.clearExportState(state);
end

function state = onExportSettingChanged(state, ~, ~)
    state = batch_crop.state.clearExportState(state);
end

function state = onChooseOutputFolder(state, ~, services)
    [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
        'Select crop export folder', state.outputFolder);
    if cancelled
        addLog(services, 'Export folder selection cancelled.');
        return;
    end
    state.outputFolder = string(folder);
    state = batch_crop.state.clearExportState(state);
end

function state = onPreviewPointerDown(state, ~, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok || ~hasTools(state)
        return;
    end
    state.previewView = capturePreviewView(state, services);
    geometry = currentGeometry(state, services);
    placement = batch_crop.view.previewPlacement(geometry);
    pt = state.tools.previewAxes.CurrentPoint;
    canvasXY = [pt(1, 1), pt(1, 2)] - placement.offset;
    canvasXY(1) = min(max(canvasXY(1), 1), size(geometry.canvas, 2));
    canvasXY(2) = min(max(canvasXY(2), 1), size(geometry.canvas, 1));
    centerXY = batch_crop.ops.canvasToOriginal(geometry, canvasXY);
    centerXY = adjustedCropCenter(state, services, centerXY);
    state.items(state.currentIndex).centerXY = centerXY;
    state.items(state.currentIndex).centerSet = true;
    labkit.ui.view.setValue(services.ui, "centerX", centerXY(1));
    labkit.ui.view.setValue(services.ui, "centerY", centerXY(2));
    state = batch_crop.state.clearExportState(state);
    addLog(services, sprintf('Picked crop center for image %d: x=%.1f, y=%.1f.', ...
        state.currentIndex, centerXY(1), centerXY(2)));
end

function state = onExportCrops(state, ~, services)
    if isempty(state.items)
        showError(services, 'No images loaded', ...
            'Load images before exporting crops.');
        return;
    end
    if ~all([state.items.centerSet])
        showError(services, 'Crop centers missing', ...
            batch_crop.view.missingWorkflowItemsText(state.items, "center"));
        return;
    end
    scaleSummary = batch_crop.state.scaleCalibrationSummary(state.items);
    if strcmpi(string(services.ui.controls.scaleMode.valueHandle.Value), ...
            "Physical") && ~scaleSummary.allCalibrated
        showError(services, 'Scale calibration missing', ...
            batch_crop.view.missingWorkflowItemsText(state.items, "scale"));
        return;
    end
    [state, loaded] = ensureAllImagesLoaded(state, services);
    if ~loaded
        return;
    end
    opts = currentExportOptions(state, services);
    plan = batch_crop.state.exportPlan(state.items, opts);
    if ~isempty(state.lastExport) && state.lastExportFingerprint == plan.fingerprint
        addLog(services, 'Crop export is already up to date; skipped duplicate write.');
        return;
    end
    try
        payload = batch_crop.export.writeOutputs(state.items, opts);
    catch ME
        if isDebugEnabled(services.debug)
            services.debug.reportException('batchCrop', 'Export failed', ME);
        end
        showError(services, 'Export failed', ME.message);
        return;
    end

    state.lastExport = payload;
    state.lastExportFingerprint = plan.fingerprint;
    statuses = string({payload.results.status});
    savedCount = sum(statuses == "saved");
    failedCount = sum(statuses == "failed");
    addLog(services, sprintf('Exported %d crop(s), %d failed. Manifest: %s', ...
        savedCount, failedCount, char(payload.manifestPath)));
    if failedCount > 0
        showError(services, 'Some crops failed', ...
            sprintf('%d image(s) failed. See the manifest for details.', failedCount));
    end
end

function [state, ok] = ensureCurrentReady(state, services)
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    ok = loaded && hasCurrentImage(state);
    if ok
        state = ensureCurrentCenter(state, services);
        state = initializeCropSizeDefaultsIfNeeded(state, services);
    end
end

function state = initializeCropSizeDefaultsIfNeeded(state, services)
    if state.cropDefaultsInitialized || ~hasCurrentImage(state)
        return;
    end
    imageData = state.items(state.currentIndex).image;
    labkit.ui.view.setValue(services.ui, "cropWidth", ...
        max(1, round(size(imageData, 2) * 0.7)));
    labkit.ui.view.setValue(services.ui, "cropHeight", ...
        max(1, round(size(imageData, 1) * 0.7)));
    state.cropDefaultsInitialized = true;
end

function [state, tf] = ensureCurrentImageLoaded(state, services)
    tf = false;
    if isempty(state.items) || state.currentIndex < 1 || ...
            state.currentIndex > numel(state.items)
        return;
    end
    try
        [state.items, tf] = batch_crop.state.loadImageForIndex( ...
            state.items, state.currentIndex);
    catch ME
        if isDebugEnabled(services.debug)
            services.debug.reportException('batchCrop', 'Could not load image', ME);
        end
        addLog(services, sprintf('Could not load image %d: %s', ...
            state.currentIndex, ME.message));
    end
end

function [state, tf] = ensureAllImagesLoaded(state, services)
    tf = false;
    try
        state.items = batch_crop.state.loadMissingImages(state.items);
        state.canvasCache = batch_crop.state.emptyCanvasCache();
        tf = true;
    catch ME
        if isDebugEnabled(services.debug)
            services.debug.reportException('batchCrop', 'Could not load image', ME);
        end
        showError(services, 'Could not load image', ME.message);
    end
end

function state = ensureCurrentCenter(state, services)
    if ~hasCurrentImage(state)
        return;
    end
    item = state.items(state.currentIndex);
    if isempty(item.centerXY) || any(~isfinite(item.centerXY))
        item.centerXY = batch_crop.ops.sourceCenterXY(item.image);
    end
    item.centerXY = adjustedCropCenter(state, services, item.centerXY);
    state.items(state.currentIndex) = item;
end

function centerXY = adjustedCropCenter(state, services, centerXY)
    geometry = currentGeometry(state, services);
    centerXY = batch_crop.ops.clampCropCenterToCanvas(geometry, centerXY, ...
        currentCropSize(state, services));
end

function geometry = currentGeometry(state, services)
    item = state.items(state.currentIndex);
    [geometry, ~] = batch_crop.state.currentGeometry(state.canvasCache, ...
        state.currentIndex, item, currentPaddingPercent(state, services));
end

function opts = currentExportOptions(state, services)
    ui = services.ui;
    opts = batch_crop.state.exportOptions(state.outputFolder, ...
        ui.controls.format.valueHandle.Value, currentCropSize(state, services), ...
        currentPaddingPercent(state, services), ...
        string(ui.controls.scaleMode.valueHandle.Value), ...
        string(ui.controls.scaleUnit.valueHandle.Value), ...
        [ui.controls.physicalWidth.valueHandle.Value, ...
        ui.controls.physicalHeight.valueHandle.Value], ...
        ui.controls.targetPixelsPerUnit.valueHandle.Value, ...
        ui.controls.maxUpsamplePercent.valueHandle.Value);
end

function cropSize = currentCropSize(state, services)
    ui = services.ui;
    if strcmpi(string(ui.controls.scaleMode.valueHandle.Value), "Physical") && ...
            hasCurrentImage(state)
        cal = batch_crop.state.itemScaleCalibration(state.items, ...
            state.currentIndex);
        if batch_crop.state.isScaleCalibrationSet(cal)
            pixelsPerUnit = batch_crop.ops.pixelsPerUnitForUnit(cal, ...
                string(ui.controls.scaleUnit.valueHandle.Value));
            cropSize = max(1, round([ ...
                double(ui.controls.physicalWidth.valueHandle.Value), ...
                double(ui.controls.physicalHeight.valueHandle.Value)] * ...
                pixelsPerUnit));
            return;
        end
    end
    cropSize = max(1, round([ ...
        double(ui.controls.cropWidth.valueHandle.Value), ...
        double(ui.controls.cropHeight.valueHandle.Value)]));
end

function percent = currentPaddingPercent(state, services)
    if hasCurrentImage(state)
        percent = batch_crop.state.itemPaddingPercent( ...
            state.items(state.currentIndex), ...
            services.ui.controls.paddingPercent.valueHandle.Value);
        return;
    end
    percent = min(max(double( ...
        services.ui.controls.paddingPercent.valueHandle.Value), 0), 200);
end

function previewView = capturePreviewView(state, services)
    previewView = struct('valid', false);
    if ~hasCurrentImage(state) || ~hasTools(state) || ...
            ~all(isfinite(state.tools.previewAxes.XLim)) || ...
            ~all(isfinite(state.tools.previewAxes.YLim))
        return;
    end
    geometry = currentGeometry(state, services);
    placement = batch_crop.view.previewPlacement(geometry);
    previewView = batch_crop.view.capturePreviewView( ...
        state.tools.previewAxes, geometry, placement);
end

function state = clearExportAndCanvas(state)
    state = batch_crop.state.clearExportState(state);
    state.canvasCache = batch_crop.state.emptyCanvasCache();
end

function tf = hasCurrentImage(state)
    tf = ~isempty(state.items) && state.currentIndex >= 1 && ...
        state.currentIndex <= numel(state.items) && ...
        ~isempty(state.items(state.currentIndex).image);
end

function tf = hasTools(state)
    tf = isfield(state, 'tools') && isstruct(state.tools) && ...
        isfield(state.tools, 'scaleTool') && ~isempty(state.tools.scaleTool);
end

function showError(services, titleText, message)
    addLog(services, sprintf('%s: %s', titleText, message));
    labkit.ui.app.showAlert(services.figure, message, titleText);
end

function addLog(services, message)
    labkit.ui.view.appendLog(services.ui, 'appLog', message);
    if isDebugEnabled(services.debug)
        services.debug.append(message);
    end
end

function fcn = traceFcn(debugLog)
    if isDebugEnabled(debugLog)
        fcn = debugLog.trace;
    else
        fcn = @(varargin) [];
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
