function varargout = labkit_CSC_app(varargin)
%LABKIT_CSC_APP Launch the CV/CSC app.
% Single-file app that composes +labkit GUI/DTA APIs and owns CV/CSC workflow choices.
%
% Assumptions
%   - CV data is already constrained to the intended water window during acquisition.
%   - No additional window cropping is applied inside the GUI.
%
% Integration rules
%   - Cathodic charge: integrate only the negative current portion.
%   - Anodic  charge: integrate only the positive current portion.
%   - Full charge     : cathodic + anodic.
%
% CT charge
%   Qct = integral(I dt) using recorded time.
%
% CV charge (constant scan rate v)
%   dt = |dV| / v, so Qcv = integral(I * |dV| / v) (not trapz(V, I) directly).
%
% Optional normalization
%   CSC = Q / area (cm^2); both charge and normalized CSC are shown.
%
    [testLoadFile, isLoadDiagnostics] = parseCSCLoadDiagnosticsRequest(varargin);
    if isLoadDiagnostics
        debugLog = labkit.ui.diag.createContext('labkit_CSC_app', struct('enabled', false));
    else
        [requestHandled, requestOutputs, debugLog] = labkit.ui.app.dispatchRequest( ...
            'labkit_CSC_app', varargin, nargout, cscAppTestHandlers());
        if requestHandled
            varargout = requestOutputs;
            return;
        end
    end
    if debugLog.enabled
        if nargout > 2
            error('labkit_CSC_app:TooManyOutputs', ...
                'labkit_CSC_app debug mode returns at most the app figure and debug log.');
        end
    elseif ~isLoadDiagnostics && nargout > 1
        error('labkit_CSC_app:TooManyOutputs', 'labkit_CSC_app returns at most the app figure handle.');
    end
    if isLoadDiagnostics && nargout == 0
        error('labkit_CSC_app:InvalidTestRequest', 'CSC load test request requires one output diagnostics struct.');
    elseif isLoadDiagnostics && nargout > 1
        error('labkit_CSC_app:TooManyOutputs', 'CSC load test request returns one diagnostics struct.');
    end

    % Application state container
    S = struct();
    S.session = labkit.dta.makeSession('cv_csc');
    S.filepath = '';
    S.items = S.session.items;
    S.current = [];
    S.curves = struct('name',{},'headers',{},'units',{},'data',{},'numericMask',{});
    S.scanRate = NaN; % V/s
    S.currentCurve = 1;

    %% ===================== Figure & Layout =====================
    ui = labkit.ui.app.createShell(struct( ...
        'title', 'Gamry DTA GUI (literature CSC)', ...
        'position', [50 30 1580 950], ...
        'leftWidth', 390, ...
        'options', struct('rightKind', 'dualPlot')));
    fig = ui.fig;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;

    % -------- File panel --------
    fileCallbacks = struct();
    fileCallbacks.onOpenFiles = @onOpenFiles;
    fileCallbacks.onOpenFolder = @onOpenFolder;
    fileCallbacks.onClearAll = @(~,~) clearAllFiles();
    fileCallbacks.onExport = @(~,~) reloadSelectedFile();
    fileCallbacks.onSelectFile = @(~,~) onSelectFile();
    fileLabels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'clearAll', 'Clear all', ...
        'export', 'Reload selected', ...
        'loadedText', 'No files loaded');
    fileUi = labkit.ui.view.panel(layFA, 'files', fileLabels, fileCallbacks);
    lbFiles = fileUi.listbox;
    txtLoaded = fileUi.loadedText;

    % -------- Curve --------
    curveUi = labkit.ui.view.section(layFA, 'Curve', 2, [4 2]);
    gf = curveUi.grid;

    uilabel(gf,'Text','File:','HorizontalAlignment','right');
    txtFile = labkit.ui.view.form(gf, 'readonly');
    txtFile.Layout.Row = 1; txtFile.Layout.Column = 2;

    uilabel(gf,'Text','Scan rate:','HorizontalAlignment','right');
    txtScan = labkit.ui.view.form(gf, 'readonly');
    txtScan.Layout.Row = 2; txtScan.Layout.Column = 2;

    uilabel(gf,'Text','Curve:','HorizontalAlignment','right');
    ddCurve = uidropdown(gf,'Items',{'(none)'},'ValueChangedFcn',@(~,~) onCurveChanged());
    ddCurve.Layout.Row = 3; ddCurve.Layout.Column = 2;

    btnAuto = uibutton(gf,'Text','Auto CV + CT','ButtonPushedFcn',@(~,~) autoPresetAndRefresh());
    btnAuto.Layout.Row = 4; btnAuto.Layout.Column = [1 2];

    % -------- Actions --------
    actionOpts = struct('columnWidth', {{'1x', '1x'}});
    actionUi = labkit.ui.view.section(layFA, 'Actions', 3, [2 2], actionOpts);
    ga = actionUi.grid;

    btnSwap = uibutton(ga,'Text','Swap Top/Bottom','ButtonPushedFcn',@(~,~) onSwapPlots());
    btnSwap.Layout.Row = 1; btnSwap.Layout.Column = 1;
    btnCompare = uibutton(ga,'Text','Compare Q / CSC','ButtonPushedFcn',@(~,~) refreshCompare());
    btnCompare.Layout.Row = 1; btnCompare.Layout.Column = 2;
    btnRefresh = uibutton(ga,'Text','Refresh Plots','ButtonPushedFcn',@(~,~) refreshPlotsOnly());
    btnRefresh.Layout.Row = 2; btnRefresh.Layout.Column = 1;
    btnClear = uibutton(ga,'Text','Clear Both','ButtonPushedFcn',@(~,~) clearBothAxes());
    btnClear.Layout.Row = 2; btnClear.Layout.Column = 2;

    % -------- Comparison / CSC --------
    compUi = labkit.ui.view.section(laySR, 'CSC / Comparison', 1, [8 2]);
    gc = compUi.grid;

    uilabel(gc,'Text','Mode:','HorizontalAlignment','right');
    ddMode = uidropdown(gc, ...
        'Items',{'Full','Cathodic','Anodic'}, ...
        'Value','Full', ...
        'ValueChangedFcn',@(~,~) refreshCompare());
    ddMode.Layout.Row = 1; ddMode.Layout.Column = 2;

    uilabel(gc,'Text','Area (cm^2):','HorizontalAlignment','right');
    edArea = uieditfield(gc,'text','Value','');
    edArea.ValueChangedFcn = @(~,~) refreshCompare();
    edArea.Layout.Row = 2; edArea.Layout.Column = 2;

    uilabel(gc,'Text','CT charge / CSC:','HorizontalAlignment','right');
    txtQct = labkit.ui.view.form(gc, 'readonly');
    txtQct.Layout.Row = 3; txtQct.Layout.Column = 2;

    uilabel(gc,'Text','CV charge / CSC:','HorizontalAlignment','right');
    txtQcv = labkit.ui.view.form(gc, 'readonly');
    txtQcv.Layout.Row = 4; txtQcv.Layout.Column = 2;

    uilabel(gc,'Text','Difference:','HorizontalAlignment','right');
    txtDiff = labkit.ui.view.form(gc, 'readonly');
    txtDiff.Layout.Row = 5; txtDiff.Layout.Column = 2;

    uilabel(gc,'Text','Relative diff:','HorizontalAlignment','right');
    txtRel = labkit.ui.view.form(gc, 'readonly');
    txtRel.Layout.Row = 6; txtRel.Layout.Column = 2;

    uilabel(gc,'Text','max|dt-|dV|/v|:','HorizontalAlignment','right');
    txtDtErr = labkit.ui.view.form(gc, 'readonly');
    txtDtErr.Layout.Row = 7; txtDtErr.Layout.Column = 2;

    lblStatus = uilabel(gc,'Text','Ready');
    lblStatus.Layout.Row = 8; lblStatus.Layout.Column = [1 2];
    lblStatus.FontWeight = 'bold';

    % -------- Log --------
    logUi = labkit.ui.view.panel(layLog, 'log', 1, {'GUI started.'});
    txtLog = logUi.textArea;
    txtLog.Value = {'GUI started.'};

    % -------- Top/bottom controls --------
    topPlotDefaults = struct('x', '(none)', 'y', '(none)', 'grid', true);
    bottomPlotDefaults = struct('x', '(none)', 'y', '(none)', 'grid', true);
    plotControls = labkit.ui.view.panel( ...
        ui.topControlsPanel, ...
        'topBottomPlotControls', ...
        ui.bottomControlsPanel, ...
        {'(none)'}, ...
        {'(none)'}, ...
        topPlotDefaults, ...
        bottomPlotDefaults, ...
        @(~,~) refreshPlotsOnly());
    ddTopX = plotControls.topX;
    ddTopY = plotControls.topY;
    cbTopGrid = plotControls.topGridCheckbox;
    ddBotX = plotControls.bottomX;
    ddBotY = plotControls.bottomY;
    cbBotGrid = plotControls.bottomGridCheckbox;
    axTop = ui.topAxes;
    axBottom = ui.bottomAxes;
    title(axTop,'Top Plot');
    xlabel(axTop,'X');
    ylabel(axTop,'Y');
    title(axBottom,'Bottom Plot');
    xlabel(axBottom,'X');
    ylabel(axBottom,'Y');

    plotControls.topGrid.ColumnWidth = {'fit','1x','fit','1x','fit','fit','fit'};
    cbTopHold = uicheckbox(plotControls.topGrid,'Text','Hold','Value',false);
    cbTopHold.Layout.Row = 1; cbTopHold.Layout.Column = 6;
    cbTopTrim = uicheckbox(plotControls.topGrid,'Text','Show Trim','Value',true, ...
        'ValueChangedFcn',@(~,~) refreshCompare());
    cbTopTrim.Layout.Row = 1; cbTopTrim.Layout.Column = 7;

    plotControls.bottomGrid.ColumnWidth = {'fit','1x','fit','1x','fit','fit','fit'};
    cbBotHold = uicheckbox(plotControls.bottomGrid,'Text','Hold','Value',false);
    cbBotHold.Layout.Row = 1; cbBotHold.Layout.Column = 6;
    cbBotTrim = uicheckbox(plotControls.bottomGrid,'Text','Show Trim','Value',true, ...
        'ValueChangedFcn',@(~,~) refreshCompare());
    cbBotTrim.Layout.Row = 1; cbBotTrim.Layout.Column = 7;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('CSC debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end
    if isLoadDiagnostics
        cleanup = onCleanup(@() delete(fig));
        addFiles({testLoadFile});
        drawnow;
        varargout{1} = collectLoadDiagnostics();
        return;
    end
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debugLog;
    end

    %% App callbacks, loading, refresh, and plotting
    function onOpenFiles(~,~)
        [files,path] = uigetfile({'*.DTA;*.dta','Gamry DTA files (*.DTA)'}, ...
            'Select Gamry DTA file(s)','MultiSelect','on');
        if isequal(files,0)
            addLog('Open file canceled.');
            return;
        end
        if ischar(files) || isstring(files)
            files = {char(files)};
        end
        filepaths = cellfun(@(f) fullfile(path,f), files, 'UniformOutput', false);
        addFiles(filepaths);
    end

    function onOpenFolder(~,~)
        folder = uigetdir(pwd,'Select folder containing DTA files');
        if isequal(folder,0)
            addLog('Folder selection canceled.');
            return;
        end
        filepaths = labkit.dta.findFiles(folder);
        if isempty(filepaths)
            uialert(fig,'No .DTA files found in the selected folder.','Open folder');
            addLog(['No .DTA files found under: ' folder]);
            return;
        end
        addFiles(filepaths);
    end

    function addFiles(filepaths)
        if isempty(filepaths)
            return;
        end

        callbacks = struct();
        callbacks.onAdded = @(~, item) onAddedItem(item);
        callbacks.onSkipped = @(filepath) addLog(['Skipped duplicate: ' filepath]);
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed to load %s: %s', filepath, message));
        [S.session, report] = labkit.dta.addFilesToSession(S.session, filepaths, "cvct", callbacks);
        S.items = S.session.items;
        if ~isempty(S.items) && isempty(S.current)
            S.current = 1;
        end
        refreshFileList();
        loadCurrentItem();

        if ~isempty(report.failed)
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', ...
                firstError.filepath, firstError.message), 'Load error');
        end
    end

    function onAddedItem(item)
        for i = 1:numel(item.logmsg)
            addLog(item.logmsg{i});
        end
        addLog(['Loaded: ' item.filepath]);
    end

    function onSelectFile()
        if isempty(S.items) || isempty(lbFiles.Value)
            return;
        end
        idx = find(strcmp({S.items.name}, lbFiles.Value), 1);
        if isempty(idx)
            idx = 1;
        end
        S.current = idx;
        loadCurrentItem();
    end

    function clearAllFiles()
        S.session = labkit.dta.makeSession('cv_csc');
        S.items = S.session.items;
        S.current = [];
        clearCurrentItem();
        refreshFileList();
        clearBothAxes();
        addLog('Cleared all files.');
    end

    function reloadSelectedFile()
        if isempty(S.items) || isempty(S.current)
            uialert(fig,'No file selected.','Reload');
            addLog('Reload failed: no file selected.');
            return;
        end
        filepath = S.items(S.current).filepath;
        [S.session, ~] = labkit.dta.removeSelectedItemsFromSession(S.session, {S.items(S.current).name}, struct());
        S.items = S.session.items;
        S.current = [];
        addFiles({filepath});
    end

    function refreshFileList()
        if isempty(S.items)
            labkit.ui.view.update(lbFiles, 'listSelection', {});
            txtLoaded.Value = 'No files loaded';
            return;
        end
        [~, idx] = labkit.ui.view.update(lbFiles, 'listSelection', {S.items.name}, S.current);
        S.current = idx(1);
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function loadCurrentItem()
        if isempty(S.items)
            clearCurrentItem();
            return;
        end
        if isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            S.current = 1;
        end
        S.session.items(S.current).currentCurve = 1;
        S.session.items(S.current).analysis = [];
        S.items = S.session.items;
        item = S.items(S.current);
        S.filepath = item.filepath;
        S.scanRate = item.scanRate;
        S.curves = item.curves;
        S.currentCurve = 1;
        txtFile.Value = item.filepath;

        if isnan(S.scanRate)
            txtScan.Value = 'Not found';
        else
            txtScan.Value = sprintf('%.6f V/s (%.3f mV/s)', S.scanRate, S.scanRate*1000);
        end

        if isempty(S.curves)
            ddCurve.Items = {'(none)'};
            ddCurve.Value = '(none)';
            lblStatus.Text = 'No curve found';
            addLog('No curve parsed.');
            return;
        end

        items = cell(1,numel(S.curves));
        for k = 1:numel(S.curves)
            items{k} = sprintf('%s (%d rows)', S.curves(k).name, size(S.curves(k).data,1));
        end
        ddCurve.Items = items;
        ddCurve.Value = items{1};

        lblStatus.Text = sprintf('Loaded %d curve(s)', numel(S.curves));
        addLog(sprintf('Loaded %d curve(s) from %s.', numel(S.curves), item.name));

        updateDropdowns();
        autoSetDefaults();
        refreshAll();
    end

    function clearCurrentItem()
        S.filepath = '';
        S.scanRate = NaN;
        S.curves = struct('name',{},'headers',{},'units',{},'data',{},'numericMask',{});
        S.currentCurve = 1;
        txtFile.Value = '';
        txtScan.Value = '';
        ddCurve.Items = {'(none)'};
        ddCurve.Value = '(none)';
        lblStatus.Text = 'Ready';
        txtQct.Value = '';
        txtQcv.Value = '';
        txtDiff.Value = '';
        txtRel.Value = '';
        txtDtErr.Value = '';
    end

    function onCurveChanged()
        if isempty(S.curves)
            return;
        end
        idx = find(strcmp(ddCurve.Items, ddCurve.Value),1);
        if isempty(idx), idx = 1; end
        S.currentCurve = idx;
        syncSessionCurrentCurve();
        addLog(sprintf('Selected curve %d', idx));
        updateDropdowns();
        autoSetDefaults();
        refreshAll();
    end

    function autoPresetAndRefresh()
        autoSetDefaults();
        refreshAll();
    end

    function onSwapPlots()
        tx = ddTopX.Value; ty = ddTopY.Value;
        bx = ddBotX.Value; by = ddBotY.Value;

        if any(strcmp(ddTopX.Items,bx)), ddTopX.Value = bx; end
        if any(strcmp(ddTopY.Items,by)), ddTopY.Value = by; end
        if any(strcmp(ddBotX.Items,tx)), ddBotX.Value = tx; end
        if any(strcmp(ddBotY.Items,ty)), ddBotY.Value = ty; end

        addLog('Swapped top/bottom selections.');
        refreshPlotsOnly();
        refreshCompare();
    end

    function clearBothAxes()
        cla(axTop);
        cla(axBottom);
        title(axTop,'Top Plot'); xlabel(axTop,'X'); ylabel(axTop,'Y');
        title(axBottom,'Bottom Plot'); xlabel(axBottom,'X'); ylabel(axBottom,'Y');
        addLog('Cleared both axes.');
    end

    function syncSessionCurrentCurve()
        if ~isempty(S.session.items) && ~isempty(S.current)
            S.session.items(S.current).currentCurve = S.currentCurve;
            S.items = S.session.items;
        end
    end

    function updateDropdowns()
        if isempty(S.curves), return; end
        c = S.curves(S.currentCurve);
        cols = c.headers(c.numericMask);
        if isempty(cols)
            cols = {'(none)'};
        end
        ddTopX.Items = cols;
        ddTopY.Items = cols;
        ddBotX.Items = cols;
        ddBotY.Items = cols;
        addLog(['Numeric columns: ' strjoin(cols, ', ')]);
    end

    function autoSetDefaults()
        if isempty(S.curves), return; end
        setDropdownValueIfExists(ddTopX,'Vf');
        setDropdownValueIfExists(ddTopY,'Im');
        setDropdownValueIfExists(ddBotX,'T');
        setDropdownValueIfExists(ddBotY,'Im');
    end

    function refreshPlotsOnly()
        if isempty(S.curves), return; end
        plotTop();
        plotBottom();
    end

    function refreshAll()
        refreshPlotsOnly();
        refreshCompare();
    end

    function plotTop()
        if isempty(S.curves), return; end
        c = S.curves(S.currentCurve);
        opts = struct('holdPlot', cbTopHold.Value, 'showGrid', cbTopGrid.Value, 'lineWidth', 1.2);
        [x, y, xName, yName] = labkit.dta.getCurveXY(c, ddTopX.Value, ddTopY.Value);
        labels = struct('title', c.name, 'x', xName, 'y', yName);
        info = labkit.ui.view.draw(axTop, 'xy', x, y, labels, opts);
        if ~info.ok
            addLog('Top plot skipped: invalid X/Y.');
            return;
        end
        addLog(sprintf('Top plot: %s vs %s, n=%d', info.yName, info.xName, numel(info.x)));
    end

    function plotBottom()
        if isempty(S.curves), return; end
        c = S.curves(S.currentCurve);
        opts = struct('holdPlot', cbBotHold.Value, 'showGrid', cbBotGrid.Value, 'lineWidth', 1.2);
        [x, y, xName, yName] = labkit.dta.getCurveXY(c, ddBotX.Value, ddBotY.Value);
        labels = struct('title', c.name, 'x', xName, 'y', yName);
        info = labkit.ui.view.draw(axBottom, 'xy', x, y, labels, opts);
        if ~info.ok
            addLog('Bottom plot skipped: invalid X/Y.');
            return;
        end
        addLog(sprintf('Bottom plot: %s vs %s, n=%d', info.yName, info.xName, numel(info.x)));
    end

    function refreshCompare()
        if isempty(S.curves)
            txtQct.Value = '';
            txtQcv.Value = '';
            txtDiff.Value = '';
            txtRel.Value = '';
            txtDtErr.Value = '';
            return;
        end

        c = S.curves(S.currentCurve);
        opts = struct();
        opts.mode = ddMode.Value;
        opts.scanRate = S.scanRate;
        opts.area_cm2 = edArea.Value;
        R = computeCSC(c, opts);

        if ~R.ok
            txtQct.Value = R.message;
            txtQcv.Value = R.message;
            txtDiff.Value = '-';
            txtRel.Value = '-';
            txtDtErr.Value = '-';
            if isfield(R, 'logMessage') && ~isempty(R.logMessage)
                addLog(R.logMessage);
            end
            return;
        end

        txtQct.Value = formatChargeAndCSC(R.Qct, R.area_cm2);
        txtQcv.Value = formatChargeAndCSC(R.Qcv, R.area_cm2);
        txtDiff.Value = formatChargeAndCSC(R.diff_C, R.area_cm2);
        txtRel.Value = sprintf('%.6f %%', R.rel_pct);
        txtDtErr.Value = sprintf('%.6e s', R.dtErr);

        clearTrim(axTop);
        clearTrim(axBottom);

        if cbTopTrim.Value && strcmp(ddTopY.Value,'Im')
            [xTop, ~, ~, ~] = labkit.dta.getCurveXY(c, ddTopX.Value, ddTopY.Value);
            if numel(xTop) == numel(R.IcathDisp)
                hold(axTop,'on');
                plot(axTop, xTop, R.IcathDisp, 'Color',[0.1 0.6 0.1], ...
                    'LineWidth',1.0,'Tag','trimCath');
                plot(axTop, xTop, R.IanodDisp, 'Color',[0.8 0.3 0.1], ...
                    'LineWidth',1.0,'Tag','trimAnod');
                hold(axTop,'off');
            end
        end

        if cbBotTrim.Value && strcmp(ddBotY.Value,'Im')
            [xBot, ~, ~, ~] = labkit.dta.getCurveXY(c, ddBotX.Value, ddBotY.Value);
            if numel(xBot) == numel(R.IcathDisp)
                hold(axBottom,'on');
                plot(axBottom, xBot, R.IcathDisp, 'Color',[0.1 0.6 0.1], ...
                    'LineWidth',1.0,'Tag','trimCath');
                plot(axBottom, xBot, R.IanodDisp, 'Color',[0.8 0.3 0.1], ...
                    'LineWidth',1.0,'Tag','trimAnod');
                hold(axBottom,'off');
            end
        end

        addLog(sprintf(['Compare [%s]: Qct=%.6e C, Qcv=%.6e C, ', ...
            'rel=%.6f %%, maxdt=%.3e s'], ...
            ddMode.Value, R.Qct, R.Qcv, R.rel_pct, R.dtErr));

        if isnan(R.area_cm2)
            lblStatus.Text = 'Charge shown (area not set)';
        else
            lblStatus.Text = sprintf('CSC normalized by %.6g cm^2', R.area_cm2);
        end
    end

    function addLog(msg)
        labkit.ui.view.update(txtLog, 'appendLog', msg);
        debugLog.append(msg);
    end

    function diagnostics = collectLoadDiagnostics()
        diagnostics = struct();
        diagnostics.file = txtFile.Value;
        diagnostics.scanRate = txtScan.Value;
        diagnostics.curveItems = ddCurve.Items;
        diagnostics.topLineCount = numel(findobj(axTop, 'Type', 'Line'));
        diagnostics.bottomLineCount = numel(findobj(axBottom, 'Type', 'Line'));
        diagnostics.qct = txtQct.Value;
        diagnostics.qcv = txtQcv.Value;
        diagnostics.status = lblStatus.Text;
        diagnostics.log = txtLog.Value;
    end
