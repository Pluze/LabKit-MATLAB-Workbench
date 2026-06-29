% Expected caller: labkit_ImageMatch_app. Input is the debug context prepared
% by the public launcher. Output is the app figure. Side effects are GUI
% creation, user-driven image loading, matched image export, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the Image Match app body.

    S = struct();
    S.items = repmat(image_match.state.emptyItem(), 0, 1);
    S.referenceItem = [];
    S.currentIndex = 0;
    S.steps = repmat(image_match.state.emptyStep(), 0, 1);
    S.outputFolder = string(labkit.ui.app.defaultDialogFolder("output"));
    S.lastExport = [];
    S.lastExportFingerprint = "";
    S.pendingDirty = false;
    S.previewImages = {};
    S.previewImageKeys = strings(0, 1);
    S.referencePreviewImage = [];
    S.referencePreviewKey = "";
    S.previewResultImage = [];
    S.previewResultKey = "";

    methods = {'Balanced', 'White balance', 'Tone only', 'Lab style', 'Histogram'};
    callbacks = struct( ...
        'referenceImageChosen', @onReferenceImageChosen, ...
        'clearReference', @onClearReference, ...
        'sourceImagesChosen', @onSourceImagesChosen, ...
        'removeImages', @onRemoveImages, ...
        'clearImages', @onClearImages, ...
        'imageSelectionChanged', @onImageSelectionChanged, ...
        'previewModeChanged', @onPreviewModeChanged, ...
        'matchSettingChanged', @onMatchSettingChanged, ...
        'applyMatch', @onApplyMatch, ...
        'undoHistory', @onUndoHistory, ...
        'resetHistory', @onResetHistory, ...
        'chooseOutputFolder', @onChooseOutputFolder, ...
        'exportImages', @onExportImages);
    spec = image_match.ui.buildSpec(methods, char(S.outputFolder), callbacks);
    ui = labkit.ui.app.create(spec, 'debug', debugLog);
    fig = ui.figure;
    if debugLog.enabled
        debugLog.trace('Image match debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetPreviewAxes();
    refreshAll();

    function onReferenceImageChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Reference image selection cancelled.');
            return;
        end
        try
            loaded = image_match.io.readImages(paths(1));
        catch ME
            showError('Could not load reference image', ME.message);
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
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Image selection cancelled.');
            return;
        end
        try
            S.items = readOrReuseImages(paths);
        catch ME
            showError('Could not load images', ME.message);
            refreshAll();
            return;
        end

        S.currentIndex = 1;
        S.steps = repmat(image_match.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        invalidatePreviewCache();
        S.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
            paths, "image_match", S.outputFolder));
        markExportDirty();
        addLog(sprintf('Loaded %d image(s).', numel(S.items)));
        refreshAll();
    end

    function onClearImages(~, ~)
        S.items = repmat(image_match.state.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.steps = repmat(image_match.state.emptyStep(), 0, 1);
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
        idx = fileIndices(event.selectedFiles, numel(S.items));
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
        S.steps = repmat(image_match.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        markExportDirty();
        addLog('Reset match history.');
        refreshAll();
    end

    function onChooseOutputFolder(~, ~)
        folder = uigetdir(labkit.ui.app.defaultDialogFolder("output", S.outputFolder), ...
            'Select image match export folder');
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
            showError('No images loaded', 'Load images before exporting matched outputs.');
            return;
        end
        if ~hasReference()
            showError('No reference image', 'Load a reference image before exporting matched outputs.');
            return;
        end
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = labkit.ui.view.getValue(ui, 'exportFormat');
        task = image_match.state.exportTask(S.items, S.referenceItem, S.steps, opts);
        if ~isempty(S.lastExport) && S.lastExportFingerprint == task.fingerprint
            addLog('Matched export is already up to date; skipped duplicate write.');
            refreshDetails();
            return;
        end
        try
            S.lastExport = image_match.export.writeOutputs( ...
                S.items, S.referenceItem, S.steps, opts);
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
            labkit.ui.view.setValue(ui, 'sourceImages', {});
            labkit.ui.view.setValue(ui, 'imageStatus', 'Images: 0');
            return;
        end

        paths = cellstr(string({S.items.path}));
        labkit.ui.view.setValue(ui, 'sourceImages', paths);
        labkit.ui.view.setValue(ui, 'imageStatus', sprintf( ...
            'Images: %d | match steps: %d', numel(S.items), numel(S.steps)));
    end

    function refreshReferenceLibrary()
        if hasReference()
            labkit.ui.view.setValue(ui, 'referenceImage', ...
                cellstr(S.referenceItem.path));
        else
            labkit.ui.view.setValue(ui, 'referenceImage', {});
        end
    end

    function refreshSelection()
        if isempty(S.items)
            return;
        end
        files = labkit.ui.view.getFiles(ui, 'sourceImages');
        labkit.ui.view.setFileSelection( ...
            ui, 'sourceImages', files(currentSelectionIndex()));
    end

    function refreshMatchControls()
        hasImages = ~isempty(S.items);
        refLoaded = hasReference();
        hasSteps = ~isempty(S.steps);
        ui.controls.sourceImages.clearButton.Enable = onOff(hasImages);
        ui.controls.sourceImages.listbox.Enable = onOff(hasImages);
        labkit.ui.view.setEnabled(ui, 'applyMatch', hasImages && refLoaded);
        labkit.ui.view.setEnabled(ui, 'undoHistory', hasSteps);
        labkit.ui.view.setEnabled(ui, 'resetHistory', hasSteps);
        labkit.ui.view.setEnabled(ui, 'exportImages', hasImages && refLoaded);
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
        switch currentPreviewMode()
            case 'Original'
                labkit.ui.view.drawImage(ui, 'preview', original, ...
                    'title', 'Original Preview');
            case 'Before | After'
                matched = currentPreviewImage(S.pendingDirty);
                labkit.ui.view.drawImage(ui, 'preview', ...
                    image_match.view.beforeAfterImage(original, matched), ...
                    'title', 'Before | After');
            otherwise
                matched = currentPreviewImage(S.pendingDirty);
                labkit.ui.view.drawImage(ui, 'preview', matched, ...
                    'title', 'Matched Preview');
        end
    end

    function refreshMetrics()
        if isempty(S.items)
            ui.controls.metricsTable.table.Data = ...
                image_match.view.resultTableData([], [], 0);
            return;
        end
        processedImage = currentPreviewImage(false);
        ui.controls.metricsTable.table.Data = image_match.view.resultTableData( ...
            S.items(currentSelectionIndex()), ...
            processedImage, numel(S.steps));
    end

    function refreshHistory()
        ui.controls.historyTable.table.Data = image_match.view.historyTableData(S.steps);
        labkit.ui.view.setValue(ui, 'historyStatus', ...
            sprintf('History steps: %d', numel(S.steps)));
    end

    function refreshDetails()
        labkit.ui.view.setValue(ui, 'exportDetails', image_match.view.detailLines( ...
            S.items, max(currentSelectionIndex(), 1), S.referenceItem, ...
            S.steps, S.lastExport));
    end

    function refreshMatchStatus()
        labkit.ui.view.setValue(ui, 'matchFlow', ...
            image_match.view.matchFlowLines(labkit.ui.view.getValue(ui, 'matchMethod')));
    end

    function items = readOrReuseImages(paths)
        paths = string(paths(:));
        template = image_match.state.emptyItem();
        items = repmat(template, numel(paths), 1);
        existingPaths = strings(0, 1);
        if ~isempty(S.items)
            existingPaths = string({S.items.path}).';
        end
        missing = paths(~ismember(paths, existingPaths));
        loaded = image_match.io.readImages(missing);
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
        end
        item = S.items(index);
        key = previewImageKey(item);
        if isempty(S.previewImages{index}) || S.previewImageKeys(index) ~= key
            S.previewImages{index} = image_match.view.previewImage(item.image);
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
            S.referencePreviewImage = image_match.view.previewImage(S.referenceItem.image);
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
            imageOut = image_match.ops.applyPipeline({imageOut}, steps, referenceImage);
            imageOut = imageOut{1};
        end
        if includePending
            imageOut = image_match.ops.applyStep( ...
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
        task = image_match.state.exportTask(item, referenceItem, stepsForKey, struct( ...
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
        step = image_match.ops.makeStep( ...
            labkit.ui.view.getValue(ui, 'matchMethod'), ...
            labkit.ui.view.getValue(ui, 'matchStrength'), ...
            labkit.ui.view.getValue(ui, 'toneStrength'), ...
            labkit.ui.view.getValue(ui, 'colorStrength'));
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
        mode = string(labkit.ui.view.getValue(ui, 'preview'));
        if strlength(mode) == 0
            mode = "Matched";
        end
        mode = char(mode);
    end

    function resetPreviewAxes()
        labkit.ui.view.resetAxes(ui, 'preview', 'Matched Preview', true);
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
