% Expected caller: labkit_BatchImageCrop_app. Input is the debug context
% prepared by the public launcher. Output is the app figure. Side effects are
% GUI creation, user-driven image loading, crop export, and debug trace attachment.
function fig = run(debugLog)
    S = struct();
    S.items = repmat(batch_crop.state.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.outputFolder = string(labkit.ui.app.defaultDialogFolder("output"));
    S.lastExport = [];
    S.lastExportFingerprint = "";
    S.canvasCache = batch_crop.state.emptyCanvasCache();
    S.cropDefaultsInitialized = false;
    callbacks = struct( ...
        "imagesChosen", @onImagesChosen, ...
        "removeImages", @(~, event) onRemoveImages(event), ...
        "clearImages", @(~, ~) onClearImages(), ...
        "duplicateImage", @(~, ~) onDuplicateImage(), ...
        "imageSelectionChanged", @(~, event) onImageSelectionChanged(event), ...
        "previousImage", @(~, ~) onPreviousImage(), ...
        "nextImage", @(~, ~) onNextImage(), ...
        "cropGeometryChanged", @(~, ~) onCropGeometryChanged(), ...
        "rotationChanged", @(~, ~) onRotationChanged(), ...
        "paddingChanged", @(~, ~) onPaddingChanged(), ...
        "centerChanged", @(~, ~) onCenterChanged(), ...
        "useImageCenter", @(~, ~) onUseImageCenter("xy"), ...
        "useImageXCenter", @(~, ~) onUseImageCenter("x"), ...
        "useImageYCenter", @(~, ~) onUseImageCenter("y"), ...
        "scaleSettingChanged", @(~, ~) onScaleSettingChanged(), ...
        "exportSettingChanged", @(~, ~) onExportSettingChanged(), ...
        "chooseOutputFolder", @(~, ~) onChooseOutputFolder(), ...
        "exportCrops", @(~, ~) onExportCrops());
    spec = batch_crop.ui.buildSpec(S.outputFolder, callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;
    previewAxes = ui.controls.preview.primaryAxes;
    imageRuntime = labkit.ui.tool.createRuntime(previewAxes, ...
        struct('figure', fig, 'onTrace', debugLog.trace));
    cropSession = imageRuntime.createSession(struct( ...
        'name', 'batchCropCenter', ...
        'onPointerDown', @onPreviewPointerDown, ...
        'installScrollWheel', false));
    scaleTool = labkit.ui.tool.scaleBar(ui.controls.scaleBarHost.grid, 1, ...
        imageRuntime, struct( ...
        'title', 'Current Image Scale', ...
        'defaultUnit', 'um', ...
        'defaultReferenceLength', 100, ...
        'onCalibrationChanged', @(~, ~) onScaleCalibrationChanged(), ...
        'onReferenceEditChanged', @(~, ~) onScaleReferenceEditChanged(), ...
        'onError', @showError, ...
        'onTrace', debugLog.trace));

    btnClearImages = ui.controls.images.clearButton;
    btnDuplicateImage = ui.controls.duplicateImage.button;
    txtImageSource = ui.controls.imageSource.valueHandle;
    btnPrevious = ui.controls.previousImage.button;
    btnNext = ui.controls.nextImage.button;
    txtImageStatus = ui.controls.imageStatus.valueHandle;
    edtCropWidth = ui.controls.cropWidth.valueHandle;
    edtCropHeight = ui.controls.cropHeight.valueHandle;
    edtRotation = ui.controls.rotation.valueHandle;
    edtPaddingPercent = ui.controls.paddingPercent.valueHandle;
    edtCenterX = ui.controls.centerX.valueHandle;
    edtCenterY = ui.controls.centerY.valueHandle;
    btnUseImageCenter = ui.controls.useImageCenter.button;
    btnUseImageXCenter = ui.controls.useImageXCenter.button;
    btnUseImageYCenter = ui.controls.useImageYCenter.button;
    ddScaleMode = ui.controls.scaleMode.valueHandle;
    ddScaleUnit = ui.controls.scaleUnit.valueHandle;
    edtPhysicalWidth = ui.controls.physicalWidth.valueHandle;
    edtPhysicalHeight = ui.controls.physicalHeight.valueHandle;
    edtTargetPixelsPerUnit = ui.controls.targetPixelsPerUnit.valueHandle;
    edtMaxUpsamplePercent = ui.controls.maxUpsamplePercent.valueHandle;
    txtScaleStatus = ui.controls.scaleStatus.valueHandle;
    ddFormat = ui.controls.format.valueHandle;
    txtOutputFolder = ui.controls.outputFolder.valueHandle;
    btnChooseOutput = ui.controls.chooseOutputFolder.button;
    btnExport = ui.controls.exportCrops.button;
    resultTable = ui.controls.resultTable.table;
    txtDetails = ui.controls.details.textArea;
    if debugLog.enabled
        debugLog.trace('Batch image crop debug trace enabled.');
        batch_crop.debug.writeAndLogSamplePack(debugLog, @addLog);
    end
    resetPreviewAxes();
    refreshAll();

    function onImagesChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Image file selection cancelled.');
            return;
        end
        items = batch_crop.state.itemsForPaths(paths);
        S.items = batch_crop.state.mergeChosenItems(S.items, items);
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        S.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
            paths, "batch_crop", S.outputFolder));
        txtOutputFolder.Value = char(S.outputFolder);
        S = batch_crop.state.clearExportState(S);
        S.canvasCache = batch_crop.state.emptyCanvasCache();
        addLog(sprintf('Selected %d image file(s); crop tasks: %d.', numel(items), numel(S.items)));
        refreshAll();
    end

    function onClearImages()
        S.items = repmat(batch_crop.state.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S = batch_crop.state.clearExportState(S);
        S.canvasCache = batch_crop.state.emptyCanvasCache();
        S.cropDefaultsInitialized = false;
        addLog('Cleared loaded images.');
        refreshAll();
    end

    function onRemoveImages(event)
        if isempty(S.items) || ~isfield(event, 'removedFiles') || isempty(event.removedFiles)
            refreshAll();
            return;
        end
        removeIdx = labkit.ui.view.fileIndices(event.removedFiles, numel(S.items));
        if isempty(removeIdx)
            refreshAll();
            return;
        end
        S.items(removeIdx) = [];
        if isempty(S.items)
            S.currentIndex = 0;
        else
            S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        end
        S = batch_crop.state.clearExportState(S);
        S.canvasCache = batch_crop.state.emptyCanvasCache();
        addLog(sprintf('Removed %d crop task(s); remaining: %d.', ...
            numel(removeIdx), numel(S.items)));
        refreshAll();
    end

    function onDuplicateImage()
        if ~hasCurrentImage()
            return;
        end

        duplicated = batch_crop.state.duplicateItem(S.items(S.currentIndex));
        insertAt = S.currentIndex + 1;
        S.items = [S.items(1:S.currentIndex); duplicated; S.items(insertAt:end)];
        S.currentIndex = insertAt;
        S = batch_crop.state.clearExportState(S);
        S.canvasCache = batch_crop.state.emptyCanvasCache();
        addLog(sprintf('Duplicated image %d as crop task %d. Pick a new crop center.', ...
            insertAt - 1, insertAt));
        refreshAll();
    end

    function onImageSelectionChanged(event)
        if isempty(S.items)
            return;
        end
        idx = labkit.ui.view.fileIndices(event.selectedFiles, numel(S.items));
        if isempty(idx)
            return;
        end
        S.currentIndex = idx(1);
        refreshAll();
    end

    function onPreviousImage()
        if isempty(S.items)
            return;
        end
        S.currentIndex = max(1, S.currentIndex - 1);
        refreshAll();
    end

    function onNextImage()
        if isempty(S.items)
            return;
        end
        S.currentIndex = min(numel(S.items), S.currentIndex + 1);
        refreshAll();
    end

    function onCropGeometryChanged()
        labkit.ui.view.setValue(ui, "cropWidth", round(max(1, edtCropWidth.Value)));
        labkit.ui.view.setValue(ui, "cropHeight", round(max(1, edtCropHeight.Value)));
        ensureCurrentCenter();
        S = batch_crop.state.clearExportState(S);
        refreshPreview(capturePreviewView());
        refreshSummary();
    end

    function onRotationChanged()
        if ~hasCurrentImage()
            return;
        end
        viewState = capturePreviewView();
        S.items(S.currentIndex).angleDeg = edtRotation.Value;
        ensureCurrentCenter();
        S = batch_crop.state.clearExportState(S);
        S.canvasCache = batch_crop.state.emptyCanvasCache();
        addLog(sprintf('Updated rotation for image %d: %.3g deg.', ...
            S.currentIndex, S.items(S.currentIndex).angleDeg));
        refreshAll(viewState);
    end

    function onPaddingChanged()
        labkit.ui.view.setValue(ui, "paddingPercent", ...
            min(max(double(edtPaddingPercent.Value), 0), 200));
        if ~hasCurrentImage()
            return;
        end
        viewState = capturePreviewView();
        S.items(S.currentIndex).paddingPercent = edtPaddingPercent.Value;
        ensureCurrentCenter();
        S = batch_crop.state.clearExportState(S);
        S.canvasCache = batch_crop.state.emptyCanvasCache();
        addLog(sprintf('Updated padding for image %d: %.3g%%.', ...
            S.currentIndex, S.items(S.currentIndex).paddingPercent));
        refreshPreview(viewState);
        refreshSummary();
    end

    function onCenterChanged()
        if ~hasCurrentImage()
            return;
        end
        viewState = capturePreviewView();
        centerXY = adjustedCropCenter([edtCenterX.Value, edtCenterY.Value]);
        S.items(S.currentIndex).centerXY = centerXY;
        S.items(S.currentIndex).centerSet = true;
        labkit.ui.view.setValue(ui, "centerX", centerXY(1));
        labkit.ui.view.setValue(ui, "centerY", centerXY(2));
        S = batch_crop.state.clearExportState(S);
        addLog(sprintf('Set crop center for image %d: x=%.1f, y=%.1f.', ...
            S.currentIndex, centerXY(1), centerXY(2)));
        refreshAll(viewState);
    end

    function onUseImageCenter(mode)
        if ~hasCurrentImage()
            return;
        end
        viewState = capturePreviewView();
        current = S.items(S.currentIndex).centerXY;
        if isempty(current) || any(~isfinite(current))
            current = batch_crop.ops.sourceCenterXY(S.items(S.currentIndex).image);
        end
        sourceCenter = batch_crop.ops.sourceCenterXY(S.items(S.currentIndex).image);
        switch string(mode)
            case "x"
                current(1) = sourceCenter(1);
            case "y"
                current(2) = sourceCenter(2);
            otherwise
                current = sourceCenter;
        end
        S.items(S.currentIndex).centerXY = adjustedCropCenter(current);
        S.items(S.currentIndex).centerSet = true;
        labkit.ui.view.setValue(ui, "centerX", S.items(S.currentIndex).centerXY(1));
        labkit.ui.view.setValue(ui, "centerY", S.items(S.currentIndex).centerXY(2));
        S = batch_crop.state.clearExportState(S);
        addLog(sprintf('Set image %d crop %s center.', ...
            S.currentIndex, char(upper(string(mode)))));
        refreshAll(viewState);
    end

    function onScaleSettingChanged()
        labkit.ui.view.setValue(ui, "physicalWidth", ...
            max(eps, double(edtPhysicalWidth.Value)));
        labkit.ui.view.setValue(ui, "physicalHeight", ...
            max(eps, double(edtPhysicalHeight.Value)));
        labkit.ui.view.setValue(ui, "targetPixelsPerUnit", ...
            max(0, double(edtTargetPixelsPerUnit.Value)));
        labkit.ui.view.setValue(ui, "maxUpsamplePercent", ...
            max(0, double(edtMaxUpsamplePercent.Value)));
        if strcmpi(string(ddScaleMode.Value), "Physical")
            scaleTool.setEnabled(struct('hasImage', hasCurrentImage()));
        end
        S = batch_crop.state.clearExportState(S);
        refreshAll(capturePreviewView());
    end

    function onScaleCalibrationChanged()
        if ~hasCurrentImage()
            return;
        end
        cal = scaleTool.calibration();
        S.items(S.currentIndex).scaleCalibration = cal;
        S = batch_crop.state.clearExportState(S);
        refreshList();
        refreshSummary();
    end

    function onScaleReferenceEditChanged()
        if scaleTool.isReferenceEditActive()
            cropSession.deactivate();
            return;
        end
        S = batch_crop.state.clearExportState(S);
        refreshPreview(capturePreviewView());
        refreshSummary();
    end

    function onExportSettingChanged()
        S = batch_crop.state.clearExportState(S);
        refreshSummary();
    end

    function onChooseOutputFolder()
        [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
            'Select crop export folder', S.outputFolder);
        if cancelled
            addLog('Export folder selection cancelled.');
            return;
        end
        S.outputFolder = string(folder);
        txtOutputFolder.Value = char(S.outputFolder);
        S = batch_crop.state.clearExportState(S);
        refreshSummary();
    end

    function onPreviewPointerDown(~, ~)
        if ~hasCurrentImage()
            return;
        end
        viewState = capturePreviewView();
        geometry = currentGeometry();
        placement = batch_crop.view.previewPlacement(geometry);
        pt = previewAxes.CurrentPoint;
        canvasXY = [pt(1, 1), pt(1, 2)] - placement.offset;
        canvasXY(1) = min(max(canvasXY(1), 1), size(geometry.canvas, 2));
        canvasXY(2) = min(max(canvasXY(2), 1), size(geometry.canvas, 1));
        centerXY = batch_crop.ops.canvasToOriginal(geometry, canvasXY);
        centerXY = adjustedCropCenter(centerXY);
        wasCenterSet = S.items(S.currentIndex).centerSet;
        S.items(S.currentIndex).centerXY = centerXY;
        S.items(S.currentIndex).centerSet = true;
        labkit.ui.view.setValue(ui, "centerX", centerXY(1));
        labkit.ui.view.setValue(ui, "centerY", centerXY(2));
        S = batch_crop.state.clearExportState(S);
        addLog(sprintf('Picked crop center for image %d: x=%.1f, y=%.1f.', ...
            S.currentIndex, centerXY(1), centerXY(2)));
        if ~wasCenterSet
            refreshList();
        end
        refreshPreview(viewState);
        refreshSummary();
    end

    function onExportCrops()
        if isempty(S.items)
            showError('No images loaded', 'Load images before exporting crops.');
            return;
        end
        if ~all([S.items.centerSet])
            showError('Crop centers missing', ...
                batch_crop.view.missingWorkflowItemsText(S.items, "center"));
            return;
        end
        scaleSummary = batch_crop.state.scaleCalibrationSummary(S.items);
        if strcmpi(string(ddScaleMode.Value), "Physical") && ~scaleSummary.allCalibrated
            showError('Scale calibration missing', ...
                batch_crop.view.missingWorkflowItemsText(S.items, "scale"));
            return;
        end
        if ~ensureAllImagesLoaded()
            return;
        end
        opts = currentExportOptions();
        plan = batch_crop.state.exportPlan(S.items, opts);
        if ~isempty(S.lastExport) && S.lastExportFingerprint == plan.fingerprint
            addLog('Crop export is already up to date; skipped duplicate write.');
            refreshSummary();
            return;
        end
        try
            payload = batch_crop.export.writeOutputs(S.items, opts);
        catch ME
            debugLog.reportException('batchCrop', 'Export failed', ME);
            showError('Export failed', ME.message);
            return;
        end

        S.lastExport = payload;
        S.lastExportFingerprint = plan.fingerprint;
        statuses = string({payload.results.status});
        savedCount = sum(statuses == "saved");
        failedCount = sum(statuses == "failed");
        addLog(sprintf('Exported %d crop(s), %d failed. Manifest: %s', ...
            savedCount, failedCount, char(payload.manifestPath)));
        refreshSummary();
        if failedCount > 0
            showError('Some crops failed', ...
                sprintf('%d image(s) failed. See the manifest for details.', failedCount));
        end
    end

    function refreshAll(viewState)
        if nargin < 1
            viewState = [];
        end
        refreshList();
        refreshControls();
        refreshPreview(viewState);
        refreshSummary();
    end

    function refreshList()
        if isempty(S.items)
            labkit.ui.view.setListItems(ui, 'images', {});
            txtImageSource.Value = 'No images loaded';
            txtImageStatus.Value = 'Images: 0';
            return;
        end

        labkit.ui.view.setValue(ui, 'images', ...
            batch_crop.view.filePanelEntries(S.items, string(ddScaleMode.Value)));
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        files = labkit.ui.view.getFiles(ui, 'images');
        labkit.ui.view.setFileSelection(ui, 'images', files(S.currentIndex));
        txtImageSource.Value = char(S.items(S.currentIndex).path);
        if strcmpi(string(ddScaleMode.Value), "Physical")
            scaleSummary = batch_crop.state.scaleCalibrationSummary(S.items);
            txtImageStatus.Value = sprintf('Images: %d | centers: %d | scales: %d', ...
                numel(S.items), batch_crop.state.countConfirmedCenters(S.items), ...
                scaleSummary.calibratedCount);
        else
            txtImageStatus.Value = sprintf('Images: %d | confirmed centers: %d', ...
                numel(S.items), batch_crop.state.countConfirmedCenters(S.items));
        end
    end

    function refreshControls()
        ensureCurrentImageLoaded();
        hasImage = hasCurrentImage();
        enabled = batch_crop.view.ternary(hasImage, 'on', 'off');
        physicalMode = strcmpi(string(ddScaleMode.Value), "Physical");
        btnClearImages.Enable = enabled;
        btnDuplicateImage.Enable = enabled;
        btnPrevious.Enable = batch_crop.view.ternary(hasImage && S.currentIndex > 1, 'on', 'off');
        btnNext.Enable = batch_crop.view.ternary(hasImage && S.currentIndex < numel(S.items), 'on', 'off');
        labkit.ui.view.setEnabled(ui, "cropWidth", hasImage && ~physicalMode);
        labkit.ui.view.setEnabled(ui, "cropHeight", hasImage && ~physicalMode);
        labkit.ui.view.setEnabled(ui, "rotation", hasImage);
        labkit.ui.view.setEnabled(ui, "paddingPercent", hasImage);
        labkit.ui.view.setEnabled(ui, "centerX", hasImage);
        labkit.ui.view.setEnabled(ui, "centerY", hasImage);
        btnUseImageCenter.Enable = enabled;
        btnUseImageXCenter.Enable = enabled;
        btnUseImageYCenter.Enable = enabled;
        ddScaleUnit.Enable = batch_crop.view.ternary(physicalMode, 'on', 'off');
        labkit.ui.view.setEnabled(ui, "physicalWidth", hasImage && physicalMode);
        labkit.ui.view.setEnabled(ui, "physicalHeight", hasImage && physicalMode);
        labkit.ui.view.setEnabled(ui, "targetPixelsPerUnit", hasImage && physicalMode);
        labkit.ui.view.setEnabled(ui, "maxUpsamplePercent", hasImage && physicalMode);

        if hasImage
            item = S.items(S.currentIndex);
            cropLimit = batch_crop.ops.cropSizeUpperLimit(item.image);
            labkit.ui.view.setLimits(ui, "cropWidth", ...
                [1, cropLimit]);
            labkit.ui.view.setLimits(ui, "cropHeight", ...
                [1, cropLimit]);
            initializeCropSizeDefaultsIfNeeded(item.image);
            ensureCurrentCenter();
            item = S.items(S.currentIndex);
            labkit.ui.view.setValue(ui, "rotation", item.angleDeg);
            labkit.ui.view.setValue(ui, "paddingPercent", ...
                batch_crop.state.itemPaddingPercent(item, edtPaddingPercent.Value));
            centerLimits = batch_crop.view.centerCoordinateLimits(currentGeometry());
            labkit.ui.view.setLimits(ui, "centerX", centerLimits.x);
            labkit.ui.view.setLimits(ui, "centerY", centerLimits.y);
            labkit.ui.view.setValue(ui, "centerX", item.centerXY(1));
            labkit.ui.view.setValue(ui, "centerY", item.centerXY(2));
        else
            labkit.ui.view.setLimits(ui, "cropWidth", [1, 100000]);
            labkit.ui.view.setLimits(ui, "cropHeight", [1, 100000]);
            labkit.ui.view.setValue(ui, "rotation", 0);
            labkit.ui.view.setValue(ui, "paddingPercent", 0);
            labkit.ui.view.setLimits(ui, "centerX", [1, 100000]);
            labkit.ui.view.setLimits(ui, "centerY", [1, 100000]);
            labkit.ui.view.setValue(ui, "centerX", 1);
            labkit.ui.view.setValue(ui, "centerY", 1);
        end

        refreshScaleControls([]);
        btnExport.Enable = enabled;
    end

    function refreshPreview(viewState)
        if nargin < 1
            viewState = [];
        end
        ensureCurrentImageLoaded();
        if ~hasCurrentImage()
            resetPreviewAxes();
            cropSession.setBackground([]);
            cropSession.setGraphics([]);
            scaleTool.setBackground([]);
            scaleTool.setImageSize([]);
            return;
        end
        ensureCurrentCenter();
        geometry = currentGeometry();
        placement = batch_crop.view.previewPlacement(geometry);
        item = S.items(S.currentIndex);
        tools = struct('scaleTool', scaleTool, 'cropSession', cropSession);
        batch_crop.view.drawPreview(ui, previewAxes, geometry, placement, item, ...
            currentCropSize(), tools, viewState);
    end

    function refreshSummary()
        ensureCurrentImageLoaded();
        cropSize = currentCropSize();
        resultTable.Data = batch_crop.view.summaryTableData(S, S.currentIndex, ...
            cropSize(1), cropSize(2), currentPaddingPercent(), ddFormat.Value);
        txtDetails.Value = batch_crop.view.detailLines(S, S.currentIndex, ...
            cropSize(1), cropSize(2), currentPaddingPercent());
        refreshScaleControls(txtScaleStatus);
    end

    function resetPreviewAxes()
        labkit.ui.view.resetAxes(ui, 'preview', ...
            'Padded rotation preview + fixed crop', true, 'crop');
    end

    function opts = currentExportOptions()
        opts = batch_crop.state.exportOptions(S.outputFolder, ddFormat.Value, ...
            currentCropSize(), currentPaddingPercent(), string(ddScaleMode.Value), ...
            string(ddScaleUnit.Value), [edtPhysicalWidth.Value, edtPhysicalHeight.Value], ...
            edtTargetPixelsPerUnit.Value, edtMaxUpsamplePercent.Value);
    end

    function cropSize = currentCropSize()
        if strcmpi(string(ddScaleMode.Value), "Physical") && hasCurrentImage()
            cal = batch_crop.state.itemScaleCalibration(S.items, S.currentIndex);
            if batch_crop.state.isScaleCalibrationSet(cal)
                pixelsPerUnit = batch_crop.ops.pixelsPerUnitForUnit(cal, string(ddScaleUnit.Value));
                cropSize = max(1, round([ ...
                    double(edtPhysicalWidth.Value), double(edtPhysicalHeight.Value)] * pixelsPerUnit));
                return;
            end
        end
        cropSize = max(1, round([double(edtCropWidth.Value), double(edtCropHeight.Value)]));
    end

    function percent = currentPaddingPercent()
        if hasCurrentImage()
            percent = batch_crop.state.itemPaddingPercent( ...
                S.items(S.currentIndex), edtPaddingPercent.Value);
            return;
        end
        percent = min(max(double(edtPaddingPercent.Value), 0), 200);
    end

    function geometry = currentGeometry()
        item = S.items(S.currentIndex);
        [geometry, S.canvasCache] = batch_crop.state.currentGeometry( ...
            S.canvasCache, S.currentIndex, item, currentPaddingPercent());
    end

    function state = capturePreviewView()
        state = struct('valid', false);
        if ~hasCurrentImage() || ~all(isfinite(previewAxes.XLim)) || ...
                ~all(isfinite(previewAxes.YLim))
            return;
        end

        geometry = currentGeometry();
        placement = batch_crop.view.previewPlacement(geometry);
        state = batch_crop.view.capturePreviewView(previewAxes, geometry, placement);
    end

    function ensureCurrentCenter()
        if ~hasCurrentImage()
            return;
        end
        item = S.items(S.currentIndex);
        if isempty(item.centerXY) || any(~isfinite(item.centerXY))
            item.centerXY = batch_crop.ops.sourceCenterXY(item.image);
        end
        item.centerXY = adjustedCropCenter(item.centerXY);
        S.items(S.currentIndex) = item;
    end

    function initializeCropSizeDefaultsIfNeeded(imageData)
        if S.cropDefaultsInitialized
            return;
        end
        labkit.ui.view.setValue(ui, "cropWidth", ...
            max(1, round(size(imageData, 2) * 0.7)));
        labkit.ui.view.setValue(ui, "cropHeight", ...
            max(1, round(size(imageData, 1) * 0.7)));
        S.cropDefaultsInitialized = true;
    end

    function centerXY = adjustedCropCenter(centerXY)
        geometry = currentGeometry();
        centerXY = batch_crop.ops.clampCropCenterToCanvas(geometry, centerXY, ...
            currentCropSize());
    end

    function tf = hasCurrentImage()
        tf = ~isempty(S.items) && S.currentIndex >= 1 && S.currentIndex <= numel(S.items) && ...
            ~isempty(S.items(S.currentIndex).image);
    end

    function tf = ensureCurrentImageLoaded()
        tf = false;
        if isempty(S.items) || S.currentIndex < 1 || S.currentIndex > numel(S.items)
            return;
        end
        try
            [S.items, tf] = batch_crop.state.loadImageForIndex(S.items, S.currentIndex);
        catch ME
            debugLog.reportException('batchCrop', 'Could not load image', ME);
            addLog(sprintf('Could not load image %d: %s', S.currentIndex, ME.message));
        end
    end

    function tf = ensureAllImagesLoaded()
        tf = false;
        try
            S.items = batch_crop.state.loadMissingImages(S.items);
            S.canvasCache = batch_crop.state.emptyCanvasCache();
            tf = true;
        catch ME
            debugLog.reportException('batchCrop', 'Could not load image', ME);
            showError('Could not load image', ME.message);
        end
    end

    function refreshScaleControls(statusControl)
        batch_crop.view.refreshScaleControls(scaleTool, statusControl, S.items, ...
            S.currentIndex, string(ddScaleMode.Value), ...
            [edtPhysicalWidth.Value, edtPhysicalHeight.Value], string(ddScaleUnit.Value));
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'appLog', message);
        if debugLog.enabled
            debugLog.append(message);
        end
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        labkit.ui.app.showAlert(fig, message, titleText);
    end
end