end

%% App-local formatting and plot cleanup

function s = formatChargeAndCSC(Q, area_cm2)
    if isnan(area_cm2) || area_cm2 <= 0
        s = sprintf('%.12e C', Q);
    else
        CSC_mC_cm2 = 1e3 * Q / area_cm2; % C -> mC/cm^2
        s = sprintf('%.12e C | %.12e mC/cm^2', Q, CSC_mC_cm2);
    end
end

function clearTrim(ax)
    delete(findobj(ax,'Tag','trimCath'));
    delete(findobj(ax,'Tag','trimAnod'));
end

function setDropdownValueIfExists(dd, valueText)
    if any(strcmp(dd.Items, valueText))
        dd.Value = valueText;
    elseif ~isempty(dd.Items)
        dd.Value = dd.Items{1};
    end
end

function handlers = cscAppTestHandlers()
    handlers = struct( ...
        'command', {'computeCSC'}, ...
        'minArgs', {2}, ...
        'maxArgs', {2}, ...
        'maxOutputs', {1}, ...
        'run', {@runComputeCSC});
end

function outputs = runComputeCSC(args)
    outputs = {computeCSC(args{1}, args{2})};
end

function [filepath, tf] = parseCSCLoadDiagnosticsRequest(args)
    filepath = '';
    tf = false;
    if numel(args) < 2 ...
            || ~(ischar(args{1}) || (isstring(args{1}) && isscalar(args{1}))) ...
            || ~strcmp(string(args{1}), "__labkit_test__") ...
            || ~(ischar(args{2}) || (isstring(args{2}) && isscalar(args{2}))) ...
            || ~strcmp(string(args{2}), "loadFileDiagnostics")
        return;
    end
    if numel(args) ~= 3 || ~(ischar(args{3}) || (isstring(args{3}) && isscalar(args{3})))
        error('labkit_CSC_app:InvalidTestArguments', ...
            'Command loadFileDiagnostics expects one filepath argument.');
    end
    filepath = char(args{3});
    tf = true;
