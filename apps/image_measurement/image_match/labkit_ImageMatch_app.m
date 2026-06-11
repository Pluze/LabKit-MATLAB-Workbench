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
        'openFiles', @onOpenFiles, ...
        'clearImages', @onClearImages, ...
        'imageSelectionChanged', @onImageSelectionChanged, ...
        'previewModeChanged', @onPreviewModeChanged, ...
        'matchSettingChanged', @onMatchSettingChanged, ...
        'applyMatch', @onApplyMatch, ...
        'undoHistory', @onUndoHistory, ...
        'resetHistory', @onResetHistory, ...
        'chooseOutputFolder', @onChooseOutputFolder, ...
        'exportImages', @onExportImages);
    uih = image_match.ui.createEditorUi(methods, char(S.outputFolder), callbacks);
    fig = uih.fig; previewAxes = uih.previewAxes; txtLog = uih.txtLog;
    btnOpenFiles = uih.btnOpenFiles; btnClearImages = uih.btnClearImages;
    lbImages = uih.lbImages; txtImageSource = uih.txtImageSource;
    txtImageStatus = uih.txtImageStatus; ddPreviewMode = uih.ddPreviewMode;
    ddReference = uih.ddReference; ddMethod = uih.ddMethod;
    edtStrength = uih.edtStrength; edtTone = uih.edtTone;
    edtColor = uih.edtColor; txtMatchFlow = uih.txtMatchFlow;
    btnApplyMatch = uih.btnApplyMatch; btnUndoHistory = uih.btnUndoHistory;
    btnResetHistory = uih.btnResetHistory; historyTable = uih.historyTable;
    txtHistoryStatus = uih.txtHistoryStatus; resultTable = uih.resultTable;
    btnChooseOutput = uih.btnChooseOutput; txtOutputFolder = uih.txtOutputFolder;
    ddFormat = uih.ddFormat; btnExport = uih.btnExport; txtDetails = uih.txtDetails;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
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

    function onOpenFiles(~, ~)
        [files, folder] = uigetfile(image_match.io.imageDialogFilter(), ...
            'Select images to match', pwd, 'MultiSelect', 'on');
        if isequal(files, 0)
            addLog('Image file selection cancelled.');
            return;
        end
        try
            paths = image_match.io.selectedImagePaths(files, folder);
            S.items = image_match.io.readImages(paths);
        catch ME
            showError('Could not load images', ME.message);
            return;
        end

        S.currentIndex = 1;
        S.steps = repmat(image_match.state.emptyStep(), 0, 1);
        S.pendingDirty = false;
        S.outputFolder = string(folder);
        S.lastExport = [];
        txtOutputFolder.Value = char(S.outputFolder);
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

    function onImageSelectionChanged(~, ~)
        if isempty(S.items)
            return;
        end
        names = image_match.view.displayImageNames(S.items);
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
        txtOutputFolder.Value = char(S.outputFolder);
        refreshDetails();
    end

    function onExportImages(~, ~)
        if isempty(S.items)
            showError('No images loaded', 'Load images before exporting matched outputs.');
            return;
        end
        opts = struct();
        opts.outputFolder = S.outputFolder;
        opts.format = ddFormat.Value;
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
        controls = {btnOpenFiles, btnClearImages, lbImages, ddPreviewMode, ...
            ddReference, ddMethod, edtStrength, edtTone, edtColor, ...
            btnApplyMatch, btnUndoHistory, btnResetHistory, btnChooseOutput, ...
            ddFormat, btnExport};
    end

    function refreshAll()
        refreshList();
        refreshControls();
        refreshSelection();
        refreshHistory();
        refreshPreview();
        refreshMetrics();
        refreshDetails();
        refreshMatchStatus();
    end

    function refreshList()
        if isempty(S.items)
            lbImages.Items = {'No images loaded'};
            lbImages.Value = 'No images loaded';
            txtImageSource.Value = 'No images loaded';
            txtImageStatus.Value = 'Images: 0';
            ddReference.Items = {'No reference'};
            ddReference.Value = 'No reference';
            return;
        end
        names = image_match.view.displayImageNames(S.items);
        S.currentIndex = min(max(S.currentIndex, 1), numel(S.items));
        lbImages.Items = names;
        lbImages.Value = names{S.currentIndex};
        txtImageStatus.Value = sprintf('Images: %d | match steps: %d', ...
            numel(S.items), numel(S.steps));
        previousReference = ddReference.Value;
        ddReference.Items = names;
        if any(strcmp(names, previousReference))
            ddReference.Value = previousReference;
        else
            ddReference.Value = names{S.currentIndex};
        end
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
        btnClearImages.Enable = image_match.view.ternary(hasImages, 'on', 'off');
        ddReference.Enable = image_match.view.ternary(hasImages, 'on', 'off');
        btnApplyMatch.Enable = image_match.view.ternary(hasImages, 'on', 'off');
        btnUndoHistory.Enable = image_match.view.ternary(hasSteps, 'on', 'off');
        btnResetHistory.Enable = image_match.view.ternary(hasSteps, 'on', 'off');
        btnExport.Enable = image_match.view.ternary(hasImages, 'on', 'off');
    end

    function refreshPreview()
        if isempty(S.items)
            resetPreviewAxes();
            return;
        end
        original = S.items(S.currentIndex).image;
        processed = currentProcessedImages(S.pendingDirty);
        matched = processed{S.currentIndex};
        switch ddPreviewMode.Value
            case 'Original'
                labkit.ui.view.draw(previewAxes, 'image', original, 'Original Preview');
            case 'Before | After'
                labkit.ui.view.draw(previewAxes, 'image', ...
                    image_match.view.beforeAfterImage(original, matched), 'Before | After');
            otherwise
                labkit.ui.view.draw(previewAxes, 'image', matched, 'Matched Preview');
        end
    end

    function refreshMetrics()
        if isempty(S.items)
            resultTable.Data = image_match.view.resultTableData([], [], 0);
            return;
        end
        processed = currentProcessedImages(false);
        resultTable.Data = image_match.view.resultTableData( ...
            S.items(S.currentIndex), processed{S.currentIndex}, numel(S.steps));
    end

    function refreshHistory()
        historyTable.Data = image_match.view.historyTableData(S.steps);
        txtHistoryStatus.Value = sprintf('History steps: %d', numel(S.steps));
    end

    function refreshDetails()
        txtDetails.Value = image_match.view.detailLines( ...
            S.items, max(S.currentIndex, 1), S.steps, S.lastExport);
    end

    function refreshMatchStatus()
        txtMatchFlow.Value = image_match.view.matchFlowLines(ddMethod.Value);
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
        step = image_match.ops.makeStep(currentReferenceIndex(), ddMethod.Value, ...
            edtStrength.Value, edtTone.Value, edtColor.Value);
    end

    function index = currentReferenceIndex()
        index = 0;
        if isempty(S.items)
            return;
        end
        names = image_match.view.displayImageNames(S.items);
        idx = find(strcmp(names, ddReference.Value), 1);
        if ~isempty(idx)
            index = idx;
        elseif S.currentIndex > 0
            index = S.currentIndex;
        end
    end

    function resetPreviewAxes()
        labkit.ui.view.draw(previewAxes, 'reset', 'Matched Preview', true);
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
