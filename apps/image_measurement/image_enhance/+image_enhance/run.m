% Expected caller: labkit_ImageEnhance_app. Input is the debug context
% prepared by the public launcher. Output is the app figure. Side effects are
% GUI creation, user-driven image loading, image export, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the Image Enhance app body.

    S = struct();
    S.items = repmat(image_enhance.state.emptyItem(), 0, 1);
    S.currentIndex = 0;
    S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
    S.outputFolder = string(pwd);
    S.lastExport = [];
    S.pendingDirty = false;

    stepKinds = {'Brightness/contrast', 'Local contrast', 'Sharpen', ...
        'Hue/saturation', 'White balance'};
    callbacks = struct( ...
        'sourceImagesChosen', @onSourceImagesChosen, ...
        'clearImages', @onClearImages, ...
        'imageSelectionChanged', @onImageSelectionChanged, ...
        'previewModeChanged', @onPreviewModeChanged, ...
        'toolChanged', @onToolChanged, ...
        'toolSettingChanged', @onToolSettingChanged, ...
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
        try
            S.items = image_enhance.io.readImages(event.paths);
        catch ME
            showError('Could not load images', ME.message);
            refreshAll();
            return;
        end

        S.currentIndex = 1;
        S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        S.outputFolder = string(fileparts(event.paths(1)));
        S.lastExport = [];
        addLog(sprintf('Loaded %d image(s).', numel(S.items)));
        refreshAll();
    end

    function onClearImages(~, ~)
        S.items = repmat(image_enhance.state.emptyItem(), 0, 1);
        S.currentIndex = 0;
        S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        S.lastExport = [];
        addLog('Cleared loaded images and enhancement history.');
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

    function onToolChanged(~, ~)
        updateToolControls(true);
        S.pendingDirty = true;
        S.lastExport = [];
        refreshPreview();
        refreshToolStatus();
    end

    function onToolSettingChanged(~, ~)
        updateToolControls(false);
        S.pendingDirty = true;
        S.lastExport = [];
        refreshPreview();
        refreshToolStatus();
    end

    function onApplyTool(~, ~)
        if isempty(S.items)
            showError('No images loaded', 'Load images before applying enhancement tools.');
            return;
        end
        step = currentToolStep();
        S.steps(end + 1, 1) = step;
        S.pendingDirty = false;
        S.lastExport = [];
        addLog(sprintf('Applied tool: %s', char(step.label)));
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
        addLog(sprintf('Undid history step: %s', char(removed.label)));
        refreshAll();
    end

    function onResetHistory(~, ~)
        if isempty(S.steps)
            return;
        end
        S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        S.lastExport = [];
        addLog('Reset enhancement history.');
        refreshAll();
    end

    function onChooseOutputFolder(~, ~)
        folder = uigetdir(char(S.outputFolder), 'Select image enhancement export folder');
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
            showError('No images loaded', 'Load images before exporting enhanced outputs.');
            return;
        end
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = labkit.ui.view.getValue(ui, 'exportFormat');
        try
            S.lastExport = image_enhance.export.writeOutputs(S.items, S.steps, opts);
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
            return;
        end
        paths = cellstr(string({S.items.path}));
        labkit.ui.view.setValue(ui, 'sourceImages', paths);
        labkit.ui.view.setValue(ui, 'imageStatus', sprintf( ...
            'Images: %d | history steps: %d', numel(S.items), numel(S.steps)));
    end

    function refreshSelection()
        if isempty(S.items)
            return;
        end
        paths = cellstr(string({S.items.path}));
        labkit.ui.view.setListSelection(ui, 'sourceImages', paths, ...
            paths{currentSelectionIndex()}, struct());
    end

    function refreshControls()
        hasImages = ~isempty(S.items);
        hasSteps = ~isempty(S.steps);
        ui.controls.sourceImages.clearButton.Enable = onOff(hasImages);
        ui.controls.sourceImages.listbox.Enable = onOff(hasImages);
        labkit.ui.view.setEnabled(ui, 'applyTool', hasImages);
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
        enhanced = processed{currentSelectionIndex()};
        switch currentPreviewMode()
            case 'Original'
                labkit.ui.view.drawImage(ui, 'preview', original, ...
                    'title', 'Original Preview');
            case 'Before | After'
                labkit.ui.view.drawImage(ui, 'preview', ...
                    image_enhance.view.beforeAfterImage(original, enhanced), ...
                    'title', 'Before | After');
            otherwise
                labkit.ui.view.drawImage(ui, 'preview', enhanced, ...
                    'title', 'Enhanced Preview');
        end
    end

    function refreshMetrics()
        if isempty(S.items)
            ui.controls.metricsTable.table.Data = ...
                image_enhance.view.resultTableData([], [], 0);
            return;
        end
        processed = currentProcessedImages(false);
        ui.controls.metricsTable.table.Data = image_enhance.view.resultTableData( ...
            S.items(currentSelectionIndex()), ...
            processed{currentSelectionIndex()}, numel(S.steps));
    end

    function refreshHistory()
        ui.controls.historyTable.table.Data = image_enhance.view.historyTableData(S.steps);
        labkit.ui.view.setValue(ui, 'historyStatus', ...
            sprintf('History steps: %d', numel(S.steps)));
    end

    function refreshDetails()
        labkit.ui.view.setValue(ui, 'exportDetails', image_enhance.view.detailLines( ...
            S.items, max(currentSelectionIndex(), 1), S.steps, S.lastExport));
    end

    function refreshToolStatus()
        if isempty(S.items)
            labkit.ui.view.setValue(ui, 'toolStatus', ...
                'Select an image, choose a tool, then apply it to history.');
            return;
        end
        step = currentToolStep();
        if S.pendingDirty
            prefix = 'Previewing: ';
        else
            prefix = 'Ready: ';
        end
        labkit.ui.view.setValue(ui, 'toolStatus', [prefix char(step.label)]);
    end

    function processed = currentProcessedImages(includePending)
        images = cell(numel(S.items), 1);
        for k = 1:numel(S.items)
            images{k} = S.items(k).image;
        end
        steps = S.steps;
        if includePending
            steps(end + 1, 1) = currentToolStep();
        end
        processed = image_enhance.ops.applyPipeline(images, steps);
    end

    function step = currentToolStep()
        step = image_enhance.ops.makeStep( ...
            labkit.ui.view.getValue(ui, 'toolKind'), ...
            labkit.ui.view.getValue(ui, 'toolAmount'), ...
            labkit.ui.view.getValue(ui, 'toolSecondary'), 0);
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
        amountHandle.Value = clampValue(amountHandle.Value, values.amountLimits);
        secondaryHandle.Value = clampValue(secondaryHandle.Value, values.secondaryLimits);
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

    function mode = currentPreviewMode()
        mode = string(labkit.ui.view.getValue(ui, 'preview'));
        if strlength(mode) == 0
            mode = "Enhanced";
        end
        mode = char(mode);
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

function value = clampValue(value, limits)
    value = min(max(value, limits(1)), limits(2));
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
