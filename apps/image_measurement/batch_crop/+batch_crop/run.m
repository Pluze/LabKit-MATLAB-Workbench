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
        "useImageCenter", @(~, ~) onUseImageCenter(), ...
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
    end
    resetPreviewAxes();
    refreshAll();

    function onImagesChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Image file selection cancelled.');
            return;
        end
        try
            items = batch_crop.state.readItems(paths);
        catch ME
            debugLog.reportException('batchCrop', 'Could not load images', ME);
            showError('Could not load images', ME.message);
            return;
        end
        S.items = batch_crop.state.mergeChosenItems(S.items, items);
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        S.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
            paths, "batch_crop", S.outputFolder));
        txtOutputFolder.Value = char(S.outputFolder);
        S = batch_crop.state.clearExportState(S);
        S.canvasCache = batch_crop.state.emptyCanvasCache();
        addLog(sprintf('Loaded %d image file(s); crop tasks: %d.', numel(items), numel(S.items)));
        refreshAll();
    end

    function onClearImages()
        S.items = repmat(batch_crop.state.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S = batch_crop.state.clearExportState(S);
        S.canvasCache = batch_crop.state.emptyCanvasCache();
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
        edtCropWidth.Value = round(max(1, edtCropWidth.Value));
        edtCropHeight.Value = round(max(1, edtCropHeight.Value));
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
        edtPaddingPercent.Value = min(max(double(edtPaddingPercent.Value), 0), 200);
        if ~hasCurrentImage()
            return;
        end
        viewState = capturePreviewView();
        S.items(S.currentIndex).paddingPercent = edtPaddingPercent.Value;
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
        S.items(S.currentIndex).centerXY = [edtCenterX.Value, edtCenterY.Value];
        S.items(S.currentIndex).centerSet = true;
        S = batch_crop.state.clearExportState(S);
        addLog(sprintf('Set crop center for image %d: x=%.1f, y=%.1f.', ...
            S.currentIndex, edtCenterX.Value, edtCenterY.Value));
        refreshAll(viewState);
    end

    function onUseImageCenter()
        if ~hasCurrentImage()
            return;
        end
        viewState = capturePreviewView();
        S.items(S.currentIndex).centerXY = batch_crop.ops.sourceCenterXY(S.items(S.currentIndex).image);
        S.items(S.currentIndex).centerSet = true;
        S = batch_crop.state.clearExportState(S);
        addLog(sprintf('Set image %d crop center to source image center.', ...
            S.currentIndex));
        refreshAll(viewState);
    end

    function onScaleSettingChanged()
        edtPhysicalWidth.Value = max(eps, double(edtPhysicalWidth.Value));
        edtPhysicalHeight.Value = max(eps, double(edtPhysicalHeight.Value));
        edtTargetPixelsPerUnit.Value = max(0, double(edtTargetPixelsPerUnit.Value));
        edtMaxUpsamplePercent.Value = max(0, double(edtMaxUpsamplePercent.Value));
        if strcmpi(currentScaleMode(), "Physical")
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
        centerXY = batch_crop.ops.clampCenterToSource(centerXY, ...
            S.items(S.currentIndex).image);
        S.items(S.currentIndex).centerXY = centerXY;
        S.items(S.currentIndex).centerSet = true;
        S = batch_crop.state.clearExportState(S);
        addLog(sprintf('Picked crop center for image %d: x=%.1f, y=%.1f.', ...
            S.currentIndex, centerXY(1), centerXY(2)));
        refreshAll(viewState);
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
        if strcmpi(currentScaleMode(), "Physical") && ~scaleSummary.allCalibrated
            showError('Scale calibration missing', ...
                batch_crop.view.missingWorkflowItemsText(S.items, "scale"));
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
            batch_crop.view.filePanelEntries(S.items, currentScaleMode()));
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        files = labkit.ui.view.getFiles(ui, 'images');
        labkit.ui.view.setFileSelection(ui, 'images', files(S.currentIndex));
        txtImageSource.Value = char(S.items(S.currentIndex).path);
        if strcmpi(currentScaleMode(), "Physical")
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
        hasImage = hasCurrentImage();
        enabled = batch_crop.view.ternary(hasImage, 'on', 'off');
        physicalMode = strcmpi(currentScaleMode(), "Physical");
        btnClearImages.Enable = enabled;
        btnDuplicateImage.Enable = enabled;
        btnPrevious.Enable = batch_crop.view.ternary(hasImage && S.currentIndex > 1, 'on', 'off');
        btnNext.Enable = batch_crop.view.ternary(hasImage && S.currentIndex < numel(S.items), 'on', 'off');
        edtCropWidth.Enable = batch_crop.view.ternary(hasImage && ~physicalMode, 'on', 'off');
        edtCropHeight.Enable = batch_crop.view.ternary(hasImage && ~physicalMode, 'on', 'off');
        edtRotation.Enable = enabled;
        edtPaddingPercent.Enable = enabled;
        edtCenterX.Enable = enabled;
        edtCenterY.Enable = enabled;
        btnUseImageCenter.Enable = enabled;
        ddScaleUnit.Enable = batch_crop.view.ternary(physicalMode, 'on', 'off');
        edtPhysicalWidth.Enable = batch_crop.view.ternary(physicalMode, 'on', 'off');
        edtPhysicalHeight.Enable = batch_crop.view.ternary(physicalMode, 'on', 'off');
        edtTargetPixelsPerUnit.Enable = batch_crop.view.ternary(physicalMode, 'on', 'off');
        edtMaxUpsamplePercent.Enable = batch_crop.view.ternary(physicalMode, 'on', 'off');

        if hasImage
            ensureCurrentCenter();
            item = S.items(S.currentIndex);
            edtRotation.Value = item.angleDeg;
            edtPaddingPercent.Value = batch_crop.state.itemPaddingPercent(item, edtPaddingPercent.Value);
            edtCenterX.Limits = [1, max(1, size(item.image, 2))];
            edtCenterY.Limits = [1, max(1, size(item.image, 1))];
            edtCenterX.Value = item.centerXY(1);
            edtCenterY.Value = item.centerXY(2);
        else
            edtRotation.Value = 0;
            edtPaddingPercent.Value = 0;
            edtCenterX.Limits = [1, Inf];
            edtCenterY.Limits = [1, Inf];
            edtCenterX.Value = 1;
            edtCenterY.Value = 1;
        end

        refreshScaleTool();
        btnExport.Enable = enabled;
    end

    function refreshPreview(viewState)
        if nargin < 1
            viewState = [];
        end
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
        hImage = labkit.ui.view.drawImage(ui, 'preview', geometry.canvas, ...
            "title", "Padded rotation preview + fixed crop", ...
            "axis", "crop", ...
            "options", struct("xData", placement.xData, "yData", placement.yData));
        hold(previewAxes, 'on');
        item = S.items(S.currentIndex);
        cropWidth = currentCropWidth();
        cropHeight = currentCropHeight();
        canvasCenterXY = batch_crop.ops.originalToCanvas(geometry, item.centerXY) + placement.offset;
        position = batch_crop.view.rectanglePosition(canvasCenterXY, cropWidth, cropHeight);
        hRect = rectangle(previewAxes, 'Position', position, ...
            'EdgeColor', [1 0.84 0], ...
            'LineWidth', 1.5, ...
            'LineStyle', '-');
        hLineX = plot(previewAxes, ...
            [canvasCenterXY(1) - 16, canvasCenterXY(1) + 16], ...
            [canvasCenterXY(2), canvasCenterXY(2)], ...
            'Color', [0 0.85 1], ...
            'LineWidth', 1.25);
        hLineY = plot(previewAxes, ...
            [canvasCenterXY(1), canvasCenterXY(1)], ...
            [canvasCenterXY(2) - 16, canvasCenterXY(2) + 16], ...
            'Color', [0 0.85 1], ...
            'LineWidth', 1.25);
        hold(previewAxes, 'off');
        scaleTool.setBackground(hImage);
        scaleTool.setImageSize(size(item.image));
        scaleTool.refresh();
        cropSession.setBackground(hImage);
        cropSession.setGraphics([hRect, hLineX, hLineY]);
        cropSession.activateIfAvailable();
        batch_crop.view.restorePreviewView(previewAxes, viewState, geometry, placement);
    end

    function refreshSummary()
        resultTable.Data = batch_crop.view.summaryTableData(S, S.currentIndex, ...
            currentCropWidth(), currentCropHeight(), currentPaddingPercent(), ddFormat.Value);
        txtDetails.Value = batch_crop.view.detailLines(S, S.currentIndex, ...
            currentCropWidth(), currentCropHeight(), currentPaddingPercent());
        refreshScaleStatus();
    end

    function resetPreviewAxes()
        labkit.ui.view.resetAxes(ui, 'preview', ...
            'Padded rotation preview + fixed crop', true, 'crop');
    end

    function opts = currentExportOptions()
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = ddFormat.Value;
        opts.cropWidth = currentCropWidth();
        opts.cropHeight = currentCropHeight();
        opts.paddingPercent = currentPaddingPercent();
        opts.scaleMode = currentScaleMode();
        opts.scaleUnit = currentScaleUnit();
        opts.physicalWidth = max(eps, double(edtPhysicalWidth.Value));
        opts.physicalHeight = max(eps, double(edtPhysicalHeight.Value));
        opts.targetPixelsPerUnit = max(0, double(edtTargetPixelsPerUnit.Value));
        opts.maxUpsamplePercent = max(0, double(edtMaxUpsamplePercent.Value));
    end

    function width = currentCropWidth()
        if strcmpi(currentScaleMode(), "Physical") && hasCurrentImage()
            cal = currentScaleCalibration();
            if batch_crop.state.isScaleCalibrationSet(cal)
                pixelsPerUnit = batch_crop.ops.pixelsPerUnitForUnit(cal, currentScaleUnit());
                width = max(1, round(double(edtPhysicalWidth.Value) * pixelsPerUnit));
                return;
            end
        end
        width = max(1, round(double(edtCropWidth.Value)));
    end

    function height = currentCropHeight()
        if strcmpi(currentScaleMode(), "Physical") && hasCurrentImage()
            cal = currentScaleCalibration();
            if batch_crop.state.isScaleCalibrationSet(cal)
                pixelsPerUnit = batch_crop.ops.pixelsPerUnitForUnit(cal, currentScaleUnit());
                height = max(1, round(double(edtPhysicalHeight.Value) * pixelsPerUnit));
                return;
            end
        end
        height = max(1, round(double(edtCropHeight.Value)));
    end

    function mode = currentScaleMode()
        mode = string(ddScaleMode.Value);
    end

    function unitName = currentScaleUnit()
        unitName = string(ddScaleUnit.Value);
    end

    function cal = currentScaleCalibration()
        cal = [];
        if hasCurrentImage() && isfield(S.items(S.currentIndex), 'scaleCalibration')
            cal = S.items(S.currentIndex).scaleCalibration;
        end
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
        key = batch_crop.state.canvasCacheKey(S.currentIndex, item, currentPaddingPercent());
        if S.canvasCache.valid && isequal(S.canvasCache.key, key)
            geometry = S.canvasCache.geometry;
            return;
        end

        geometry = batch_crop.ops.prepareCropCanvas(item.image, struct( ...
            'angleDeg', item.angleDeg, ...
            'paddingPercent', currentPaddingPercent()));
        S.canvasCache = struct('valid', true, 'key', key, 'geometry', geometry);
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
        item.centerXY = batch_crop.ops.clampCenterToSource(item.centerXY, ...
            item.image);
        S.items(S.currentIndex) = item;
    end

    function tf = hasCurrentImage()
        tf = ~isempty(S.items) && S.currentIndex >= 1 && S.currentIndex <= numel(S.items);
    end

    function refreshScaleTool()
        physicalMode = strcmpi(currentScaleMode(), "Physical");
        hasImage = hasCurrentImage();
        if scaleTool.isReferenceEditActive()
            scaleTool.setEnabled(struct( ...
                'hasImage', hasImage && physicalMode, ...
                'blockInputs', ~physicalMode, ...
                'blockPlacement', true));
            return;
        end
        if hasImage
            scaleTool.setCalibration(S.items(S.currentIndex).scaleCalibration);
            scaleTool.setImageSize(size(S.items(S.currentIndex).image));
        else
            scaleTool.setCalibration([]);
            scaleTool.setImageSize([]);
        end
        scaleTool.setEnabled(struct( ...
            'hasImage', hasImage && physicalMode, ...
            'blockInputs', ~physicalMode, ...
            'blockPlacement', true));
    end

    function refreshScaleStatus()
        txtScaleStatus.Value = batch_crop.view.scaleStatusText(S, S.currentIndex, currentScaleMode(), ...
            [edtPhysicalWidth.Value, edtPhysicalHeight.Value], currentScaleUnit());
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
