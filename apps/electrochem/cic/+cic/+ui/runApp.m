% App-owned runner extracted from labkit_CIC_app.m. Expected caller: labkit_CIC_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = runApp(debugLog)
%RUNCICAPP Build and run the app body.

    S = struct();
    S.session = labkit.dta.makeSession('cic_vt');
    S.items = S.session.items; % loaded files + parsed content + analysis
    S.current = [];

    %% ===================== Figure & Layout =====================
    ui = labkit.ui.app.createShell(struct( ...
        'title', 'Gamry CIC GUI (Voltage Transient)', ...
        'position', [40 30 1680 980], ...
        'leftWidth', 430, ...
        'options', struct('rightKind', 'dualPlot')));
    fig = ui.fig;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;

    %% ===================== File panel =====================
    fileCallbacks = struct();
    fileCallbacks.onOpenFiles = @onOpenFiles;
    fileCallbacks.onOpenFolder = @onOpenFolder;
    fileCallbacks.onClearAll = @(~,~) clearAllFiles();
    fileCallbacks.onExport = @(~,~) exportResultsCSV();
    fileCallbacks.onSelectFile = @(~,~) onSelectFile();
    fileLabels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'clearAll', 'Clear all', ...
        'export', 'Export results CSV', ...
        'loadedText', 'No files loaded');
    fileUi = labkit.ui.view.panel(layFA, 'files', fileLabels, fileCallbacks);
    lbFiles = fileUi.listbox;
    txtLoaded = fileUi.loadedText;

    %% ===================== Analysis settings =====================
    settingsUi = labkit.ui.view.section(layFA, 'Analysis Settings', 2, [9 2]);
    gs = settingsUi.grid;

    uilabel(gs,'Text','Window preset:','HorizontalAlignment','right');
    ddPreset = uidropdown(gs, ...
        'Items',{'Pt (-0.6 to 0.8 V)','PEDOT:PSS (-0.9 to 0.6 V)','Custom'}, ...
        'Value','Pt (-0.6 to 0.8 V)', ...
        'ValueChangedFcn',@(~,~) onPresetChanged());
    ddPreset.Layout.Row = 1; ddPreset.Layout.Column = 2;

    [lblCathLim, edCathLim] = labkit.ui.view.form(gs, 'spinner', 'Cathodic limit (V):', ...
        'Value', -0.6, 'Limits', [-10 10], 'Step', 0.01, ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
    lblCathLim.Layout.Row = 2; lblCathLim.Layout.Column = 1;
    edCathLim.Layout.Row = 2; edCathLim.Layout.Column = 2;

    [lblAnodLim, edAnodLim] = labkit.ui.view.form(gs, 'spinner', 'Anodic limit (V):', ...
        'Value', 0.8, 'Limits', [-10 10], 'Step', 0.01, ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
    lblAnodLim.Layout.Row = 3; lblAnodLim.Layout.Column = 1;
    edAnodLim.Layout.Row = 3; edAnodLim.Layout.Column = 2;

    [lblDelayUs, edDelayUs] = labkit.ui.view.form(gs, 'spinner', 'Sample delay after pulse end:', ...
        'Value', 10, 'Limits', [0 inf], 'Step', 1, ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
    lblDelayUs.Layout.Row = 4; lblDelayUs.Layout.Column = 1;
    edDelayUs.Layout.Row = 4; edDelayUs.Layout.Column = 2;

    uilabel(gs,'Text','Area override (cm^2):','HorizontalAlignment','right');
    edArea = uieditfield(gs,'text','Value','', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    edArea.Layout.Row = 5; edArea.Layout.Column = 2;

    uilabel(gs,'Text','Pulse detection:','HorizontalAlignment','right');
    ddPulseMode = uidropdown(gs, ...
        'Items',{'Metadata first, then auto','Metadata only','Auto from Im only'}, ...
        'Value','Metadata first, then auto', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    ddPulseMode.Layout.Row = 6; ddPulseMode.Layout.Column = 2;

    uilabel(gs,'Text','CIC summary mode:','HorizontalAlignment','right');
    ddCICMode = uidropdown(gs, ...
        'Items',{'Cathodic phase','Anodic phase','Total biphasic'}, ...
        'Value','Total biphasic', ...
        'ValueChangedFcn',@(~,~) refreshResultsSummary());
    ddCICMode.Layout.Row = 7; ddCICMode.Layout.Column = 2;

    uilabel(gs,'Text','CIC unit:','HorizontalAlignment','right');
    ddCICUnit = uidropdown(gs, ...
        'Items',{'mC/cm^2','uC/cm^2'}, ...
        'Value','mC/cm^2', ...
        'ValueChangedFcn',@(~,~) refreshCICUnitDisplays());
    ddCICUnit.Layout.Row = 8; ddCICUnit.Layout.Column = 2;

    cbUseMeasuredCurrent = uicheckbox(gs,'Text','Use measured Im integration for charge (recommended)', ...
        'Value',true,'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    cbUseMeasuredCurrent.Layout.Row = 9; cbUseMeasuredCurrent.Layout.Column = [1 2];

    %% ===================== Quick info =====================
    infoUi = labkit.ui.view.section(laySR, 'Current File Summary', 1, [11 2]);
    gi = infoUi.grid;

    S.txtControlMode = labkit.ui.view.form(gi, 'info', 1, 'Control mode:');
    S.txtDetect = labkit.ui.view.form(gi, 'info', 2, 'Detection:');
    S.txtDelay = labkit.ui.view.form(gi, 'info', 3, 'Delay used:');
    S.txtArea = labkit.ui.view.form(gi, 'info', 4, 'Area:');
    S.txtEmc = labkit.ui.view.form(gi, 'info', 5, 'Emc:');
    S.txtEma = labkit.ui.view.form(gi, 'info', 6, 'Ema:');
    S.txtQc = labkit.ui.view.form(gi, 'info', 7, 'Cathodic Q/CIC:');
    S.txtQa = labkit.ui.view.form(gi, 'info', 8, 'Anodic Q/CIC:');
    S.txtQt = labkit.ui.view.form(gi, 'info', 9, 'Total Q/CIC:');
    S.txtSafe = labkit.ui.view.form(gi, 'info', 10, 'Safety:');
    S.txtBest = labkit.ui.view.form(gi, 'info', 11, 'Best safe among loaded:');

    %% ===================== Actions =====================
    actionUi = labkit.ui.view.section(layFA, 'Plot / Debug', 3, [2 3]);
    ga = actionUi.grid;

    btnRefresh = uibutton(ga,'Text','Refresh plots','ButtonPushedFcn',@(~,~) refreshPlots());
    btnRefresh.Layout.Row = 1; btnRefresh.Layout.Column = 1;
    btnSwap = uibutton(ga,'Text','Swap top / bottom','ButtonPushedFcn',@(~,~) swapPlots());
    btnSwap.Layout.Row = 1; btnSwap.Layout.Column = 2;
    btnReset = uibutton(ga,'Text','Reset axes','ButtonPushedFcn',@(~,~) resetAxes());
    btnReset.Layout.Row = 1; btnReset.Layout.Column = 3;

    cbShowMarkers = uicheckbox(ga,'Text','Show debug markers','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowMarkers.Layout.Row = 2; cbShowMarkers.Layout.Column = 1;
    cbShowLimits = uicheckbox(ga,'Text','Show window limits','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowLimits.Layout.Row = 2; cbShowLimits.Layout.Column = 2;
    cbShowShading = uicheckbox(ga,'Text','Shade pulse windows','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowShading.Layout.Row = 2; cbShowShading.Layout.Column = 3;

    %% ===================== Results table =====================
    tableUi = labkit.ui.view.panel(laySR, 'table', 'Batch Results', 2, ...
        {'File','Amp(A)','Emc(V)','Ema(V)','Qc(mC/cm^2)','Qa(mC/cm^2)','Qtot(mC/cm^2)','Safe'}, ...
        cell(0,8));
    tbl = tableUi.table;

    %% ===================== Log =====================
    logUi = labkit.ui.view.panel(layLog, 'log', 1);
    txtLog = logUi.textArea;

    %% ===================== Right: plots =====================
    topPlotDefaults = struct('x', 'Time (s)', 'y', 'VT: Vf vs time', 'grid', true);
    bottomPlotDefaults = struct('x', 'Time (s)', 'y', 'IT: Im vs time', 'grid', true);
    plotControls = labkit.ui.view.panel( ...
        ui.topControlsPanel, ...
        'topBottomPlotControls', ...
        ui.bottomControlsPanel, ...
        {'Time (s)', 'Sample #'}, ...
        {'VT: Vf vs time', 'IT: Im vs time'}, ...
        topPlotDefaults, ...
        bottomPlotDefaults, ...
        @(~,~) refreshPlots());
    ddTopX = plotControls.topX;
    ddTopY = plotControls.topY;
    cbTopGrid = plotControls.topGridCheckbox;
    axTop = ui.topAxes;
    ddBotX = plotControls.bottomX;
    ddBotY = plotControls.bottomY;
    cbBotGrid = plotControls.bottomGridCheckbox;
    axBottom = ui.bottomAxes;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('CIC debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end
    %% App callbacks, session actions, refresh, plotting, and export
    function onPresetChanged()
        switch ddPreset.Value
            case 'Pt (-0.6 to 0.8 V)'
                edCathLim.Value = -0.6;
                edAnodLim.Value = 0.8;
            case 'PEDOT:PSS (-0.9 to 0.6 V)'
                edCathLim.Value = -0.9;
                edAnodLim.Value = 0.6;
            otherwise
                % keep manual values
        end
        analyzeCurrentFile();
    end

    function onOpenFiles(~,~)
        [f,p] = uigetfile({'*.DTA;*.dta','Gamry DTA (*.DTA)';'*.*','All files'}, ...
            'Select one or more Gamry DTA files','MultiSelect','on');
        if isequal(f,0)
            addLog('Open cancelled.');
            return;
        end

        if ischar(f) || isstring(f)
            f = {char(f)};
        end

        filepaths = cellfun(@(name) fullfile(p, name), f, 'UniformOutput', false);
        loadDTAFiles(filepaths);
    end

    function onOpenFolder(~,~)
        folder = uigetdir(pwd, 'Select a folder to recursively scan for .DTA files');
        if isequal(folder,0)
            addLog('Folder selection cancelled.');
            return;
        end

        filepaths = labkit.dta.findFiles(folder);
        if isempty(filepaths)
            addLog(sprintf('No DTA files found under: %s', folder));
            uialert(fig, sprintf('No .DTA files found under:\n%s', folder), 'No files found');
            return;
        end

        addLog(sprintf('Found %d DTA file(s) under %s', numel(filepaths), folder));
        loadDTAFiles(filepaths);
    end

    function loadDTAFiles(filepaths)
        if isempty(filepaths)
            return;
        end

        filepaths = unique(filepaths, 'stable');
        callbacks = struct();
        callbacks.onAdded = @(~, ~) [];
        callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped already loaded: %s', filepath));
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));
        [S.session, report] = labkit.dta.addFilesToSession(S.session, filepaths, "chrono", callbacks);
        postProcessAddedItems(report.added);
        S.items = S.session.items;

        refreshFileList();
        restoreDefaultPlotSelections();
        resetAxesToDefaultState();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();

        if ~isempty(report.failed)
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function postProcessAddedItems(filepaths)
        for iFile = 1:numel(filepaths)
            idx = find(strcmp(string({S.session.items.filepath}), string(filepaths{iFile})), 1, 'first');
            if isempty(idx)
                continue;
            end
            item = S.session.items(idx);
            item.analysis = [];

            for ii = 1:numel(item.logmsg)
                addLog(item.logmsg{ii});
            end

            item = analyzeItem(item);
            S.session.items(idx) = item;
            addLog(sprintf('Loaded: %s', filepaths{iFile}));
        end
    end

    function analyzeCurrentFile()
        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            refreshResultsSummary();
            refreshPlots();
            return;
        end
        S.items(S.current) = analyzeItem(S.items(S.current));
        S.session.items = S.items;
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();
    end

    function item = analyzeItem(item)
        opts = struct();
        opts.delay_s = edDelayUs.Value * 1e-6;
        opts.cathLimit = edCathLim.Value;
        opts.anodLimit = edAnodLim.Value;
        opts.areaOverride = edArea.Value;
        opts.pulseMode = ddPulseMode.Value;
        opts.usedMeasuredCurrent = cbUseMeasuredCurrent.Value;

        A = cic.ops.computeCIC(item, opts);
        item.analysis = A;
        if A.ok
            addLog(sprintf('%s: Emc=%.6f V, Ema=%.6f V, safe=%d', item.name, A.Emc, A.Ema, A.safe));
        elseif isfield(A, 'logOnFailure') && A.logOnFailure
            addLog(sprintf('%s: %s', item.name, A.message));
        end
    end

    function onSelectFile()
        if isempty(lbFiles.Items)
            S.current = [];
            resetAxesToDefaultState();
            refreshResultsSummary();
            refreshPlots();
            return;
        end

        idx = find(strcmp(lbFiles.Items, lbFiles.Value), 1);
        if isempty(idx)
            S.current = [];
        else
            S.current = idx;
        end

        restoreDefaultPlotSelections();
        resetAxesToDefaultState();
        refreshResultsSummary();
        refreshPlots();
    end

    function clearAllFiles()
        S.session = labkit.dta.makeSession('cic_vt');
        S.items = S.session.items;
        S.current = [];
        restoreDefaultPlotSelections();
        resetAxesToDefaultState();
        refreshFileList();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();
        addLog('Cleared all files.');
    end

    function refreshFileList()
        if isempty(S.items)
            labkit.ui.view.update(lbFiles, 'listSelection', {});
            txtLoaded.Value = fileLabels.loadedText;
            S.current = [];
            return;
        end

        names = {S.items.name};
        [~, idx] = labkit.ui.view.update(lbFiles, 'listSelection', names, S.current);
        S.current = idx(1);
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshBatchTable()
        [~, unitLabel] = cicDisplayUnit();
        [C, columnNames] = cic.view.buildBatchTableData(S.items, unitLabel);
        tbl.ColumnName = columnNames;
        if isempty(S.items)
            tbl.Data = cell(0,8);
            return;
        end
        tbl.Data = C;
    end

    function refreshResultsSummary()
        % clear first
        S.txtControlMode.Value = '-';
        S.txtDetect.Value = '-';
        S.txtDelay.Value = '-';
        S.txtArea.Value = '-';
        S.txtEmc.Value = '-';
        S.txtEma.Value = '-';
        S.txtQc.Value = '-';
        S.txtQa.Value = '-';
        S.txtQt.Value = '-';
        S.txtSafe.Value = '-';
        S.txtBest.Value = bestSafeString();

        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            return;
        end

        it = S.items(S.current);
        S.txtControlMode.Value = chronoControlModeText(it);
        if isempty(it.analysis) || ~it.analysis.ok
            if ~isempty(it.analysis) && isfield(it.analysis,'message')
                S.txtSafe.Value = it.analysis.message;
            else
                S.txtSafe.Value = 'No valid analysis';
            end
            S.txtBest.Value = bestSafeString();
            return;
        end

        A = it.analysis;
        S.txtDetect.Value = sprintf('%s | %s', A.detectMode, A.detectMsg);
        S.txtDelay.Value = sprintf('%.3f us', 1e6 * A.delay_s);
        S.txtArea.Value = cic.view.formatMaybeNum(A.area_cm2,'%.8g cm^2');
        S.txtEmc.Value = sprintf('%.6f V @ %.6fus', A.Emc, 1e6*A.t_emc);
        S.txtEma.Value = sprintf('%.6f V @ %.6fus', A.Ema, 1e6*A.t_ema);
        S.txtQc.Value = cic.view.formatChargeDensity(A.Qc_C, A.CICc_mCcm2, ddCICUnit.Value);
        S.txtQa.Value = cic.view.formatChargeDensity(A.Qa_C, A.CICa_mCcm2, ddCICUnit.Value);
        S.txtQt.Value = cic.view.formatChargeDensity(A.Qt_C, A.CICt_mCcm2, ddCICUnit.Value);
        if A.safe
            safeText = 'SAFE';
        else
            safeText = 'UNSAFE';
        end
        S.txtSafe.Value = sprintf('%s | Emc>=%.3f? %d | Ema<=%.3f? %d', ...
            safeText, A.cathLimit, A.cathOK, A.anodLimit, A.anodOK);
        S.txtBest.Value = bestSafeString();
    end

    function out = chronoControlModeText(item)
        out = 'Unknown chrono control mode';
        if ~isfield(item, 'controlMode')
            return;
        end

        switch string(item.controlMode)
            case "current"
                out = 'Current-controlled chrono';
            case "voltage"
                out = 'Voltage-controlled chrono';
            otherwise
                out = 'Unknown chrono control mode';
        end
    end

    function out = bestSafeString()
        if isempty(S.items)
            out = '-';
            return;
        end
        safeIdx = [];
        vals = [];
        for i = 1:numel(S.items)
            if ~isempty(S.items(i).analysis) && S.items(i).analysis.ok && S.items(i).analysis.safe
                safeIdx(end+1) = i; %#ok<AGROW>
                vals(end+1) = selectedCICValue(S.items(i).analysis); %#ok<AGROW>
            end
        end
        if isempty(safeIdx)
            out = 'No safe file in current batch';
            return;
        end
        [~, imax] = max(vals);
        ii = safeIdx(imax);
        [scale, unitLabel] = cicDisplayUnit();
        out = sprintf('%s | %s = %.6g %s', S.items(ii).name, shortModeName(), scale * vals(imax), unitLabel);
    end

    function refreshCICUnitDisplays()
        refreshBatchTable();
        refreshResultsSummary();
    end

    function [scale, unitLabel] = cicDisplayUnit()
        unitLabel = ddCICUnit.Value;
        switch unitLabel
            case 'uC/cm^2'
                scale = 1e3;
            otherwise
                scale = 1;
                unitLabel = 'mC/cm^2';
        end
    end

    function v = selectedCICValue(A)
        switch ddCICMode.Value
            case 'Cathodic phase'
                v = A.CICc_mCcm2;
            case 'Anodic phase'
                v = A.CICa_mCcm2;
            otherwise
                v = A.CICt_mCcm2;
        end
    end

    function s = shortModeName()
        switch ddCICMode.Value
            case 'Cathodic phase'
                s = 'CICc';
            case 'Anodic phase'
                s = 'CICa';
            otherwise
                s = 'CICtotal';
        end
    end

    function refreshPlots()
        labkit.ui.view.draw(axTop, 'clear');
        labkit.ui.view.draw(axBottom, 'clear');
        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            title(axTop,'Top Plot');
            title(axBottom,'Bottom Plot');
            return;
        end

        it = S.items(S.current);
        if isempty(it.analysis) || ~it.analysis.ok
            title(axTop,'Top Plot');
            title(axBottom,'Bottom Plot');
            text(axTop,0.5,0.5,'No valid analysis','Units','normalized','HorizontalAlignment','center');
            return;
        end

        A = it.analysis;
        plotOneAxis(axTop, A, ddTopX.Value, ddTopY.Value, cbTopGrid.Value);
        plotOneAxis(axBottom, A, ddBotX.Value, ddBotY.Value, cbBotGrid.Value);
    end

    function plotOneAxis(ax, A, xChoice, yChoice, showGrid)
        if strcmp(xChoice,'Sample #')
            x = A.pt;
            xlab = 'Sample #';
            cathStartX = cic.ops.interp1Safe(A.t, A.pt, A.pulse.cath_start);
            cathEndX   = cic.ops.interp1Safe(A.t, A.pt, A.pulse.cath_end);
            anodStartX = cic.ops.interp1Safe(A.t, A.pt, A.pulse.anod_start);
            anodEndX   = cic.ops.interp1Safe(A.t, A.pt, A.pulse.anod_end);
            emcX       = cic.ops.interp1Safe(A.t, A.pt, A.t_emc);
            emaX       = cic.ops.interp1Safe(A.t, A.pt, A.t_ema);
        else
            x = A.t;
            xlab = 'Time (s)';
            cathStartX = A.pulse.cath_start;
            cathEndX   = A.pulse.cath_end;
            anodStartX = A.pulse.anod_start;
            anodEndX   = A.pulse.anod_end;
            emcX       = A.t_emc;
            emaX       = A.t_ema;
        end

        if startsWith(yChoice,'VT')
            y = A.Vf;
            ylab = 'Vf (V vs Ref.)';
            baseColor = [0 0.4470 0.7410];
            plot(ax, x, y, 'LineWidth',1.25, 'Color', baseColor);
            hold(ax,'on');

            if cbShowShading.Value
                cic.view.shadeWindow(ax, cathStartX, cathEndX, [0.85 0.93 1.00]);
                cic.view.shadeWindow(ax, anodStartX, anodEndX, [1.00 0.92 0.85]);
            end

            if cbShowLimits.Value
                yline(ax, A.cathLimit, '--', sprintf('Cath limit = %.3f V', A.cathLimit), ...
                    'Color',[0.85 0.2 0.2],'LabelHorizontalAlignment','left');
                yline(ax, A.anodLimit, '--', sprintf('Anod limit = %.3f V', A.anodLimit), ...
                    'Color',[0.85 0.2 0.2],'LabelHorizontalAlignment','left');
            end

            cic.view.addBaselineYLines(ax, A);

            if cbShowMarkers.Value
                xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
                xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
                xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
                xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
                cic.view.addPaperStyleVTAnnotations(ax, A, xChoice, ...
                    cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX);
            end
            hold(ax,'off');
            if A.safe
                safeText = 'SAFE';
            else
                safeText = 'UNSAFE';
            end
            ttl = sprintf('%s | VT | %s', itName(), safeText);
        else
            y = A.Im;
            ylab = 'Im (A)';
            baseColor = [0.8500 0.3250 0.0980];
            plot(ax, x, y, 'LineWidth',1.25, 'Color', baseColor);
            hold(ax,'on');

            if cbShowShading.Value
                cic.view.shadeWindow(ax, cathStartX, cathEndX, [0.85 0.93 1.00]);
                cic.view.shadeWindow(ax, anodStartX, anodEndX, [1.00 0.92 0.85]);
            end

            if cbShowMarkers.Value
                xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
                xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
                xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
                xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
                cic.view.addPaperStyleITAnnotations(ax, A, xChoice, ...
                    cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX);
            end
            hold(ax,'off');
            ttl = sprintf('%s | IT | |I|max = %.4g A', itName(), A.ampEstimate_A);
        end

        title(ax, ttl, 'Interpreter','none');
        xlabel(ax, xlab);
        ylabel(ax, ylab);
        if showGrid
            grid(ax, 'on');
        else
            grid(ax, 'off');
        end
    end

    function nm = itName()
        if isempty(S.items) || isempty(S.current), nm = 'file'; else, nm = S.items(S.current).name; end
    end

    function swapPlots()
        labkit.ui.view.update(plotControls, 'swapPlotSelections');
        refreshPlots();
    end

    function resetAxes()
        resetAxesToDefaultState();
        refreshPlots();
    end

    function restoreDefaultPlotSelections()
        labkit.ui.view.update(plotControls, 'setPlotSelections', ...
            topPlotDefaults, bottomPlotDefaults);
    end

    function resetAxesToDefaultState()
        labkit.ui.view.draw(axTop, 'reset', 'Top Plot', true);
        labkit.ui.view.draw(axBottom, 'reset', 'Bottom Plot', true);
    end

    function exportResultsCSV()
        if isempty(S.items)
            uialert(fig,'No results to export.','Export');
            return;
        end
        [f,p] = uiputfile('cic_results.csv','Save results CSV');
        if isequal(f,0)
            return;
        end
        out = fullfile(p,f);
        [~, unitLabel] = cicDisplayUnit();
        [ok, msg] = cic.export.writeResultsCSV(S.items, out, unitLabel);
        if ~ok
            uialert(fig,msg,'Export');
            return;
        end
        addLog(['Exported CSV: ' out]);
    end

    %% ===================== Logging =====================
    function addLog(msg)
        labkit.ui.view.update(txtLog, 'appendLog', msg);
        debugLog.append(msg);
    end

end