end

%% App-local analysis
function A = computeCSC(curve, opts)
%COMPUTECSC Compute CV/CT charge comparison and CSC for the CSC app.

    if nargin < 2
        opts = struct();
    end
    opts = fillOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.logMessage = '';
    A.mode = opts.mode;
    A.scanRate = opts.scanRate;
    A.area_cm2 = parsePositiveScalar(opts.area_cm2);

    if ~(isscalar(A.scanRate) && isfinite(A.scanRate) && A.scanRate > 0)
        A.message = 'scan rate missing';
        A.logMessage = 'Compare skipped: scan rate missing.';
        return;
    end

    if ~hasExactColumns(curve, {'T', 'Vf', 'Im'})
        A.message = 'Need T, Vf, Im';
        A.logMessage = 'Compare skipped: T/Vf/Im not all present.';
        return;
    end

    t = exactColumn(curve, 'T');
    V = exactColumn(curve, 'Vf');
    I = exactColumn(curve, 'Im');

    good = ~(isnan(t) | isnan(V) | isnan(I));
    t = t(good);
    V = V(good);
    I = I(good);

    if numel(t) < 2
        A.message = 'Not enough points';
        A.logMessage = 'Compare skipped: not enough valid points.';
        return;
    end

    CT = computeCTCharge(t, V, I);
    CV = computeCVCharge(t, V, I, A.scanRate);
    if ~CT.ok
        A.message = CT.message;
        A.logMessage = 'Compare skipped: not enough valid points.';
        return;
    end
    if ~CV.ok
        A.message = CV.message;
        A.logMessage = 'Compare skipped: scan rate missing.';
        return;
    end

    A.t = t;
    A.Vf = V;
    A.Im = I;
    A.IcathDisp = CT.IcathDisp;
    A.IanodDisp = CT.IanodDisp;
    A.QctCath = CT.QctCath;
    A.QctAnod = CT.QctAnod;
    A.QctFull = CT.QctFull;
    A.QcvCath = CV.QcvCath;
    A.QcvAnod = CV.QcvAnod;
    A.QcvFull = CV.QcvFull;
    A.dtErr = CV.dtErr;

    switch A.mode
        case 'Cathodic'
            A.Qct = A.QctCath;
            A.Qcv = A.QcvCath;
        case 'Anodic'
            A.Qct = A.QctAnod;
            A.Qcv = A.QcvAnod;
        otherwise
            A.mode = 'Full';
            A.Qct = A.QctFull;
            A.Qcv = A.QcvFull;
    end

    A.diff_C = A.Qct - A.Qcv;
    denom = max(abs(A.Qct), abs(A.Qcv));
    if denom == 0
        A.rel_pct = 0;
    else
        A.rel_pct = 100 * abs(A.diff_C) / denom;
    end

    if isfinite(A.area_cm2) && A.area_cm2 > 0
        A.Qct_mC_cm2 = 1e3 * A.Qct / A.area_cm2;
        A.Qcv_mC_cm2 = 1e3 * A.Qcv / A.area_cm2;
        A.diff_mC_cm2 = 1e3 * A.diff_C / A.area_cm2;
    else
        A.Qct_mC_cm2 = NaN;
        A.Qcv_mC_cm2 = NaN;
        A.diff_mC_cm2 = NaN;
    end

    A.ok = true;
    A.message = 'OK';
