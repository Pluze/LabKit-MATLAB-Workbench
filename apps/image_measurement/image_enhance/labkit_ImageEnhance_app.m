function varargout = labkit_ImageEnhance_app(varargin)
%LABKIT_IMAGEENHANCE_APP Image enhancement and color matching app for figures.

    [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
        'labkit_ImageEnhance_app', varargin, nargout);
    if requestHandled
        varargout = requestOutputs;
        return;
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_ImageEnhance_app:TooManyOutputs', ...
                'labkit_ImageEnhance_app debug mode returns at most the app figure and debug log.');
        end
    elseif nargout > 1
        error('labkit_ImageEnhance_app:TooManyOutputs', ...
            'labkit_ImageEnhance_app returns at most the app figure handle.');
    end

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
        'openFiles', @onOpenFiles, ...
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
    uih = image_enhance.ui.createEditorUi(stepKinds, char(S.outputFolder), callbacks);
    fig = uih.fig; previewAxes = uih.previewAxes; txtLog = uih.txtLog;
    btnOpenFiles = uih.btnOpenFiles; btnClearImages = uih.btnClearImages;
    lbImages = uih.lbImages; txtImageSource = uih.txtImageSource;
    txtImageStatus = uih.txtImageStatus; ddPreviewMode = uih.ddPreviewMode;
    lbTools = uih.lbTools; txtToolStatus = uih.txtToolStatus;
    lblAmount = uih.lblAmount; edtAmount = uih.edtAmount;
    lblSecondary = uih.lblSecondary; edtSecondary = uih.edtSecondary;
    btnApplyTool = uih.btnApplyTool;
    btnUndoHistory = uih.btnUndoHistory; btnResetHistory = uih.btnResetHistory;
    historyTable = uih.historyTable; txtHistoryStatus = uih.txtHistoryStatus;
    resultTable = uih.resultTable; btnChooseOutput = uih.btnChooseOutput;
    txtOutputFolder = uih.txtOutputFolder; ddFormat = uih.ddFormat;
    btnExport = uih.btnExport; txtDetails = uih.txtDetails;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('Image enhance debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    resetPreviewAxes();
    updateToolControls(false);
    refreshAll();

    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

    function onOpenFiles(~, ~)
        [files, folder] = uigetfile(image_enhance.io.imageDialogFilter(), ...
            'Select images to enhance', pwd, 'MultiSelect', 'on');
        if isequal(files, 0)
            addLog('Image file selection cancelled.');
            return;
        end

        try
            paths = image_enhance.io.selectedImagePaths(files, folder);
            S.items = image_enhance.io.readImages(paths);
        catch ME
            showError('Could not load images', ME.message);
            return;
        end

        S.currentIndex = 1;
        S.steps = repmat(image_enhance.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        S.outputFolder = string(folder);
        S.lastExport = [];
        txtOutputFolder.Value = char(S.outputFolder);
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

    function onImageSelectionChanged(~, ~)
        if isempty(S.items)
            return;
        end

        names = image_enhance.view.displayImageNames(S.items);
        idx = find(strcmp(names, lbImages.Value), 1);
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
        txtOutputFolder.Value = char(S.outputFolder);
        refreshDetails();
    end

    function onExportImages(~, ~)
        if isempty(S.items)
            showError('No images loaded', 'Load images before exporting enhanced outputs.');
            return;
        end

        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = ddFormat.Value;
        busyOpts = struct();
        busyOpts.title = 'Export enhanced images';
        busyOpts.message = 'Writing enhanced image outputs...';
        busyOpts.controls = exportBusyControls();
        try
            S.lastExport = labkit.ui.app.runBusy(fig, ...
                @() image_enhance.export.writeOutputs(S.items, S.steps, opts), busyOpts);
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
        controls = {btnOpenFiles, btnClearImages, lbImages, ddPreviewMode, ...
            lbTools, edtAmount, edtSecondary, btnApplyTool, ...
            btnUndoHistory, btnResetHistory, btnChooseOutput, ddFormat, btnExport};
    end

    function refreshAll()
        refreshList();
        updateToolControls(false);
        refreshControls();
        refreshSelection();
        refreshHistory();
        refreshPreview();
        refreshMetrics();
        refreshDetails();
        refreshToolStatus();
    end

    function refreshList()
        if isempty(S.items)
            lbImages.Items = {'No images loaded'};
            lbImages.Value = 'No images loaded';
            txtImageSource.Value = 'No images loaded';
            txtImageStatus.Value = 'Images: 0';
            return;
        end

        names = image_enhance.view.displayImageNames(S.items);
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        lbImages.Items = names;
        lbImages.Value = names{S.currentIndex};
        txtImageStatus.Value = sprintf('Images: %d | history steps: %d', ...
            numel(S.items), numel(S.steps));

    end

    function refreshSelection()
        if isempty(S.items)
            txtImageSource.Value = 'No images loaded';
            return;
        end

        txtImageSource.Value = char(S.items(S.currentIndex).path);
    end

    function refreshControls()
        hasImages = ~isempty(S.items);
        hasSteps = ~isempty(S.steps);
        btnClearImages.Enable = image_enhance.view.ternary(hasImages, 'on', 'off');
        btnApplyTool.Enable = image_enhance.view.ternary(hasImages, 'on', 'off');
        btnUndoHistory.Enable = image_enhance.view.ternary(hasSteps, 'on', 'off');
        btnResetHistory.Enable = image_enhance.view.ternary(hasSteps, 'on', 'off');
        btnExport.Enable = image_enhance.view.ternary(hasImages, 'on', 'off');
    end

    function refreshPreview()
        if isempty(S.items)
            resetPreviewAxes();
            return;
        end

        original = S.items(S.currentIndex).image;
        processed = currentProcessedImages(S.pendingDirty);
        enhanced = processed{S.currentIndex};

        switch ddPreviewMode.Value
            case 'Original'
                labkit.ui.view.draw(previewAxes, 'image', original, 'Original Preview');
            case 'Before | After'
                labkit.ui.view.draw(previewAxes, 'image', ...
                    image_enhance.view.beforeAfterImage(original, enhanced), 'Before | After');
            otherwise
                labkit.ui.view.draw(previewAxes, 'image', enhanced, 'Enhanced Preview');
        end
    end

    function refreshMetrics()
        if isempty(S.items)
            resultTable.Data = image_enhance.view.resultTableData([], [], 0);
            return;
        end

        processed = currentProcessedImages(false);
        resultTable.Data = image_enhance.view.resultTableData( ...
            S.items(S.currentIndex), processed{S.currentIndex}, numel(S.steps));
    end

    function refreshHistory()
        historyTable.Data = image_enhance.view.historyTableData(S.steps);
        txtHistoryStatus.Value = sprintf('History steps: %d', numel(S.steps));
    end

    function refreshDetails()
        txtDetails.Value = image_enhance.view.detailLines( ...
            S.items, max(S.currentIndex, 1), S.steps, S.lastExport);
    end

    function refreshToolStatus()
        if isempty(S.items)
            txtToolStatus.Value = 'Select an image, choose a tool, then apply it to history.';
            return;
        end

        step = currentToolStep();
        if S.pendingDirty
            prefix = 'Previewing: ';
        else
            prefix = 'Ready: ';
        end
        txtToolStatus.Value = [prefix char(step.label)];
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
        step = image_enhance.ops.makeStep(lbTools.Value, ...
            edtAmount.Value, edtSecondary.Value, 0);
    end

    function updateToolControls(resetToDefaults)
        values = image_enhance.ops.defaultStepValues(lbTools.Value);
        lblAmount.Text = char(values.amountLabel);
        lblSecondary.Text = char(values.secondaryLabel);
        edtAmount.Limits = values.amountLimits;
        edtSecondary.Limits = values.secondaryLimits;
        edtAmount.Value = min(max(edtAmount.Value, edtAmount.Limits(1)), edtAmount.Limits(2));
        edtSecondary.Value = min(max(edtSecondary.Value, edtSecondary.Limits(1)), edtSecondary.Limits(2));
        if resetToDefaults
            edtAmount.Value = values.amount;
            edtSecondary.Value = values.secondary;
        end
    end

    function resetPreviewAxes()
        labkit.ui.view.draw(previewAxes, 'reset', 'Enhanced Preview', true);
    end

    function addLog(message)
        labkit.ui.view.update(txtLog, 'appendLog', message);
        if debugLog.enabled
            debugLog.append(message);
        end
    end

    function showError(titleText, message)
        addLog(sprintf('%s: %s', titleText, message));
        uialert(fig, message, titleText);
    end
end
