% Expected caller: labkit_ImageEnhance_app. Input is the debug context
% prepared by the public launcher. Output is the app figure. Side effects are
% GUI creation, user-driven image loading, image export, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the Image Enhance app body.

    S = struct();
    S.items = repmat(image_enhance.state.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
    S.batchMode = true;
    S.outputFolder = string(labkit.ui.app.defaultDialogFolder("output"));
    S.lastExport = [];
    S.lastExportFingerprint = "";
    S.pendingDirty = false;
    S.previewImages = {};
    S.previewImageKeys = strings(0, 1);
    S.previewScales = [];
    S.previewResultImage = [];
    S.previewResultKey = "";
    S.whiteRoiHandle = [];
    S.whiteRoiListener = [];

    stepKinds = {'Brightness/contrast', 'Local contrast', 'Sharpen', ...
        'Hue/saturation', 'White balance', 'White ROI calibration'};
    callbacks = struct( ...
        'sourceImagesChosen', @onSourceImagesChosen, ...
        'removeImages', @onRemoveImages, ...
        'clearImages', @onClearImages, ...
        'imageSelectionChanged', @onImageSelectionChanged, ...
        'batchModeChanged', @onBatchModeChanged, ...
        'previewModeChanged', @onPreviewModeChanged, ...
        'toolChanged', @onToolChanged, ...
        'toolSettingChanged', @onToolSettingChanged, ...
        'setWhiteRoi', @onSetWhiteRoi, ...
        'applyTool', @onApplyTool, ...
        'undoHistory', @onUndoHistory, ...
        'resetHistory', @onResetHistory, ...
        'chooseOutputFolder', @onChooseOutputFolder, ...
        'exportImages', @onExportImages);
    spec = image_enhance.ui.buildSpec(stepKinds, char(S.outputFolder), callbacks);
    ui = labkit.ui.app.create(spec, 'debug', debugLog);
    fig = ui.figure;
    if debugLog.enabled
        debugLog.trace('Image enhance debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetPreviewAxes();
    updateToolControls(true);
    refreshAll();

    function onSourceImagesChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Image selection cancelled.');
            return;
        end
        try
            addLog(sprintf('Starting image import for %d selected path(s).', numel(paths)));
            S.items = readOrReuseImages(paths);
        catch ME
            showError('Could not load images', ME.message);
            refreshAll();
            return;
        end

        S.currentIndex = 1;
        S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
        S = image_enhance.state.setActivePendingDirty(S, false);
        invalidatePreviewCache();
        S.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
            paths, "image_enhance", S.outputFolder));
        markExportDirty();
        addLog(sprintf('Loaded %d image(s).', numel(S.items)));
        refreshAll();
    end

    function onClearImages(~, ~)
        S.items = repmat(image_enhance.state.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
        S = image_enhance.state.setActivePendingDirty(S, false);
        invalidatePreviewCache();
        markExportDirty();
        addLog('Cleared loaded images and enhancement history.');
        refreshAll();
    end

    function onRemoveImages(~, event)
        if isempty(S.items)
            return;
        end
        removeIdx = fileIndices(event.removedFiles, numel(S.items));
        if isempty(removeIdx)
            refreshAll();
            return;
        end
        S.items(removeIdx) = [];
        S.currentIndex = min(S.currentIndex, numel(S.items));
        if isempty(S.items)
            S.currentIndex = 0;
        end
        pendingDirty = image_enhance.state.activePendingDirty(S);
        invalidatePreviewCache();
        S = image_enhance.state.setActivePendingDirty(S, pendingDirty);
        markExportDirty();
        addLog(sprintf('Removed image file(s); %d remaining.', numel(S.items)));
        refreshAll();
    end

    function onImageSelectionChanged(~, event)
        if isempty(S.items)
            return;
        end
        idx = fileIndices(event.selectedFiles, numel(S.items));
        if isempty(idx)
            return;
        end
        S.currentIndex = idx(1);
        refreshSelection();
        refreshHistory();
        refreshPreview();
        refreshMetrics();
        refreshDetails();
        refreshToolStatus();
    end

    function onPreviewModeChanged(~, ~)
        refreshPreview();
    end

    function onBatchModeChanged(~, ~)
        S.batchMode = logical(labkit.ui.view.getValue(ui, 'batchMode'));
        S = image_enhance.state.setActivePendingDirty(S, false);
        invalidatePreviewCache();
        markExportDirty();
        refreshAll();
    end

    function onToolChanged(~, ~)
        updateToolControls(true);
        S = image_enhance.state.setActivePendingDirty(S, true);
        markExportDirty();
        refreshPreview();
        refreshToolStatus();
    end

    function onToolSettingChanged(~, ~)
        updateToolControls(false);
        S = image_enhance.state.setActivePendingDirty(S, true);
        markExportDirty();
        refreshPreview();
        refreshToolStatus();
    end

    function onApplyTool(~, ~)
        if isempty(S.items)
            showError('No images loaded', 'Load images before applying enhancement tools.');
            return;
        end
        availability = currentToolAvailability();
        if ~availability.canApply
            showError('White ROI missing', ...
                'Switch off batch mode and set a white ROI for this image before applying.');
            return;
        end
        step = currentToolStep();
        steps = image_enhance.state.activeSteps(S);
        steps(end + 1, 1) = step;
        S = image_enhance.state.setActiveSteps(S, steps);
        S = image_enhance.state.setActivePendingDirty(S, false);
        markExportDirty();
        addLog(sprintf('Applied tool: %s', char(step.label)));
        refreshAll();
    end

    function onUndoHistory(~, ~)
        steps = image_enhance.state.activeSteps(S);
        if isempty(steps)
            return;
        end
        removed = steps(end);
        steps(end) = [];
        S = image_enhance.state.setActiveSteps(S, steps);
        S = image_enhance.state.setActivePendingDirty(S, false);
        markExportDirty();
        addLog(sprintf('Undid history step: %s', char(removed.label)));
        refreshAll();
    end

    function onResetHistory(~, ~)
        if isempty(image_enhance.state.activeSteps(S))
            return;
        end
        S = image_enhance.state.setActiveSteps(S, repmat(image_enhance.state.emptyStep(), 0, 1));
        S = image_enhance.state.setActivePendingDirty(S, false);
        markExportDirty();
        addLog('Reset enhancement history.');
        refreshAll();
    end

    function onChooseOutputFolder(~, ~)
        folder = uigetdir(labkit.ui.app.defaultDialogFolder("output", S.outputFolder), ...
            'Select image enhancement export folder');
        if isequal(folder, 0)
            addLog('Export folder selection cancelled.');
            return;
        end
        S.outputFolder = string(folder);
        markExportDirty();
        refreshExportControls();
        refreshDetails();
    end

    function onExportImages(~, ~)
        if isempty(S.items)
            showError('No images loaded', 'Load images before exporting enhanced outputs.');
            return;
        end
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = labkit.ui.view.getValue(ui, 'exportFormat');
        opts.itemSteps = image_enhance.state.itemStepsForExport(S);
        task = image_enhance.state.exportTask(S.items, image_enhance.state.stepsForTask(S), opts);
        if ~isempty(S.lastExport) && S.lastExportFingerprint == task.fingerprint
            addLog('Enhanced export is already up to date; skipped duplicate write.');
            refreshDetails();
            return;
        end
        try
            S.lastExport = image_enhance.export.writeOutputs(S.items, image_enhance.state.stepsForTask(S), opts);
            S.lastExportFingerprint = task.fingerprint;
        catch ME
            showError('Export failed', ME.message);
            return;
        end
        statuses = string({S.lastExport.results.status});
        addLog(sprintf('Exported %d image(s), %d failed. Manifest: %s', ...
            sum(statuses == "saved"), sum(statuses == "failed"), ...
            char(S.lastExport.manifestPath)));
        refreshDetails();
    end

    function refreshAll()
        refreshSourceLibrary();
        updateToolControls(false);
        refreshControls();
        refreshSelection();
        refreshHistory();
        refreshPreview();
        refreshMetrics();
        refreshDetails();
        refreshToolStatus();
        refreshExportControls();
    end

    function refreshSourceLibrary()
        if isempty(S.items)
            labkit.ui.view.setValue(ui, 'sourceImages', {});
            labkit.ui.view.setValue(ui, 'imageStatus', 'Images: 0');
            labkit.ui.view.setValue(ui, 'batchModeStatus', image_enhance.state.modeStatusText(S));
            return;
        end
        paths = cellstr(string({S.items.path}));
        labkit.ui.view.setValue(ui, 'sourceImages', paths);
        labkit.ui.view.setValue(ui, 'imageStatus', sprintf( ...
            'Images: %d | current steps: %d', numel(S.items), numel(image_enhance.state.activeSteps(S))));
        labkit.ui.view.setValue(ui, 'batchModeStatus', image_enhance.state.modeStatusText(S));
    end

    function refreshSelection()
        if isempty(S.items)
            return;
        end
        files = labkit.ui.view.getFiles(ui, 'sourceImages');
        labkit.ui.view.setFileSelection( ...
            ui, 'sourceImages', files(currentSelectionIndex()));
    end

    function refreshControls()
        hasImages = ~isempty(S.items);
        hasSteps = ~isempty(image_enhance.state.activeSteps(S));
        availability = currentToolAvailability();
        ui.controls.sourceImages.clearButton.Enable = image_enhance.ui.onOff(hasImages);
        ui.controls.sourceImages.listbox.Enable = image_enhance.ui.onOff(hasImages);
        labkit.ui.view.setEnabled(ui, 'applyTool', availability.canApply);
        labkit.ui.view.setEnabled(ui, 'setWhiteRoi', availability.canSetWhiteRoi);
        labkit.ui.view.setEnabled(ui, 'undoHistory', hasSteps);
        labkit.ui.view.setEnabled(ui, 'resetHistory', hasSteps);
        labkit.ui.view.setEnabled(ui, 'exportImages', hasImages);
    end

    function refreshExportControls()
        labkit.ui.view.setValue(ui, 'outputFolder', char(S.outputFolder));
    end

    function refreshPreview()
        if isempty(S.items)
            resetPreviewAxes();
            return;
        end
        original = currentPreviewSourceImage();
        switch string(labkit.ui.view.getValue(ui, 'preview'))
            case 'Original'
                labkit.ui.view.drawImage(ui, 'preview', original, ...
                    'title', 'Original Preview');
                refreshWhiteRoiOverlay();
            case 'Before | After'
                enhanced = currentPreviewImage(image_enhance.state.activePendingDirty(S));
                labkit.ui.view.drawImage(ui, 'preview', ...
                    image_enhance.view.beforeAfterImage(original, enhanced), ...
                    'title', 'Before | After');
                clearWhiteRoiOverlay();
            otherwise
                enhanced = currentPreviewImage(image_enhance.state.activePendingDirty(S));
                labkit.ui.view.drawImage(ui, 'preview', enhanced, ...
                    'title', 'Enhanced Preview');
                refreshWhiteRoiOverlay();
        end
    end

    function refreshMetrics()
        if isempty(S.items)
            ui.controls.metricsTable.table.Data = ...
                image_enhance.view.resultTableData([], [], 0);
            return;
        end
        processedImage = currentPreviewImage(false);
        ui.controls.metricsTable.table.Data = image_enhance.view.resultTableData( ...
            S.items(currentSelectionIndex()), ...
            processedImage, numel(image_enhance.state.activeSteps(S)));
    end

    function refreshHistory()
        ui.controls.historyTable.table.Data = image_enhance.view.historyTableData(image_enhance.state.activeSteps(S));
        labkit.ui.view.setValue(ui, 'historyStatus', ...
            sprintf('History steps: %d', numel(image_enhance.state.activeSteps(S))));
    end

    function refreshDetails()
        labkit.ui.view.setValue(ui, 'exportDetails', image_enhance.view.detailLines( ...
            S.items, max(currentSelectionIndex(), 1), image_enhance.state.activeSteps(S), S.lastExport));
    end

    function refreshToolStatus()
        if isempty(S.items)
            labkit.ui.view.setValue(ui, 'toolStatus', ...
                'Select an image, choose a tool, then apply it to history.');
            return;
        end
        availability = currentToolAvailability();
        step = currentToolStep();
        if availability.isWhiteRoi
            labkit.ui.view.setValue(ui, 'toolStatus', availability.status);
            return;
        end
        if image_enhance.state.activePendingDirty(S)
            prefix = 'Previewing: ';
        else
            prefix = 'Ready: ';
        end
        labkit.ui.view.setValue(ui, 'toolStatus', ...
            [prefix char(step.label) ' | ' availability.status]);
    end

    function items = readOrReuseImages(paths)
        paths = image_enhance.io.normalizeAppPaths(paths);
        template = image_enhance.state.emptyItem();
        items = repmat(template, numel(paths), 1);
        existingPaths = strings(0, 1);
        if ~isempty(S.items)
            existingPaths = string({S.items.path}).';
        end
        missing = paths(~ismember(paths, existingPaths));
        addLog(sprintf('Image import will read %d new file(s) and reuse %d loaded file(s).', ...
            numel(missing), numel(paths) - numel(missing)));
        loaded = image_enhance.io.readImages(missing, struct( ...
            'progressFcn', @onReadProgress));
        for k = 1:numel(paths)
            existingIndex = find(existingPaths == paths(k), 1);
            if ~isempty(existingIndex)
                addLog(sprintf('Reusing image %d/%d: %s', ...
                    k, numel(paths), char(image_enhance.io.displayName(paths(k)))));
                items(k) = S.items(existingIndex);
                continue;
            end
            loadedIndex = find(string({loaded.path}) == paths(k), 1);
            if ~isempty(loadedIndex)
                items(k) = loaded(loadedIndex);
            end
        end
    end

    function onReadProgress(progress)
        switch string(progress.stage)
            case "beforeRead"
                addLog(sprintf('Reading image %d/%d: %s', ...
                    progress.index, progress.count, char(progress.name)));
            case "afterRead"
                addLog(sprintf('Finished image %d/%d: %s', ...
                    progress.index, progress.count, char(progress.name)));
        end
    end

    function idx = fileIndices(files, itemCount)
        idx = zeros(numel(files), 1);
        for k = 1:numel(files)
            if isfield(files(k), 'index')
                indexValue = double(files(k).index);
                if isscalar(indexValue) && isfinite(indexValue)
                    idx(k) = indexValue;
                    continue;
                end
            end
            if isfield(files(k), 'id')
                token = regexp(char(string(files(k).id)), '^file(\d+)$', ...
                    'tokens', 'once');
                if ~isempty(token)
                    idx(k) = str2double(token{1});
                end
            end
        end
        idx = unique(idx(idx >= 1 & idx <= itemCount), 'stable');
    end

    function imageOut = currentPreviewSourceImage()
        if isempty(S.items)
            imageOut = [];
            return;
        end
        index = currentSelectionIndex();
        if numel(S.previewImages) ~= numel(S.items)
            S.previewImages = cell(numel(S.items), 1);
            S.previewImageKeys = strings(numel(S.items), 1);
            S.previewScales = ones(numel(S.items), 1);
        end
        item = S.items(index);
        key = previewImageKey(item);
        if isempty(S.previewImages{index}) || S.previewImageKeys(index) ~= key
            [previewImage, previewScale] = image_enhance.view.previewImage(item.image);
            S.previewImages{index} = previewImage;
            S.previewScales(index) = previewScale;
            S.previewImageKeys(index) = key;
        end
        imageOut = S.previewImages{index};
    end

    function imageOut = currentPreviewImage(includePending)
        imageOut = currentPreviewSourceImage();
        previewScale = currentPreviewScale();
        steps = previewScaledSteps(image_enhance.state.activeSteps(S), previewScale);
        stepsForKey = steps;
        if includePending && currentToolAvailability().canPreviewPending
            stepsForKey(end + 1, 1) = previewScaledStep(currentToolStep(), previewScale);
        end
        key = currentPreviewResultKey(stepsForKey, includePending);
        if ~isempty(S.previewResultImage) && S.previewResultKey == key
            imageOut = S.previewResultImage;
            return;
        end
        if ~isempty(steps)
            imageOut = image_enhance.ops.applyPipeline( ...
                {imageOut}, steps, {image_enhance.ui.whiteRoiHelpers("context", S.items(currentSelectionIndex()), currentPreviewScale())});
            imageOut = imageOut{1};
        end
        if includePending && currentToolAvailability().canPreviewPending
            imageOut = image_enhance.ops.applyStep( ...
                imageOut, previewScaledStep(currentToolStep(), previewScale), ...
                image_enhance.ui.whiteRoiHelpers("context", S.items(currentSelectionIndex()), currentPreviewScale()));
        end
        S.previewResultImage = imageOut;
        S.previewResultKey = key;
    end

    function invalidatePreviewCache()
        S.previewImages = {};
        S.previewImageKeys = strings(0, 1);
        S.previewScales = [];
        S.previewResultImage = [];
        S.previewResultKey = "";
    end

    function key = currentPreviewResultKey(stepsForKey, includePending)
        item = S.items(currentSelectionIndex());
        task = image_enhance.state.exportTask(item, stepsForKey, struct( ...
            'outputFolder', "preview", ...
            'format', "display"));
        key = task.fingerprint + sprintf('\n') + ...
            "scale=" + string(currentPreviewScale()) + ...
            "|pending=" + string(logical(includePending));
    end

    function markExportDirty()
        S.lastExport = [];
        S.lastExportFingerprint = "";
        S.previewResultImage = [];
        S.previewResultKey = "";
    end

    function scale = currentPreviewScale()
        index = currentSelectionIndex();
        if isempty(S.previewScales) || numel(S.previewScales) < index
            scale = 1;
            return;
        end
        scale = S.previewScales(index);
        if ~isfinite(scale) || scale <= 0
            scale = 1;
        end
    end

    function steps = previewScaledSteps(steps, scale)
        for iStep = 1:numel(steps)
            steps(iStep) = previewScaledStep(steps(iStep), scale);
        end
    end

    function step = previewScaledStep(step, scale)
        switch lower(regexprep(char(string(step.kind)), '[^a-zA-Z0-9]', ''))
            case {'localcontrast', 'sharpen'}
                step.secondary = step.secondary .* scale;
        end
    end

    function key = previewImageKey(item)
        dims = strjoin(string(size(item.image)), "x");
        key = strjoin([string(item.path), dims, string(class(item.image))], "|");
    end

    function step = currentToolStep()
        step = image_enhance.ops.makeStep( ...
            labkit.ui.view.getValue(ui, 'toolKind'), ...
            labkit.ui.view.getValue(ui, 'toolAmount'), ...
            labkit.ui.view.getValue(ui, 'toolSecondary'), 0);
    end

    function onSetWhiteRoi(~, ~)
        if isempty(S.items) || S.batchMode
            showError('White ROI unavailable', ...
                'White ROI calibration uses per-image mode only.');
            return;
        end
        clearWhiteRoiOverlay();
        position = image_enhance.ui.whiteRoiHelpers("defaultPosition", size(currentPreviewSourceImage()));
        if image_enhance.ui.whiteRoiHelpers("hasRoi", S.items(currentSelectionIndex()))
            position = S.items(currentSelectionIndex()).whiteRoi .* currentPreviewScale();
        end
        S.whiteRoiHandle = drawrectangle(ui.controls.preview.primaryAxes, ...
            'Position', position, 'Color', [1 1 1], 'StripeColor', [0 0 0]);
        S.whiteRoiListener = addlistener(S.whiteRoiHandle, 'ROIMoved', ...
            @(~, event) storeWhiteRoi(event.CurrentPosition));
        storeWhiteRoi(S.whiteRoiHandle.Position);
    end

    function availability = currentToolAvailability()
        availability = image_enhance.ui.toolAvailability( ...
            S, labkit.ui.view.getValue(ui, 'toolKind'));
    end

    function storeWhiteRoi(position)
        if isempty(S.items)
            return;
        end
        S.items(currentSelectionIndex()).whiteRoi = double(position) ./ currentPreviewScale();
        markExportDirty();
        S = image_enhance.state.setActivePendingDirty(S, true);
        refreshControls();
        refreshPreview();
        refreshToolStatus();
    end

    function refreshWhiteRoiOverlay()
        if ~image_enhance.ui.whiteRoiHelpers("isTool", labkit.ui.view.getValue(ui, 'toolKind')) || S.batchMode || ~image_enhance.ui.whiteRoiHelpers("hasRoi", S.items(currentSelectionIndex()))
            clearWhiteRoiOverlay();
            return;
        end
        if isempty(S.whiteRoiHandle) || ~isvalid(S.whiteRoiHandle)
            S.whiteRoiHandle = drawrectangle(ui.controls.preview.primaryAxes, ...
                'Position', S.items(currentSelectionIndex()).whiteRoi .* currentPreviewScale(), ...
                'Color', [1 1 1], 'StripeColor', [0 0 0]);
            S.whiteRoiListener = addlistener(S.whiteRoiHandle, 'ROIMoved', ...
                @(~, event) storeWhiteRoi(event.CurrentPosition));
        end
    end

    function clearWhiteRoiOverlay()
        if ~isempty(S.whiteRoiListener)
            delete(S.whiteRoiListener);
            S.whiteRoiListener = [];
        end
        if ~isempty(S.whiteRoiHandle) && isvalid(S.whiteRoiHandle)
            delete(S.whiteRoiHandle);
        end
        S.whiteRoiHandle = [];
    end

    function updateToolControls(resetToDefaults)
        values = image_enhance.ops.defaultStepValues( ...
            labkit.ui.view.getValue(ui, 'toolKind'));
        amountHandle = ui.controls.toolAmount.handle;
        secondaryHandle = ui.controls.toolSecondary.handle;
        ui.controls.toolAmount.label.Text = char(values.amountLabel);
        ui.controls.toolSecondary.label.Text = char(values.secondaryLabel);
        amountHandle.Limits = values.amountLimits;
        secondaryHandle.Limits = values.secondaryLimits;
        amountHandle.Value = image_enhance.state.clampValue( ...
            amountHandle.Value, values.amountLimits);
        secondaryHandle.Value = image_enhance.state.clampValue( ...
            secondaryHandle.Value, values.secondaryLimits);
        if resetToDefaults
            labkit.ui.view.setValue(ui, 'toolAmount', values.amount);
            labkit.ui.view.setValue(ui, 'toolSecondary', values.secondary);
        end
    end

    function index = currentSelectionIndex()
        if isempty(S.items)
            index = 0;
            return;
        end
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        index = S.currentIndex;
    end

    function resetPreviewAxes()
        labkit.ui.view.resetAxes(ui, 'preview', 'Enhanced Preview', true);
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'logPanel', message);
        if debugLog.enabled
            debugLog.append(message);
        end
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        uialert(fig, message, titleText);
    end
end