end

%% Small app-local utilities
function opts = fillOptions(opts)
    if ~isfield(opts, 'mode')
        opts.mode = 'Full';
    end
    if ~isfield(opts, 'scanRate')
        opts.scanRate = NaN;
    end
    if ~isfield(opts, 'area_cm2')
        opts.area_cm2 = NaN;
    end
end

function tf = hasExactColumns(curve, names)
    tf = isfield(curve, 'headers');
    if ~tf
        return;
    end
    for k = 1:numel(names)
        if ~any(strcmp(curve.headers, names{k}))
            tf = false;
            return;
        end
    end
end

function col = exactColumn(curve, name)
    idx = find(strcmp(curve.headers, name), 1);
    if isempty(idx)
        col = [];
    else
        col = curve.data(:, idx);
    end
end

function R = computeCTCharge(t, V, I)
    R = struct();
    R.ok = false;
    R.message = '';

    if nargin < 3 || numel(t) < 2 || numel(V) < 2 || numel(I) < 2
        R.message = 'Not enough points';
        R = fillEmptyCT(R);
        return;
    end

    S = integrateCVCTSignSplit(t, V, I, NaN);
    R = copyFields(R, S, {'QctCath', 'QctAnod', 'IcathDisp', 'IanodDisp'});
    R.QctFull = R.QctCath + R.QctAnod;
    R.ok = true;
    R.message = 'OK';
