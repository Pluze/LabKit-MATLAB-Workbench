function varargout = labkit_ImageMatch_app(varargin)
%LABKIT_IMAGEMATCH_APP Reference image matching app for figure images.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_ImageMatch_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ImageMatch_app:TooManyOutputs', ...
                'labkit_ImageMatch_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ImageMatch_app:TooManyOutputs', ...
            'labkit_ImageMatch_app returns at most the app figure handle.');
    end

    S = struct();
    S.items = repmat(image_match.state.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.steps = repmat(image_match.state.emptyStep(), 0, 1);
    S.outputFolder = string(pwd);
    S.lastExport = [];
    S.pendingDirty = false;

    methods = {'Balanced', 'White balance', 'Tone only', 'Lab style', 'Histogram'};
    callbacks = struct( ...
        'sourceImagesChosen', @onSourceImagesChosen, ...
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

    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

    function onSourceImagesChosen(~, event)
        try
            S.items = image_match.io.readImages(event.paths);
        catch ME
            showError('Could not load images', ME.message);
            refreshAll();
            return;
        end

        S.currentIndex = 1;
        S.steps = repmat(image_match.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        S.outputFolder = string(fileparts(event.paths{1}));
        S.lastExport = [];
        addLog(sprintf('Loaded %d image(s).', numel(S.items)));
        refreshAll();
    end

    function onClearImages(~, ~)
        S.items = repmat(image_match.state.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.steps = repmat(image_match.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        S.lastExport = [];
        addLog('Cleared loaded images and match history.');
        refreshAll();
    end

    function onImageSelectionChanged(~, event)
        if isempty(S.items) || isempty(event.value)
            return;
        end
        selectedPath = string(event.value);
        idx = find(string({S.items.path}) == selectedPath, 1);
        if isempty(idx)
            return;
        end
        S.currentIndex = idx;
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
        S.lastExport = [];
        refreshPreview();
        refreshMatchStatus();
    end

    function onApplyMatch(~, ~)
        if isempty(S.items)
            showError('No images loaded', 'Load images before applying reference matches.');
            return;
        end
        step = currentMatchStep();
        S.steps(end + 1, 1) = step;
        S.pendingDirty = false;
        S.lastExport = [];
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
        S.lastExport = [];
        addLog(sprintf('Undid match step: %s', char(removed.label)));
        refreshAll();
    end

    function onResetHistory(~, ~)
        if isempty(S.steps)
            return;
        end
        S.steps = repmat(image_match.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        S.lastExport = [];
        addLog('Reset match history.');
        refreshAll();
    end

    function onChooseOutputFolder(~, ~)
        folder = uigetdir(char(S.outputFolder), 'Select image match export folder');
        if isequal(folder, 0)
            addLog('Export folder selection cancelled.');
            return;
        end
        S.outputFolder = string(folder);
        refreshExportControls();
        refreshDetails();
    end

    function onExportImages(~, ~)
        if isempty(S.items)
            showError('No images loaded', 'Load images before exporting matched outputs.');
            return;
        end
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = labkit.ui.view.getValue(ui, 'exportFormat');
        busyOpts = struct();
        busyOpts.title = 'Export matched images';
        busyOpts.message = 'Writing matched image outputs...';
        busyOpts.controls = exportBusyControls();
        try
            S.lastExport = labkit.ui.app.runBusy(fig, ...
                @() image_match.export.writeOutputs(S.items, S.steps, opts), busyOpts);
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

    function controls = exportBusyControls()
        controls = { ...
            ui.controls.sourceImages.chooseButton ...
            ui.controls.sourceImages.clearButton ...
            ui.controls.sourceImages.listbox ...
            ui.controls.preview.viewModeDropDown ...
            ui.controls.referenceImage.handle ...
            ui.controls.matchMethod.handle ...
            ui.controls.matchStrength.handle ...
            ui.controls.toneStrength.handle ...
            ui.controls.colorStrength.handle ...
            ui.controls.applyMatch.button ...
            ui.controls.undoHistory.button ...
            ui.controls.resetHistory.button ...
            ui.controls.chooseOutputFolder.button ...
            ui.controls.exportFormat.handle ...
            ui.controls.exportImages.button};
    end

    function refreshAll()
        refreshSourceLibrary();
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
            referenceHandle = ui.controls.referenceImage.handle;
            referenceHandle.Items = {'No reference'};
            referenceHandle.Value = 'No reference';
            return;
        end

        paths = cellstr(string({S.items.path}));
        labkit.ui.view.setValue(ui, 'sourceImages', paths);
        labkit.ui.view.setValue(ui, 'imageStatus', sprintf( ...
            'Images: %d | match steps: %d', numel(S.items), numel(S.steps)));

        names = image_match.view.displayImageNames(S.items);
        referenceHandle = ui.controls.referenceImage.handle;
        previousReference = referenceHandle.Value;
        referenceHandle.Items = names;
        if any(strcmp(names, previousReference))
            referenceHandle.Value = previousReference;
        else
            referenceHandle.Value = names{currentSelectionIndex()};
        end
    end

    function refreshSelection()
        if isempty(S.items)
            return;
        end
        paths = cellstr(string({S.items.path}));
        labkit.ui.view.setListSelection(ui, 'sourceImages', paths, ...
            paths{currentSelectionIndex()}, struct());
    end

    function refreshMatchControls()
        hasImages = ~isempty(S.items);
        hasSteps = ~isempty(S.steps);
        ui.controls.sourceImages.clearButton.Enable = onOff(hasImages);
        ui.controls.sourceImages.listbox.Enable = onOff(hasImages);
        labkit.ui.view.setEnabled(ui, 'referenceImage', hasImages);
        labkit.ui.view.setEnabled(ui, 'applyMatch', hasImages);
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
        original = S.items(currentSelectionIndex()).image;
        processed = currentProcessedImages(S.pendingDirty);
        matched = processed{currentSelectionIndex()};
        switch currentPreviewMode()
            case 'Original'
                labkit.ui.view.drawImage(ui, 'preview', original, ...
                    'title', 'Original Preview');
            case 'Before | After'
                labkit.ui.view.drawImage(ui, 'preview', ...
                    image_match.view.beforeAfterImage(original, matched), ...
                    'title', 'Before | After');
            otherwise
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
        processed = currentProcessedImages(false);
        ui.controls.metricsTable.table.Data = image_match.view.resultTableData( ...
            S.items(currentSelectionIndex()), ...
            processed{currentSelectionIndex()}, numel(S.steps));
    end

    function refreshHistory()
        ui.controls.historyTable.table.Data = image_match.view.historyTableData(S.steps);
        labkit.ui.view.setValue(ui, 'historyStatus', ...
            sprintf('History steps: %d', numel(S.steps)));
    end

    function refreshDetails()
        labkit.ui.view.setValue(ui, 'exportDetails', image_match.view.detailLines( ...
            S.items, max(currentSelectionIndex(), 1), S.steps, S.lastExport));
    end

    function refreshMatchStatus()
        labkit.ui.view.setValue(ui, 'matchFlow', ...
            image_match.view.matchFlowLines(labkit.ui.view.getValue(ui, 'matchMethod')));
    end

    function processed = currentProcessedImages(includePending)
        images = cell(numel(S.items), 1);
        for k = 1:numel(S.items)
            images{k} = S.items(k).image;
        end
        steps = S.steps;
        if includePending
            steps(end + 1, 1) = currentMatchStep();
        end
        processed = image_match.ops.applyPipeline(images, steps);
    end

    function step = currentMatchStep()
        step = image_match.ops.makeStep(currentReferenceIndex(), ...
            labkit.ui.view.getValue(ui, 'matchMethod'), ...
            labkit.ui.view.getValue(ui, 'matchStrength'), ...
            labkit.ui.view.getValue(ui, 'toneStrength'), ...
            labkit.ui.view.getValue(ui, 'colorStrength'));
    end

    function index = currentReferenceIndex()
        index = 0;
        if isempty(S.items)
            return;
        end
        names = image_match.view.displayImageNames(S.items);
        selectedReference = labkit.ui.view.getValue(ui, 'referenceImage');
        idx = find(strcmp(names, selectedReference), 1);
        if ~isempty(idx)
            index = idx;
        else
            index = currentSelectionIndex();
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
