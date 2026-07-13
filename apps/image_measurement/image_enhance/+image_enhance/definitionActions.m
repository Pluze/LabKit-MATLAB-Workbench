% App-owned action table for Image Enhance. Expected caller is
% image_enhance.definition. Output maps semantic action ids to handlers used
% by labkit.ui.runtime.run. Handlers preserve the enhancement workflow while
% moving package-root lifecycle orchestration into the framework runtime.
function actions = definitionActions()
%DEFINITIONACTIONS Build the Image Enhance runtime action map.
    S = [];
    ui = [];
    fig = [];
    debugLog = [];
    imageRuntime = [];
    actions = struct( ...
        'startup', @onStartup, ...
        'sourceImagesChosen', @dispatchSourceImagesChosen, ...
        'removeImages', @dispatchRemoveImages, ...
        'clearImages', @dispatchClearImages, ...
        'imageSelectionChanged', @dispatchImageSelectionChanged, ...
        'batchModeChanged', @dispatchBatchModeChanged, ...
        'previewModeChanged', @dispatchPreviewModeChanged, ...
        'toolChanged', @dispatchToolChanged, ...
        'toolSettingChanged', @dispatchToolSettingChanged, ...
        'setWhiteRoi', @dispatchSetWhiteRoi, ...
        'applyTool', @dispatchApplyTool, ...
        'undoHistory', @dispatchUndoHistory, ...
        'resetHistory', @dispatchResetHistory, ...
        'chooseOutputFolder', @dispatchChooseOutputFolder, ...
        'exportImages', @dispatchExportImages);
    function state = onStartup(state, ~, services)
        S = state;
        ui = services.ui;
        fig = services.figure;
        debugLog = services.debug;
        imageRuntime = labkit.ui.interaction.runtime( ...
            ui.controls.preview.primaryAxes, struct('figure', fig));
        if debugLog.enabled
            debugLog.trace('Image enhance debug trace enabled.');
            debugLog.instrumentFigure(fig);
            image_enhance.debug.writeAndLogSamplePack(debugLog, @addLog);
        end
        resetPreviewAxes();
        updateToolControls(true);
        refreshAll();
        state = S;
    end
    function state = dispatchWithEvent(state, payload, callback)
        S = state;
        callback([], payload.event);
        state = S;
    end
    function state = dispatchNoEvent(state, ~, callback)
        S = state;
        callback([], []);
        state = S;
    end
    function state = dispatchSourceImagesChosen(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onSourceImagesChosen);
    end
    function state = dispatchRemoveImages(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onRemoveImages);
    end
    function state = dispatchClearImages(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onClearImages);
    end
    function state = dispatchImageSelectionChanged(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onImageSelectionChanged);
    end
    function state = dispatchBatchModeChanged(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onBatchModeChanged);
    end
    function state = dispatchPreviewModeChanged(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onPreviewModeChanged);
    end
    function state = dispatchToolChanged(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onToolChanged);
    end
    function state = dispatchToolSettingChanged(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onToolSettingChanged);
    end
    function state = dispatchSetWhiteRoi(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onSetWhiteRoi);
    end
    function state = dispatchApplyTool(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onApplyTool);
    end
    function state = dispatchUndoHistory(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onUndoHistory);
    end
    function state = dispatchResetHistory(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onResetHistory);
    end
    function state = dispatchChooseOutputFolder(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onChooseOutputFolder);
    end
    function state = dispatchExportImages(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onExportImages);
    end
    function onSourceImagesChosen(~, event)
        newFiles = labkit.ui.control.filePaths(event.addedFiles);
        if isempty(newFiles)
            addLog('Image selection cancelled.');
            return;
        end
        paths = labkit.ui.control.filePaths(event.files);
        if isempty(paths)
            paths = newFiles;
        end
        try
            addLog(sprintf('Starting image import for %d selected path(s).', numel(newFiles)));
            S.items = readOrReuseImages(paths);
        catch ME
            showException('Could not load images', ME);
            refreshAll();
            return;
        end
        S.currentIndex = currentIndexForAddedPath(paths, newFiles(1));
        S.steps = repmat(image_enhance.appState.emptyStep(), 0, 1);
        S = image_enhance.appState.setActivePendingDirty(S, false);
        invalidatePreviewCache();
        S.outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
            paths, "image_enhance", S.outputFolder));
        markExportDirty();
        addLog(sprintf('Loaded %d image(s).', numel(S.items)));
        refreshAll();
    end
    function onClearImages(~, ~)
        S.items = repmat(image_enhance.appState.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.steps = repmat(image_enhance.appState.emptyStep(), 0, 1);
        S = image_enhance.appState.setActivePendingDirty(S, false);
        invalidatePreviewCache();
        markExportDirty();
        addLog('Cleared loaded images and enhancement history.');
        refreshAll();
    end
    function onRemoveImages(~, event)
        if isempty(S.items)
            return;
        end
        removeIdx = labkit.ui.control.fileIndices(event.removedFiles, numel(S.items));
        if isempty(removeIdx)
            refreshAll();
            return;
        end
        S.items(removeIdx) = [];
        S.currentIndex = min(S.currentIndex, numel(S.items));
        if isempty(S.items)
            S.currentIndex = 0;
        end
        pendingDirty = image_enhance.appState.activePendingDirty(S);
        invalidatePreviewCache();
        S = image_enhance.appState.setActivePendingDirty(S, pendingDirty);
        markExportDirty();
        addLog(sprintf('Removed image file(s); %d remaining.', numel(S.items)));
        refreshAll();
    end
    function onImageSelectionChanged(~, event)
        if isempty(S.items)
            return;
        end
        idx = labkit.ui.control.fileIndices(event.selectedFiles, numel(S.items));
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
    function onBatchModeChanged(~, event)
        S.batchMode = logical(event.value);
        S = image_enhance.appState.setActivePendingDirty(S, false);
        invalidatePreviewCache();
        markExportDirty();
        refreshAll();
    end
    function onToolChanged(~, ~)
        updateToolControls(true);
        S = image_enhance.appState.setActivePendingDirty(S, true);
        markExportDirty();
        refreshPreview();
        refreshControls();
        refreshToolStatus();
    end
    function onToolSettingChanged(~, ~)
        updateToolControls(false);
        S = image_enhance.appState.setActivePendingDirty(S, true);
        markExportDirty();
        refreshPreview();
        refreshControls();
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
        steps = image_enhance.appState.activeSteps(S);
        steps(end + 1, 1) = step;
        S = image_enhance.appState.setActiveSteps(S, steps);
        S = image_enhance.appState.setActivePendingDirty(S, false);
        markExportDirty();
        addLog(sprintf('Applied tool: %s', char(step.label)));
        refreshAll();
    end
    function onUndoHistory(~, ~)
        steps = image_enhance.appState.activeSteps(S);
        if isempty(steps)
            return;
        end
        removed = steps(end);
        steps(end) = [];
        S = image_enhance.appState.setActiveSteps(S, steps);
        S = image_enhance.appState.setActivePendingDirty(S, false);
        markExportDirty();
        addLog(sprintf('Undid history step: %s', char(removed.label)));
        refreshAll();
    end
    function onResetHistory(~, ~)
        if isempty(image_enhance.appState.activeSteps(S))
            return;
        end
        S = image_enhance.appState.setActiveSteps(S, repmat(image_enhance.appState.emptyStep(), 0, 1));
        S = image_enhance.appState.setActivePendingDirty(S, false);
        markExportDirty();
        addLog('Reset enhancement history.');
        refreshAll();
    end
    function onChooseOutputFolder(~, ~)
        [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
            'Select image enhancement export folder', S.outputFolder);
        if cancelled
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
        [task, opts, steps] = currentExportTask();
        if ~isempty(S.lastExport) && S.lastExportFingerprint == task.fingerprint
            addLog('Enhanced export is already up to date; skipped duplicate write.');
            refreshDetails();
            return;
        end
        try
            S.lastExport = image_enhance.resultFiles.writeOutputs(S.items, steps, opts);
            S.lastExportFingerprint = task.fingerprint;
        catch ME
            showException('Export failed', ME);
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
            labkit.ui.control.setValue(ui, 'sourceImages', {});
            labkit.ui.control.setValue(ui, 'imageStatus', 'Images: 0');
            labkit.ui.control.setValue(ui, 'batchModeStatus', image_enhance.appState.modeStatusText(S));
            return;
        end
        paths = cellstr(string({S.items.path}));
        labkit.ui.control.setValue(ui, 'sourceImages', paths);
        labkit.ui.control.setValue(ui, 'imageStatus', sprintf( ...
            'Images: %d | current steps: %d', numel(S.items), numel(image_enhance.appState.activeSteps(S))));
        labkit.ui.control.setValue(ui, 'batchModeStatus', image_enhance.appState.modeStatusText(S));
    end
    function refreshSelection()
        if isempty(S.items)
            return;
        end
        files = labkit.ui.control.getFiles(ui, 'sourceImages');
        labkit.ui.control.setFileSelection( ...
            ui, 'sourceImages', files(currentSelectionIndex()));
    end
    function refreshControls()
        hasImages = ~isempty(S.items);
        hasSteps = ~isempty(image_enhance.appState.activeSteps(S));
        availability = currentToolAvailability();
        ui.controls.sourceImages.clearButton.Enable = image_enhance.userInterface.onOff(hasImages);
        ui.controls.sourceImages.listbox.Enable = image_enhance.userInterface.onOff(hasImages);
        labkit.ui.control.setEnabled(ui, 'applyTool', availability.canApply);
        labkit.ui.control.setEnabled(ui, 'setWhiteRoi', availability.canSetWhiteRoi);
        labkit.ui.control.setEnabled(ui, 'undoHistory', hasSteps);
        labkit.ui.control.setEnabled(ui, 'resetHistory', hasSteps);
        labkit.ui.control.setEnabled(ui, 'exportImages', hasImages);
    end
    function refreshExportControls()
        labkit.ui.control.setValue(ui, 'outputFolder', char(S.outputFolder));
    end
    function refreshPreview()
        if isempty(S.items)
            resetPreviewAxes();
            return;
        end
        original = currentPreviewSourceImage();
        switch string(labkit.ui.control.getValue(ui, 'preview'))
            case 'Original'
                labkit.ui.plot.image(ui, 'preview', original, ...
                    'title', 'Original Preview');
                refreshWhiteRoiOverlay();
            case 'Before | After'
                enhanced = currentPreviewImage(image_enhance.appState.activePendingDirty(S));
                labkit.ui.plot.image(ui, 'preview', ...
                    image_enhance.userInterface.beforeAfterImage(original, enhanced), ...
                    'title', 'Before | After');
                clearWhiteRoiOverlay();
            otherwise
                enhanced = currentPreviewImage(image_enhance.appState.activePendingDirty(S));
                labkit.ui.plot.image(ui, 'preview', enhanced, ...
                    'title', 'Enhanced Preview');
                refreshWhiteRoiOverlay();
        end
    end
    function refreshMetrics()
        if isempty(S.items)
            ui.controls.metricsTable.table.Data = ...
                image_enhance.userInterface.resultTableData([], [], 0);
            return;
        end
        processedImage = currentPreviewImage(false);
        ui.controls.metricsTable.table.Data = image_enhance.userInterface.resultTableData( ...
            S.items(currentSelectionIndex()), ...
            processedImage, numel(image_enhance.appState.activeSteps(S)));
    end
    function refreshHistory()
        ui.controls.historyTable.table.Data = image_enhance.userInterface.historyTableData(image_enhance.appState.activeSteps(S));
        labkit.ui.control.setValue(ui, 'historyStatus', ...
            sprintf('History steps: %d', numel(image_enhance.appState.activeSteps(S))));
    end
    function refreshDetails()
        labkit.ui.control.setValue(ui, 'exportDetails', image_enhance.userInterface.detailLines( ...
            S.items, max(currentSelectionIndex(), 1), image_enhance.appState.activeSteps(S), S.lastExport));
    end
    function refreshToolStatus()
        if isempty(S.items)
            labkit.ui.control.setValue(ui, 'toolStatus', ...
                'Select an image, choose a tool, then apply it to history.');
            return;
        end
        availability = currentToolAvailability();
        step = currentToolStep();
        if availability.isWhiteRoi
            labkit.ui.control.setValue(ui, 'toolStatus', availability.status);
            return;
        end
        if image_enhance.appState.activePendingDirty(S)
            prefix = 'Previewing: ';
        else
            prefix = 'Ready: ';
        end
        labkit.ui.control.setValue(ui, 'toolStatus', ...
            [prefix char(step.label) ' | ' availability.status]);
    end
    function items = readOrReuseImages(paths)
        paths = labkit.image.normalizePaths(paths);
        template = image_enhance.appState.emptyItem();
        items = repmat(template, numel(paths), 1);
        existingPaths = strings(0, 1);
        if ~isempty(S.items)
            existingPaths = string({S.items.path}).';
        end
        missing = paths(~ismember(paths, existingPaths));
        addLog(sprintf('Image import will read %d new file(s) and reuse %d loaded file(s).', ...
            numel(missing), numel(paths) - numel(missing)));
        loaded = image_enhance.sourceFiles.readImages(missing, struct( ...
            'progressFcn', @onReadProgress));
        for k = 1:numel(paths)
            existingIndex = find(existingPaths == paths(k), 1);
            if ~isempty(existingIndex)
                addLog(sprintf('Reusing image %d/%d: %s', ...
                    k, numel(paths), char(labkit.image.displayName(paths(k)))));
                items(k) = S.items(existingIndex);
                continue;
            end
            loadedIndex = find(string({loaded.path}) == paths(k), 1);
            if ~isempty(loadedIndex)
                items(k) = loaded(loadedIndex);
            end
        end
    end
    function idx = currentIndexForAddedPath(paths, addedPath)
        idx = find(string(paths(:)) == string(addedPath), 1);
        if isempty(idx)
            idx = 1;
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
            [previewImage, previewScale] = image_enhance.userInterface.previewImage(item.image);
            S.previewImages{index} = previewImage;
            S.previewScales(index) = previewScale;
            S.previewImageKeys(index) = key;
        end
        imageOut = S.previewImages{index};
    end
    function imageOut = currentPreviewImage(includePending)
        imageOut = currentPreviewSourceImage();
        previewScale = currentPreviewScale();
        steps = previewScaledSteps(image_enhance.appState.activeSteps(S), previewScale);
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
            imageOut = image_enhance.analysisRun.applyPipeline( ...
                {imageOut}, steps, {image_enhance.userInterface.whiteRoiHelpers("context", S.items(currentSelectionIndex()), currentPreviewScale())});
            imageOut = imageOut{1};
        end
        if includePending && currentToolAvailability().canPreviewPending
            imageOut = image_enhance.analysisRun.applyStep( ...
                imageOut, previewScaledStep(currentToolStep(), previewScale), ...
                image_enhance.userInterface.whiteRoiHelpers("context", S.items(currentSelectionIndex()), currentPreviewScale()));
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
        task = image_enhance.appState.exportTask(item, stepsForKey, struct( ...
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
    function [task, opts, steps] = currentExportTask()
        opts = struct('outputFolder', S.outputFolder, ...
            'format', labkit.ui.control.getValue(ui, 'exportFormat'));
        [task, opts, steps] = image_enhance.appState.exportTask(S, opts);
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
        step = image_enhance.analysisRun.makeStep( ...
            labkit.ui.control.getValue(ui, 'toolKind'), ...
            labkit.ui.control.getValue(ui, 'toolAmount'), ...
            labkit.ui.control.getValue(ui, 'toolSecondary'), 0);
    end
    function onSetWhiteRoi(~, ~)
        if isempty(S.items) || S.batchMode
            showError('White ROI unavailable', ...
                'White ROI calibration uses per-image mode only.');
            return;
        end
        clearWhiteRoiOverlay();
        position = image_enhance.userInterface.whiteRoiHelpers("defaultPosition", size(currentPreviewSourceImage()));
        if image_enhance.userInterface.whiteRoiHelpers("hasRoi", S.items(currentSelectionIndex()))
            position = S.items(currentSelectionIndex()).whiteRoi .* currentPreviewScale();
        end
        S.whiteRoiHandle = createWhiteRoiEditor(position);
        storeWhiteRoi(S.whiteRoiHandle.getPosition());
    end
    function availability = currentToolAvailability()
        availability = image_enhance.userInterface.toolAvailability( ...
            S, labkit.ui.control.getValue(ui, 'toolKind'));
    end
    function storeWhiteRoi(position)
        if isempty(S.items)
            return;
        end
        S.items(currentSelectionIndex()).whiteRoi = double(position) ./ currentPreviewScale();
        markExportDirty();
        S = image_enhance.appState.setActivePendingDirty(S, true);
        refreshControls();
        refreshToolStatus();
    end
    function refreshWhiteRoiOverlay()
        if ~image_enhance.userInterface.whiteRoiHelpers("isTool", labkit.ui.control.getValue(ui, 'toolKind')) || S.batchMode || ~image_enhance.userInterface.whiteRoiHelpers("hasRoi", S.items(currentSelectionIndex()))
            clearWhiteRoiOverlay();
            return;
        end
        if isempty(S.whiteRoiHandle) || ~S.whiteRoiHandle.isValid()
            if ~isempty(S.whiteRoiHandle) && isstruct(S.whiteRoiHandle)
                S.whiteRoiHandle.delete();
            end
            S.whiteRoiHandle = createWhiteRoiEditor( ...
                S.items(currentSelectionIndex()).whiteRoi .* currentPreviewScale());
        end
    end
    function clearWhiteRoiOverlay()
        if ~isempty(S.whiteRoiHandle) && isstruct(S.whiteRoiHandle)
            S.whiteRoiHandle.delete();
        end
        S.whiteRoiHandle = [];
        S.whiteRoiListener = [];
    end
    function editor = createWhiteRoiEditor(position)
        editor = labkit.ui.interaction.rectangleEditor(imageRuntime, ...
            size(currentPreviewSourceImage()), position, struct( ...
            'color', [1 1 1], ...
            'onMoved', @storeWhiteRoi));
    end
    function updateToolControls(resetToDefaults)
        values = image_enhance.analysisRun.defaultStepValues( ...
            labkit.ui.control.getValue(ui, 'toolKind'));
        amountHandle = ui.controls.toolAmount.handle;
        secondaryHandle = ui.controls.toolSecondary.handle;
        ui.controls.toolAmount.label.Text = char(values.amountLabel);
        ui.controls.toolSecondary.label.Text = char(values.secondaryLabel);
        amountHandle.Limits = values.amountLimits;
        secondaryHandle.Limits = values.secondaryLimits;
        amountHandle.Value = image_enhance.appState.clampValue( ...
            amountHandle.Value, values.amountLimits);
        secondaryHandle.Value = image_enhance.appState.clampValue( ...
            secondaryHandle.Value, values.secondaryLimits);
        if resetToDefaults
            labkit.ui.control.setValue(ui, 'toolAmount', values.amount);
            labkit.ui.control.setValue(ui, 'toolSecondary', values.secondary);
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
        labkit.ui.plot.reset(ui, 'preview', 'Enhanced Preview', true);
    end
    function addLog(message)
        labkit.ui.control.appendLog(ui, 'logPanel', message);
        if debugLog.enabled
            debugLog.append(message);
        end
    end
    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        labkit.ui.runtime.showAlert(fig, message, titleText);
    end
    function showException(titleText, exception)
        if debugLog.enabled && isfield(debugLog, 'reportException')
            debugLog.reportException('imageEnhance', titleText, exception);
        end
        showError(titleText, exception.message);
    end
end
