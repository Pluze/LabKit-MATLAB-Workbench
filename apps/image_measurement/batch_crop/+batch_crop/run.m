% Expected caller: labkit_BatchImageCrop_app. Input is the debug context
% prepared by the public launcher. Output is the app figure. Side effects are
% GUI creation, user-driven image loading, crop export, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the Batch Image Crop app body.

    S = struct();
    S.items = repmat(batch_crop.state.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.outputFolder = string(pwd);
    S.lastExport = [];
    S.canvasCache = emptyCanvasCache();

    callbacks = struct( ...
        "imagesChosen", @onImagesChosen, ...
        "clearImages", @(~, ~) onClearImages(), ...
        "duplicateImage", @(~, ~) onDuplicateImage(), ...
        "imageSelectionChanged", @(~, ~) onImageSelectionChanged(), ...
        "previousImage", @(~, ~) onPreviousImage(), ...
        "nextImage", @(~, ~) onNextImage(), ...
        "cropGeometryChanged", @(~, ~) onCropGeometryChanged(), ...
        "rotationChanged", @(~, ~) onRotationChanged(), ...
        "paddingChanged", @(~, ~) onPaddingChanged(), ...
        "centerChanged", @(~, ~) onCenterChanged(), ...
        "useImageCenter", @(~, ~) onUseImageCenter(), ...
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

    btnOpenFiles = ui.controls.images.chooseButton;
    btnClearImages = ui.controls.images.clearButton;
    btnDuplicateImage = ui.controls.duplicateImage.button;
    txtImageSource = ui.controls.imageSource.valueHandle;
    lbImages = ui.controls.images.listbox;
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
        if isempty(event.paths)
            addLog('Image file selection cancelled.');
            return;
        end

        try
            items = readCropItems(event.paths);
        catch ME
            showError('Could not load images', ME.message);
            return;
        end

        S.items = items;
        S.currentIndex = 1;
        S.lastExport = [];
        S.canvasCache = emptyCanvasCache();
        addLog(sprintf('Loaded %d image(s).', numel(S.items)));
        refreshAll();
    end

    function onClearImages()
        S.items = repmat(batch_crop.state.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.lastExport = [];
        S.canvasCache = emptyCanvasCache();
        addLog('Cleared loaded images.');
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
        S.lastExport = [];
        S.canvasCache = emptyCanvasCache();
        addLog(sprintf('Duplicated image %d as crop task %d. Pick a new crop center.', ...
            insertAt - 1, insertAt));
        refreshAll();
    end

    function onImageSelectionChanged()
        if isempty(S.items)
            return;
        end
        items = batch_crop.view.listboxItems(S.items);
        idx = find(strcmp(items, lbImages.Value), 1);
        if isempty(idx)
            return;
        end
        S.currentIndex = idx;
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
        refreshPreview();
        refreshSummary();
    end

    function onRotationChanged()
        if ~hasCurrentImage()
            return;
        end
        S.items(S.currentIndex).angleDeg = edtRotation.Value;
        ensureCurrentCenter();
        S.canvasCache = emptyCanvasCache();
        addLog(sprintf('Updated rotation for image %d: %.3g deg.', ...
            S.currentIndex, S.items(S.currentIndex).angleDeg));
        refreshAll();
    end

    function onPaddingChanged()
        edtPaddingPercent.Value = min(max(double(edtPaddingPercent.Value), 0), 50);
        S.canvasCache = emptyCanvasCache();
        if hasCurrentImage()
            addLog(sprintf('Updated padding for image %d: %.3g%%.', ...
                S.currentIndex, edtPaddingPercent.Value));
        end
        refreshPreview();
        refreshSummary();
    end

    function onCenterChanged()
        if ~hasCurrentImage()
            return;
        end
        S.items(S.currentIndex).centerXY = [edtCenterX.Value, edtCenterY.Value];
        S.items(S.currentIndex).centerSet = true;
        addLog(sprintf('Set crop center for image %d: x=%.1f, y=%.1f.', ...
            S.currentIndex, edtCenterX.Value, edtCenterY.Value));
        refreshAll();
    end

    function onUseImageCenter()
        if ~hasCurrentImage()
            return;
        end
        S.items(S.currentIndex).centerXY = sourceCenterXY(S.items(S.currentIndex).image);
        S.items(S.currentIndex).centerSet = true;
        addLog(sprintf('Set image %d crop center to source image center.', ...
            S.currentIndex));
        refreshAll();
    end

    function onExportSettingChanged()
        refreshSummary();
    end

    function onChooseOutputFolder()
        folder = uigetdir(char(S.outputFolder), 'Select crop export folder');
        if isequal(folder, 0)
            addLog('Export folder selection cancelled.');
            return;
        end
        S.outputFolder = string(folder);
        txtOutputFolder.Value = char(S.outputFolder);
        refreshSummary();
    end

    function onPreviewPointerDown(~, ~)
        if ~hasCurrentImage()
            return;
        end
        geometry = currentGeometry();
        pt = previewAxes.CurrentPoint;
        x = min(max(pt(1, 1), 1), size(geometry.canvas, 2));
        y = min(max(pt(1, 2), 1), size(geometry.canvas, 1));
        centerXY = batch_crop.ops.canvasToOriginal(geometry, [x, y]);
        centerXY = clampToSource(centerXY, S.items(S.currentIndex).image);
        S.items(S.currentIndex).centerXY = centerXY;
        S.items(S.currentIndex).centerSet = true;
        addLog(sprintf('Picked crop center for image %d: x=%.1f, y=%.1f.', ...
            S.currentIndex, centerXY(1), centerXY(2)));
        refreshAll();
    end

    function onExportCrops()
        if isempty(S.items)
            showError('No images loaded', 'Load images before exporting crops.');
            return;
        end
        if ~all([S.items.centerSet])
            showError('Crop centers missing', ...
                'Set or confirm the crop center for every loaded image before exporting.');
            return;
        end

        opts = currentExportOptions();
        try
            payload = batch_crop.export.writeOutputs(S.items, opts);
        catch ME
            showError('Export failed', ME.message);
            return;
        end

        S.lastExport = payload;
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

    function refreshAll()
        refreshList();
        refreshControls();
        refreshPreview();
        refreshSummary();
    end

    function refreshList()
        if isempty(S.items)
            labkit.ui.view.setListItems(ui, 'images', {'No images loaded'});
            lbImages.Value = 'No images loaded';
            txtImageSource.Value = 'No images loaded';
            txtImageStatus.Value = 'Images: 0';
            return;
        end

        items = batch_crop.view.listboxItems(S.items);
        labkit.ui.view.setListItems(ui, 'images', items);
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        lbImages.Value = items{S.currentIndex};
        txtImageSource.Value = char(S.items(S.currentIndex).path);
        txtImageStatus.Value = sprintf('Images: %d | confirmed centers: %d', ...
            numel(S.items), countConfirmedCenters());
    end

    function refreshControls()
        hasImage = hasCurrentImage();
        enabled = ternary(hasImage, 'on', 'off');
        btnClearImages.Enable = enabled;
        btnDuplicateImage.Enable = enabled;
        btnPrevious.Enable = ternary(hasImage && S.currentIndex > 1, 'on', 'off');
        btnNext.Enable = ternary(hasImage && S.currentIndex < numel(S.items), 'on', 'off');
        edtRotation.Enable = enabled;
        edtPaddingPercent.Enable = enabled;
        edtCenterX.Enable = enabled;
        edtCenterY.Enable = enabled;
        btnUseImageCenter.Enable = enabled;

        if hasImage
            ensureCurrentCenter();
            item = S.items(S.currentIndex);
            edtRotation.Value = item.angleDeg;
            edtCenterX.Limits = [1, max(1, size(item.image, 2))];
            edtCenterY.Limits = [1, max(1, size(item.image, 1))];
            edtCenterX.Value = item.centerXY(1);
            edtCenterY.Value = item.centerXY(2);
        else
            edtRotation.Value = 0;
            edtPaddingPercent.Value = 12;
            edtCenterX.Limits = [1, Inf];
            edtCenterY.Limits = [1, Inf];
            edtCenterX.Value = 1;
            edtCenterY.Value = 1;
        end

        btnExport.Enable = ternary(hasImage && all([S.items.centerSet]), 'on', 'off');
    end

    function refreshPreview()
        if ~hasCurrentImage()
            resetPreviewAxes();
            cropSession.setBackground([]);
            cropSession.setGraphics([]);
            return;
        end

        ensureCurrentCenter();
        geometry = currentGeometry();
        hImage = labkit.ui.view.drawImage(ui, 'preview', geometry.canvas, ...
            "title", "Padded rotation preview + fixed crop", ...
            "axis", "crop");
        hold(previewAxes, 'on');
        item = S.items(S.currentIndex);
        cropWidth = currentCropWidth();
        cropHeight = currentCropHeight();
        canvasCenterXY = batch_crop.ops.originalToCanvas(geometry, item.centerXY);
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
        cropSession.setBackground(hImage);
        cropSession.setGraphics([hRect, hLineX, hLineY]);
        cropSession.activate();
    end

    function refreshSummary()
        resultTable.Data = batch_crop.view.summaryTableData(S, S.currentIndex, ...
            currentCropWidth(), currentCropHeight(), currentPaddingPercent(), ddFormat.Value);
        txtDetails.Value = batch_crop.view.detailLines(S, S.currentIndex, ...
            currentCropWidth(), currentCropHeight(), currentPaddingPercent());
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
    end

    function width = currentCropWidth()
        width = max(1, round(double(edtCropWidth.Value)));
    end

    function height = currentCropHeight()
        height = max(1, round(double(edtCropHeight.Value)));
    end

    function percent = currentPaddingPercent()
        percent = min(max(double(edtPaddingPercent.Value), 0), 50);
    end

    function geometry = currentGeometry()
        item = S.items(S.currentIndex);
        key = canvasCacheKey(S.currentIndex, item, currentPaddingPercent());
        if S.canvasCache.valid && isequal(S.canvasCache.key, key)
            geometry = S.canvasCache.geometry;
            return;
        end

        geometry = batch_crop.ops.prepareCropCanvas(item.image, struct( ...
            'angleDeg', item.angleDeg, ...
            'paddingPercent', currentPaddingPercent()));
        S.canvasCache = struct('valid', true, 'key', key, 'geometry', geometry);
    end

    function ensureCurrentCenter()
        if ~hasCurrentImage()
            return;
        end
        item = S.items(S.currentIndex);
        if isempty(item.centerXY) || any(~isfinite(item.centerXY))
            item.centerXY = sourceCenterXY(item.image);
        end
        item.centerXY = clampToSource(item.centerXY, item.image);
        S.items(S.currentIndex) = item;
    end

    function tf = hasCurrentImage()
        tf = ~isempty(S.items) && S.currentIndex >= 1 && S.currentIndex <= numel(S.items);
    end

    function count = countConfirmedCenters()
        if isempty(S.items)
            count = 0;
        else
            count = sum([S.items.centerSet]);
        end
    end

    function items = readCropItems(paths)
        items = batch_crop.state.readItems(paths);
    end

    function key = canvasCacheKey(index, item, paddingPercent)
        key = struct( ...
            'index', index, ...
            'path', item.path, ...
            'angleDeg', double(item.angleDeg), ...
            'paddingPercent', double(paddingPercent), ...
            'width', size(item.image, 2), ...
            'height', size(item.image, 1), ...
            'channels', size(item.image, 3), ...
            'className', string(class(item.image)));
    end

    function cache = emptyCanvasCache()
        cache = struct('valid', false, 'key', [], 'geometry', []);
    end

    function centerXY = sourceCenterXY(imageData)
        centerXY = [(size(imageData, 2) + 1) / 2, (size(imageData, 1) + 1) / 2];
    end

    function centerXY = clampToSource(centerXY, imageData)
        centerXY = double(centerXY(:)).';
        centerXY(1) = min(max(centerXY(1), 1), size(imageData, 2));
        centerXY(2) = min(max(centerXY(2), 1), size(imageData, 1));
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'appLog', message);
        if debugLog.enabled
            debugLog.append(message);
        end
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        uialert(fig, message, titleText);
    end

    function value = ternary(condition, trueValue, falseValue)
        if condition
            value = trueValue;
        else
            value = falseValue;
        end
    end
end
