% App-owned action table for Image Match. Expected caller is
% image_match.definition. Output maps semantic action ids to handlers used
% by labkit.ui.runtime.run. Handlers preserve the reference-match workflow while
% moving package-root lifecycle orchestration into the framework runtime.
function actions = definitionActions()
%DEFINITIONACTIONS Build the Image Match runtime action map.

    S = [];
    ui = [];
    fig = [];
    debugLog = [];

    actions = struct( ...
        'startup', @onStartup, ...
        'referenceImageChosen', @dispatchReferenceImageChosen, ...
        'clearReference', @dispatchClearReference, ...
        'sourceImagesChosen', @dispatchSourceImagesChosen, ...
        'removeImages', @dispatchRemoveImages, ...
        'clearImages', @dispatchClearImages, ...
        'imageSelectionChanged', @dispatchImageSelectionChanged, ...
        'previewModeChanged', @dispatchPreviewModeChanged, ...
        'matchSettingChanged', @dispatchMatchSettingChanged, ...
        'applyMatch', @dispatchApplyMatch, ...
        'undoHistory', @dispatchUndoHistory, ...
        'resetHistory', @dispatchResetHistory, ...
        'chooseOutputFolder', @dispatchChooseOutputFolder, ...
        'exportImages', @dispatchExportImages);

    function state = onStartup(state, ~, services)
        S = state;
        ui = services.ui;
        fig = services.figure;
        debugLog = services.debug;
        if debugLog.enabled
            debugLog.trace('Image match debug trace enabled.');
            debugLog.instrumentFigure(fig);
            setupDebugSamples();
        end

        resetPreviewAxes();
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

    function state = dispatchReferenceImageChosen(state, payload, ~)
        state = dispatchWithEvent(state, payload, @onReferenceImageChosen);
    end
    function state = dispatchClearReference(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onClearReference);
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
    function state = dispatchPreviewModeChanged(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onPreviewModeChanged);
    end
    function state = dispatchMatchSettingChanged(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onMatchSettingChanged);
    end
    function state = dispatchApplyMatch(state, payload, ~)
        state = dispatchNoEvent(state, payload, @onApplyMatch);
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

    function onReferenceImageChosen(~, event)
        paths = labkit.ui.control.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Reference image selection cancelled.');
            return;
        end
        try
            loaded = image_match.sourceFiles.readImages(paths(1));
        catch ME
            showException('Could not load reference image', ME);
            refreshAll();
            return;
        end

        S.referenceItem = loaded(1);
        S.pendingDirty = false;
        invalidatePreviewCache();
        markExportDirty();
        addLog(sprintf('Loaded reference image: %s.', char(S.referenceItem.name)));
        refreshAll();
    end

    function onClearReference(~, ~)
        S.referenceItem = [];
        S.pendingDirty = false;
        invalidatePreviewCache();
        markExportDirty();
        addLog('Cleared reference image.');
        refreshAll();
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
            S.items = readOrReuseImages(paths);
        catch ME
            showException('Could not load images', ME);
            refreshAll();
            return;
        end

        S.currentIndex = currentIndexForAddedPath(paths, newFiles(1));
        S.steps = repmat(image_match.appState.emptyStep(), 0, 1);
        S.pendingDirty = false;
        invalidatePreviewCache();
        S.outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
            paths, "image_match", S.outputFolder));
        markExportDirty();
        addLog(sprintf('Loaded %d image(s).', numel(S.items)));
        refreshAll();
    end

    function onClearImages(~, ~)
        S.items = repmat(image_match.appState.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.steps = repmat(image_match.appState.emptyStep(), 0, 1);
        S.pendingDirty = false;
        invalidatePreviewCache();
        markExportDirty();
        addLog('Cleared loaded images and match history.');
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
        pendingDirty = S.pendingDirty;
        invalidatePreviewCache();
        S.pendingDirty = pendingDirty;
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
        refreshPreview();
        refreshMetrics();
        refreshDetails();
    end

    function onPreviewModeChanged(~, ~)
        refreshPreview();
    end

    function onMatchSettingChanged(~, ~)
        S.pendingDirty = true;
        markExportDirty();
        refreshPreview();
        refreshMatchStatus();
    end

    function onApplyMatch(~, ~)
        if isempty(S.items)
            showError('No images loaded', 'Load images before applying reference matches.');
            return;
        end
        if ~hasReference()
            showError('No reference image', 'Load a reference image before applying matches.');
            return;
        end
        step = currentMatchStep();
        S.steps(end + 1, 1) = step;
        S.pendingDirty = false;
        markExportDirty();
        addLog(sprintf('Applied match: %s', char(step.label)));
        refreshAll();
    end

    function onUndoHistory(~, ~)
        if isempty(S.steps)
            return;
        end
        removed = S.steps(end);
        S.steps(end) = [];
        S.pendingDirty = false;
        markExportDirty();
        addLog(sprintf('Undid match step: %s', char(removed.label)));
        refreshAll();
    end

    function onResetHistory(~, ~)
        if isempty(S.steps)
            return;
        end
        S.steps = repmat(image_match.appState.emptyStep(), 0, 1);
        S.pendingDirty = false;
        markExportDirty();
        addLog('Reset match history.');
        refreshAll();
    end

    function onChooseOutputFolder(~, ~)
        [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
            'Select image match export folder', S.outputFolder);
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
            showError('No images loaded', 'Load images before exporting matched outputs.');
            return;
        end
        if ~hasReference()
            showError('No reference image', 'Load a reference image before exporting matched outputs.');
            return;
        end
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = labkit.ui.control.getValue(ui, 'exportFormat');
        task = image_match.appState.exportTask(S.items, S.referenceItem, S.steps, opts);
        if ~isempty(S.lastExport) && S.lastExportFingerprint == task.fingerprint
            addLog('Matched export is already up to date; skipped duplicate write.');
            refreshDetails();
            return;
        end
        try
            S.lastExport = image_match.resultFiles.writeOutputs( ...
                S.items, S.referenceItem, S.steps, opts);
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
        refreshReferenceLibrary();
        refreshSelection();
        refreshMatchControls();
        refreshExportControls();
        refreshHistory();
        refreshPreview();
        refreshMetrics();
        refreshDetails();
        refreshMatchStatus();
    end

    function refreshSourceLibrary()
        if isempty(S.items)
            labkit.ui.control.setValue(ui, 'sourceImages', {});
            labkit.ui.control.setValue(ui, 'imageStatus', 'Images: 0');
            return;
        end

        paths = cellstr(string({S.items.path}));
        labkit.ui.control.setValue(ui, 'sourceImages', paths);
        labkit.ui.control.setValue(ui, 'imageStatus', sprintf( ...
            'Images: %d | match steps: %d', numel(S.items), numel(S.steps)));
    end

    function refreshReferenceLibrary()
        if hasReference()
            labkit.ui.control.setValue(ui, 'referenceImage', ...
                cellstr(S.referenceItem.path));
        else
            labkit.ui.control.setValue(ui, 'referenceImage', {});
        end
    end

    function refreshSelection()
        if isempty(S.items)
            return;
        end
        files = labkit.ui.control.getFiles(ui, 'sourceImages');
        labkit.ui.control.setFileSelection( ...
            ui, 'sourceImages', files(currentSelectionIndex()));
    end

    function refreshMatchControls()
        hasImages = ~isempty(S.items);
        refLoaded = hasReference();
        hasSteps = ~isempty(S.steps);
        ui.controls.sourceImages.clearButton.Enable = onOff(hasImages);
        ui.controls.sourceImages.listbox.Enable = onOff(hasImages);
        labkit.ui.control.setEnabled(ui, 'applyMatch', hasImages && refLoaded);
        labkit.ui.control.setEnabled(ui, 'undoHistory', hasSteps);
        labkit.ui.control.setEnabled(ui, 'resetHistory', hasSteps);
        labkit.ui.control.setEnabled(ui, 'exportImages', hasImages && refLoaded);
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
        switch currentPreviewMode()
            case 'Original'
                labkit.ui.plot.image(ui, 'preview', original, ...
                    'title', 'Original Preview');
            case 'Before | After'
                matched = currentPreviewImage(S.pendingDirty);
                labkit.ui.plot.image(ui, 'preview', ...
                    image_match.userInterface.beforeAfterImage(original, matched), ...
                    'title', 'Before | After');
            otherwise
                matched = currentPreviewImage(S.pendingDirty);
                labkit.ui.plot.image(ui, 'preview', matched, ...
                    'title', 'Matched Preview');
        end
    end

    function refreshMetrics()
        if isempty(S.items)
            ui.controls.metricsTable.table.Data = ...
                image_match.userInterface.resultTableData([], [], 0);
            return;
        end
        processedImage = currentPreviewImage(false);
        ui.controls.metricsTable.table.Data = image_match.userInterface.resultTableData( ...
            S.items(currentSelectionIndex()), ...
            processedImage, numel(S.steps));
    end

    function refreshHistory()
        ui.controls.historyTable.table.Data = image_match.userInterface.historyTableData(S.steps);
        labkit.ui.control.setValue(ui, 'historyStatus', ...
            sprintf('History steps: %d', numel(S.steps)));
    end

    function refreshDetails()
        labkit.ui.control.setValue(ui, 'exportDetails', image_match.userInterface.detailLines( ...
            S.items, max(currentSelectionIndex(), 1), S.referenceItem, ...
            S.steps, S.lastExport));
    end

    function refreshMatchStatus()
        labkit.ui.control.setValue(ui, 'matchFlow', ...
            image_match.userInterface.matchFlowLines(labkit.ui.control.getValue(ui, 'matchMethod')));
    end

    function items = readOrReuseImages(paths)
        paths = string(paths(:));
        template = image_match.appState.emptyItem();
        items = repmat(template, numel(paths), 1);
        existingPaths = strings(0, 1);
        if ~isempty(S.items)
            existingPaths = string({S.items.path}).';
        end
        missing = paths(~ismember(paths, existingPaths));
        loaded = image_match.sourceFiles.readImages(missing);
        for k = 1:numel(paths)
            existingIndex = find(existingPaths == paths(k), 1);
            if ~isempty(existingIndex)
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

    function imageOut = currentPreviewSourceImage()
        if isempty(S.items)
            imageOut = [];
            return;
        end
        index = currentSelectionIndex();
        if numel(S.previewImages) ~= numel(S.items)
            S.previewImages = cell(numel(S.items), 1);
            S.previewImageKeys = strings(numel(S.items), 1);
        end
        item = S.items(index);
        key = previewImageKey(item);
        if isempty(S.previewImages{index}) || S.previewImageKeys(index) ~= key
            S.previewImages{index} = image_match.userInterface.previewImage(item.image);
            S.previewImageKeys(index) = key;
        end
        imageOut = S.previewImages{index};
    end

    function imageOut = currentPreviewReferenceImage()
        if ~hasReference()
            imageOut = [];
            return;
        end
        key = previewImageKey(S.referenceItem);
        if isempty(S.referencePreviewImage) || S.referencePreviewKey ~= key
            S.referencePreviewImage = image_match.userInterface.previewImage(S.referenceItem.image);
            S.referencePreviewKey = key;
        end
        imageOut = S.referencePreviewImage;
    end

    function imageOut = currentPreviewImage(includePending)
        imageOut = currentPreviewSourceImage();
        referenceImage = currentPreviewReferenceImage();
        steps = S.steps;
        stepsForKey = steps;
        if includePending
            stepsForKey(end + 1, 1) = currentMatchStep();
        end
        key = currentPreviewResultKey(stepsForKey, includePending);
        if ~isempty(S.previewResultImage) && S.previewResultKey == key
            imageOut = S.previewResultImage;
            return;
        end
        if ~isempty(steps)
            imageOut = image_match.analysisRun.applyPipeline({imageOut}, steps, referenceImage);
            imageOut = imageOut{1};
        end
        if includePending
            imageOut = image_match.analysisRun.applyStep( ...
                imageOut, currentMatchStep(), referenceImage);
        end
        S.previewResultImage = imageOut;
        S.previewResultKey = key;
    end

    function invalidatePreviewCache()
        S.previewImages = {};
        S.previewImageKeys = strings(0, 1);
        S.referencePreviewImage = [];
        S.referencePreviewKey = "";
        S.previewResultImage = [];
        S.previewResultKey = "";
    end

    function key = currentPreviewResultKey(stepsForKey, includePending)
        item = S.items(currentSelectionIndex());
        referenceItem = S.referenceItem;
        if ~hasReference()
            referenceItem = [];
        end
        task = image_match.appState.exportTask(item, referenceItem, stepsForKey, struct( ...
            'outputFolder', "preview", ...
            'format', "display"));
        key = task.fingerprint + sprintf('\n') + ...
            "pending=" + string(logical(includePending));
    end

    function markExportDirty()
        S.lastExport = [];
        S.lastExportFingerprint = "";
        S.previewResultImage = [];
        S.previewResultKey = "";
    end

    function key = previewImageKey(item)
        dims = strjoin(string(size(item.image)), "x");
        key = strjoin([string(item.path), dims, string(class(item.image))], "|");
    end

    function step = currentMatchStep()
        step = image_match.analysisRun.makeStep( ...
            labkit.ui.control.getValue(ui, 'matchMethod'), ...
            labkit.ui.control.getValue(ui, 'matchStrength'), ...
            labkit.ui.control.getValue(ui, 'toneStrength'), ...
            labkit.ui.control.getValue(ui, 'colorStrength'));
    end

    function tf = hasReference()
        tf = ~isempty(S.referenceItem) && isfield(S.referenceItem, 'image') && ...
            ~isempty(S.referenceItem.image);
    end

    function index = currentSelectionIndex()
        if isempty(S.items)
            index = 0;
            return;
        end
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        index = S.currentIndex;
    end

    function mode = currentPreviewMode()
        mode = string(labkit.ui.control.getValue(ui, 'preview'));
        if strlength(mode) == 0
            mode = "Matched";
        end
        mode = char(mode);
    end

    function resetPreviewAxes()
        labkit.ui.plot.reset(ui, 'preview', 'Matched Preview', true);
    end

    function addLog(message)
        labkit.ui.control.appendLog(ui, 'logPanel', message);
        if debugLog.enabled
            debugLog.append(message);
        end
    end

    function setupDebugSamples()
        try
            pack = image_match.debug.writeSamplePack(debugLog);
            addLog(sprintf('Debug sample files: %s', char(pack.sampleFolder)));
            addLog(sprintf('Debug output folder: %s', char(pack.outputFolder)));
        catch ME
            debugLog.reportException('imageMatch', 'Debug sample setup failed', ME);
            addLog(sprintf('Debug sample setup failed: %s', ME.message));
        end
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        labkit.ui.runtime.showAlert(fig, message, titleText);
    end

    function showException(titleText, exception)
        debugLog.reportException('imageMatch', titleText, exception);
        showError(titleText, exception.message);
    end
end

function text = onOff(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'on';
        else
            text = 'off';
        end
    else
        text = char(string(value));
    end
end