end

function R = computeCVCharge(t, V, I, scanRate)
    R = struct();
    R.ok = false;
    R.message = '';

    if nargin < 4 || ~(isscalar(scanRate) && isfinite(scanRate) && scanRate > 0)
        R.message = 'scan rate missing';
        R = fillEmptyCV(R);
        return;
    end
    if numel(t) < 2 || numel(V) < 2 || numel(I) < 2
        R.message = 'Not enough points';
        R = fillEmptyCV(R);
        return;
    end

    S = integrateCVCTSignSplit(t, V, I, scanRate);
    R = copyFields(R, S, {'QcvCath', 'QcvAnod', 'dtErr', 'IcathDisp', 'IanodDisp'});
    R.QcvFull = R.QcvCath + R.QcvAnod;
    R.ok = true;
    R.message = 'OK';
end

function R = integrateCVCTSignSplit(t, V, I, scanRate)
    if nargin < 4
        scanRate = NaN;
    end

    t = t(:);
    V = V(:);
    I = I(:);

    R = struct();
    R.QctCath = 0;
    R.QctAnod = 0;
    R.QcvCath = 0;
    R.QcvAnod = 0;
    R.dtErr = NaN;

    R.IcathDisp = I;
    R.IanodDisp = I;
    R.IcathDisp(I >= 0) = NaN;
    R.IanodDisp(I <= 0) = NaN;

    dtErrList = [];
    useCV = isscalar(scanRate) && isfinite(scanRate) && scanRate > 0;

    for k = 1:numel(t)-1
        t1 = t(k);   t2 = t(k+1);
        V1 = V(k);   V2 = V(k+1);
        I1 = I(k);   I2 = I(k+1);

        if any(~isfinite([t1 t2 V1 V2 I1 I2]))
            continue;
        end

        bp = [0, 1];
        s0 = crossingFraction(I1, I2, 0);
        if ~isempty(s0)
            bp(end+1) = s0; %#ok<AGROW>
        end
        bp = unique(sort(bp));

        for j = 1:numel(bp)-1
            sa = bp(j);
            sb = bp(j+1);

            ta = lerp(t1, t2, sa);
            tb = lerp(t1, t2, sb);
            Va = lerp(V1, V2, sa);
            Vb = lerp(V1, V2, sb);
            Ia = lerp(I1, I2, sa);
            Ib = lerp(I1, I2, sb);

            Imid = 0.5 * (Ia + Ib);
            if Imid < 0
                R.QctCath = R.QctCath + abs(trapz([ta tb], [Ia Ib]));
            elseif Imid > 0
                R.QctAnod = R.QctAnod + trapz([ta tb], [Ia Ib]);
            end

            if useCV
                dt_act = tb - ta;
                dt_cv = abs(Vb - Va) / scanRate;
                dtErrList(end+1) = abs(dt_act - dt_cv); %#ok<AGROW>

                if Imid < 0
                    R.QcvCath = R.QcvCath + abs(trapz([0 dt_cv], [Ia Ib]));
                elseif Imid > 0
                    R.QcvAnod = R.QcvAnod + trapz([0 dt_cv], [Ia Ib]);
                end
            end
        end
    end

    if ~isempty(dtErrList)
        R.dtErr = max(dtErrList);
    end
end

function R = fillEmptyCT(R)
    R.QctCath = 0;
    R.QctAnod = 0;
    R.QctFull = 0;
    R.IcathDisp = [];
    R.IanodDisp = [];
end

function R = fillEmptyCV(R)
    R.QcvCath = 0;
    R.QcvAnod = 0;
    R.QcvFull = 0;
    R.dtErr = NaN;
    R.IcathDisp = [];
    R.IanodDisp = [];
end

function out = copyFields(out, in, names)
    for k = 1:numel(names)
        out.(names{k}) = in.(names{k});
    end
end

function y = lerp(a, b, s)
    y = a + s * (b - a);
end

function s = crossingFraction(y1, y2, y0)
    if ~isfinite(y1) || ~isfinite(y2) || y1 == y2
        s = [];
        return;
    end
    s = (y0 - y1) / (y2 - y1);
    if ~(s > 0 && s < 1)
        s = [];
    end
end

function q = parsePositiveScalar(x)
    if isnumeric(x)
        q = x;
    else
        x = strtrim(char(x));
        if isempty(x)
            q = NaN;
            return;
        end
        q = str2double(x);
    end

    if ~isscalar(q) || ~isfinite(q) || q <= 0
        q = NaN;
    end
end
