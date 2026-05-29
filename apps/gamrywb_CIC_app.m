function varargout = gamrywb_CIC_app(varargin)
%GAMRYWB_CIC_APP Launch the CIC voltage-transient app.
% GUI for calculating CIC from Gamry MULTI_STEP_CHRONOPOT .DTA files.
% Layout updated to 3 left-side tabs with vertical file actions.
%
% Main features
%   - Parses Gamry chronopotentiometry DTA files (MULTI_STEP_CHRONOPOT)
%   - Supports loading one or multiple files
%   - Extracts pulse timing from ISTEP/TSTEP metadata when available
%   - Falls back to current-based automatic pulse detection when needed
%   - Calculates voltage-transient metrics used for CIC evaluation:
%         Emc = Vf at (end of cathodic pulse + delay)
%         Ema = Vf at (end of anodic   pulse + delay)
%   - Calculates injected charge from the measured current waveform
%   - Reports per-phase and total charge densities
%   - Highlights selected voltage points and pulse windows on VT / IT plots
%
% Notes
%   - This GUI is for single transient files and batch comparison across files.
%   - True "CIC limit" usually comes from a series of files acquired at different
%     current amplitudes; the GUI therefore marks each file safe/unsafe and also
%     reports the highest safe file among all loaded files.
%   - By default, the evaluation point is 10 us after the end of each phase,
%     matching the convention commonly used in the literature the user shared.
    if nargin > 0
        error('gamrywb_CIC_app:UnsupportedInput', 'gamrywb_CIC_app does not accept input arguments.');
    end
    if nargout > 1
        error('gamrywb_CIC_app:TooManyOutputs', 'gamrywb_CIC_app returns at most the app figure handle.');
    end

    S = struct();
    S.session = gamrywb.data.makeSession('cic_vt');
    S.items = S.session.items; % loaded files + parsed content + analysis
    S.current = [];
    S.isDragging = false;

    %% ===================== Figure & Layout =====================
    ui = gamrywb.ui.createTabbedDualPlotShell( ...
        'Gamry CIC GUI (Voltage Transient)', ...
        [40 30 1680 980], ...
        430, ...
        @startDrag);
    fig = ui.fig;
    main = ui.main;
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
    fileUi = gamrywb.ui.createSingleSelectFilePanel(layFA, 'Export results CSV', fileCallbacks);
    lbFiles = fileUi.listbox;
    txtLoaded = fileUi.loadedText;

    %% ===================== Analysis settings =====================
    pSet = uipanel(layFA,'Title','Analysis Settings');
    pSet.Layout.Row = 2;
    gs = uigridlayout(pSet,[9 2]);
    gs.RowHeight = repmat({'fit'},1,9);
    gs.ColumnWidth = {'fit','1x'};
    gs.Padding = [8 8 8 8];
    gs.ColumnSpacing = 8;

    uilabel(gs,'Text','Window preset:','HorizontalAlignment','right');
    ddPreset = uidropdown(gs, ...
        'Items',{'Pt (-0.6 to 0.8 V)','PEDOT:PSS (-0.9 to 0.6 V)','Custom'}, ...
        'Value','Pt (-0.6 to 0.8 V)', ...
        'ValueChangedFcn',@(~,~) onPresetChanged());
    ddPreset.Layout.Row = 1; ddPreset.Layout.Column = 2;

    uilabel(gs,'Text','Cathodic limit (V):','HorizontalAlignment','right');
    edCathLim = uieditfield(gs,'numeric','Value',-0.6,'Limits',[-10 10], ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
    edCathLim.Layout.Row = 2; edCathLim.Layout.Column = 2;

    uilabel(gs,'Text','Anodic limit (V):','HorizontalAlignment','right');
    edAnodLim = uieditfield(gs,'numeric','Value',0.8,'Limits',[-10 10], ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
    edAnodLim.Layout.Row = 3; edAnodLim.Layout.Column = 2;

    uilabel(gs,'Text','Sample delay after pulse end:','HorizontalAlignment','right');
    edDelayUs = uieditfield(gs,'numeric','Value',10,'Limits',[0 inf], ...
        'ValueDisplayFormat','%.6g','ValueChangedFcn',@(~,~) analyzeCurrentFile());
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
    pInfo = uipanel(laySR,'Title','Current File Summary');
    pInfo.Layout.Row = 1;
    gi = uigridlayout(pInfo,[10 2]);
    gi.RowHeight = repmat({'fit'},1,10);
    gi.ColumnWidth = {'fit','1x'};
    gi.Padding = [8 8 8 8];
    gi.ColumnSpacing = 8;

    S.txtDetect = gamrywb.ui.createReadOnlyInfoRow(gi,1,'Detection:');
    S.txtDelay = gamrywb.ui.createReadOnlyInfoRow(gi,2,'Delay used:');
    S.txtArea = gamrywb.ui.createReadOnlyInfoRow(gi,3,'Area:');
    S.txtEmc = gamrywb.ui.createReadOnlyInfoRow(gi,4,'Emc:');
    S.txtEma = gamrywb.ui.createReadOnlyInfoRow(gi,5,'Ema:');
    S.txtQc = gamrywb.ui.createReadOnlyInfoRow(gi,6,'Cathodic Q/CIC:');
    S.txtQa = gamrywb.ui.createReadOnlyInfoRow(gi,7,'Anodic Q/CIC:');
    S.txtQt = gamrywb.ui.createReadOnlyInfoRow(gi,8,'Total Q/CIC:');
    S.txtSafe = gamrywb.ui.createReadOnlyInfoRow(gi,9,'Safety:');
    S.txtBest = gamrywb.ui.createReadOnlyInfoRow(gi,10,'Best safe among loaded:');

    %% ===================== Actions =====================
    pAct = uipanel(layFA,'Title','Plot / Debug');
    pAct.Layout.Row = 3;
    ga = uigridlayout(pAct,[2 3]);
    ga.RowHeight = {'fit','fit'};
    ga.ColumnWidth = {'1x','1x','1x'};
    ga.Padding = [8 8 8 8];
    ga.ColumnSpacing = 8;

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
    tableUi = gamrywb.ui.createResultTablePanel(laySR, 'Batch Results', 2, ...
        {'File','Amp(A)','Emc(V)','Ema(V)','Qc(mC/cm^2)','Qa(mC/cm^2)','Qtot(mC/cm^2)','Safe'}, ...
        cell(0,8));
    tbl = tableUi.table;

    %% ===================== Log =====================
    logUi = gamrywb.ui.createLogPanel(layLog, 1);
    txtLog = logUi.textArea;

    %% ===================== Right: plots =====================
    topPlotDefaults = struct('x', 'Time (s)', 'y', 'VT: Vf vs time', 'grid', true);
    bottomPlotDefaults = struct('x', 'Time (s)', 'y', 'IT: Im vs time', 'grid', true);
    plotControls = gamrywb.ui.createTopBottomPlotControls( ...
        ui.topControlsPanel, ...
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
    if nargout == 1
        varargout{1} = fig;
    end

    onPresetChanged();

    %% ===================== Nested helpers =====================
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

        filepaths = gamrywb.io.findDTAFilesRecursive(folder);
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
        callbacks.onAdded = @(filepath, item) addLog(sprintf('Loaded: %s', filepath)); %#ok<INUSD>
        callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped already loaded: %s', filepath));
        callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));
        [S.session, report] = gamrywb.data.addFilesToSession(S.session, filepaths, @loadOneDTA, callbacks);
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

    function item = loadOneDTA(filepath)
        [item, status] = gamrywb.dta.loadFile(filepath, "chrono");
        if ~status.ok
            error('gamrywb_CIC_app:LoadFailed', '%s', status.message);
        end
        item.analysis = [];

        for ii = 1:numel(item.logmsg)
            addLog(item.logmsg{ii});
        end

        item = analyzeItem(item);
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

        A = gamrywb_apps.cic.computeCIC(item, opts);
        item.analysis = A;
        if A.ok
            addLog(sprintf('%s: Emc=%.6f V, Ema=%.6f V, safe=%d', item.name, A.Emc, A.Ema, A.safe));
        elseif isfield(A, 'logOnFailure') && A.logOnFailure
            addLog(sprintf('%s: %s', item.name, A.message));
        end
    end

    function onSelectFile()
        selectionCallbacks = struct();
        selectionCallbacks.restoreDefaultPlotSelections = @restoreDefaultPlotSelections;
        selectionCallbacks.resetAxesToDefaultState = @resetAxesToDefaultState;
        selectionCallbacks.refreshResultsSummary = @refreshResultsSummary;
        selectionCallbacks.refreshPlots = @refreshPlots;
        S.current = gamrywb.ui.handleSingleFileSelection(lbFiles, selectionCallbacks);
    end

    function clearAllFiles()
        clearCallbacks = struct();
        clearCallbacks.applyState = @applyClearState;
        clearCallbacks.restoreDefaultPlotSelections = @restoreDefaultPlotSelections;
        clearCallbacks.resetAxesToDefaultState = @resetAxesToDefaultState;
        clearCallbacks.refreshFileList = @refreshFileList;
        clearCallbacks.refreshBatchTable = @refreshBatchTable;
        clearCallbacks.refreshResultsSummary = @refreshResultsSummary;
        clearCallbacks.refreshPlots = @refreshPlots;
        clearCallbacks.addLog = @addLog;
        gamrywb.ui.handleClearSingleFileSession('cic_vt', clearCallbacks);
    end

    function applyClearState(session, items, current)
        S.session = session;
        S.items = items;
        S.current = current;
    end

    function refreshFileList()
        S.current = gamrywb.ui.refreshSingleSelectFileListbox(lbFiles, txtLoaded, S.items, S.current);
    end

    function refreshBatchTable()
        [~, unitLabel] = cicDisplayUnit();
        [C, columnNames] = gamrywb_apps.cic.buildBatchTableData(S.items, unitLabel);
        tbl.ColumnName = columnNames;
        if isempty(S.items)
            tbl.Data = cell(0,8);
            return;
        end
        tbl.Data = C;
    end

    function refreshResultsSummary()
        % clear first
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
        S.txtArea.Value = formatMaybeNum(A.area_cm2,'%.8g cm^2');
        S.txtEmc.Value = sprintf('%.6f V @ %.6fus', A.Emc, 1e6*A.t_emc);
        S.txtEma.Value = sprintf('%.6f V @ %.6fus', A.Ema, 1e6*A.t_ema);
        S.txtQc.Value = formatChargeDensity(A.Qc_C, A.CICc_mCcm2, ddCICUnit.Value);
        S.txtQa.Value = formatChargeDensity(A.Qa_C, A.CICa_mCcm2, ddCICUnit.Value);
        S.txtQt.Value = formatChargeDensity(A.Qt_C, A.CICt_mCcm2, ddCICUnit.Value);
        S.txtSafe.Value = sprintf('%s | Emc>=%.3f? %d | Ema<=%.3f? %d', ...
            ternary(A.safe,'SAFE','UNSAFE'), A.cathLimit, A.cathOK, A.anodLimit, A.anodOK);
        S.txtBest.Value = bestSafeString();
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
        gamrywb.ui.clearAxisObjects(axTop);
        gamrywb.ui.clearAxisObjects(axBottom);
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
            cathStartX = interp1_safe(A.t, A.pt, A.pulse.cath_start);
            cathEndX   = interp1_safe(A.t, A.pt, A.pulse.cath_end);
            anodStartX = interp1_safe(A.t, A.pt, A.pulse.anod_start);
            anodEndX   = interp1_safe(A.t, A.pt, A.pulse.anod_end);
            emcX       = interp1_safe(A.t, A.pt, A.t_emc);
            emaX       = interp1_safe(A.t, A.pt, A.t_ema);
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
                shadeWindow(ax, cathStartX, cathEndX, [0.85 0.93 1.00]);
                shadeWindow(ax, anodStartX, anodEndX, [1.00 0.92 0.85]);
            end

            if cbShowLimits.Value
                yline(ax, A.cathLimit, '--', sprintf('Cath limit = %.3f V', A.cathLimit), ...
                    'Color',[0.85 0.2 0.2],'LabelHorizontalAlignment','left');
                yline(ax, A.anodLimit, '--', sprintf('Anod limit = %.3f V', A.anodLimit), ...
                    'Color',[0.85 0.2 0.2],'LabelHorizontalAlignment','left');
            end

            addBaselineYLines(ax, A);

            if cbShowMarkers.Value
                xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
                xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
                xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
                xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
                addPaperStyleVTAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX);
            end
            hold(ax,'off');
            ttl = sprintf('%s | VT | %s', itName(), ternary(A.safe,'SAFE','UNSAFE'));
        else
            y = A.Im;
            ylab = 'Im (A)';
            baseColor = [0.8500 0.3250 0.0980];
            plot(ax, x, y, 'LineWidth',1.25, 'Color', baseColor);
            hold(ax,'on');

            if cbShowShading.Value
                shadeWindow(ax, cathStartX, cathEndX, [0.85 0.93 1.00]);
                shadeWindow(ax, anodStartX, anodEndX, [1.00 0.92 0.85]);
            end

            if cbShowMarkers.Value
                xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
                xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
                xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
                xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
                addPaperStyleITAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX);
            end
            hold(ax,'off');
            ttl = sprintf('%s | IT | |I|max = %.4g A', itName(), A.ampEstimate_A);
        end

        title(ax, ttl, 'Interpreter','none');
        xlabel(ax, xlab);
        ylabel(ax, ylab);
        grid(ax, ternary(showGrid,'on','off'));
    end

    function nm = itName()
        if isempty(S.items) || isempty(S.current), nm = 'file'; else, nm = S.items(S.current).name; end
    end

    function swapPlots()
        gamrywb.ui.swapTopBottomPlotSelections(ddTopX, ddTopY, ddBotX, ddBotY);
        refreshPlots();
    end

    function resetAxes()
        resetAxesToDefaultState();
        refreshPlots();
    end

    function restoreDefaultPlotSelections()
        gamrywb.ui.setTopBottomPlotSelections(ddTopX, ddTopY, ddBotX, ddBotY, ...
            topPlotDefaults, bottomPlotDefaults);
    end

    function resetAxesToDefaultState()
        gamrywb.ui.resetTopBottomAxes(axTop, axBottom, true);
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
        [ok, msg] = gamrywb_apps.cic.writeResultsCSV(S.items, out, unitLabel);
        if ~ok
            uialert(fig,msg,'Export');
            return;
        end
        addLog(['Exported CSV: ' out]);
    end

    %% ===================== Drag separator =====================
    function startDrag(~,~)
        S.isDragging = true;
        fig.WindowButtonMotionFcn = @doDrag;
        fig.WindowButtonUpFcn = @stopDrag;
        fig.Pointer = 'left';
    end

    function doDrag(~,~)
        if ~S.isDragging, return; end
        cp = fig.CurrentPoint;
        pad = main.Padding;
        newW = cp(1) - pad(1);
        minW = 260;
        maxW = max(420, fig.Position(3) - 380);
        newW = min(maxW, max(minW, newW));
        main.ColumnWidth = {newW,6,'1x'};
    end

    function stopDrag(~,~)
        S.isDragging = false;
        fig.WindowButtonMotionFcn = '';
        fig.WindowButtonUpFcn = '';
        fig.Pointer = 'arrow';
    end

    %% ===================== Logging =====================
    function addLog(msg)
        gamrywb.ui.appendLog(txtLog, msg);
    end

end

%% ========================================================================
%% =============================== Utilities ===============================
%% ========================================================================
function v = interp1_safe(x, y, xq)
    if numel(x) < 2 || any(~isfinite([x(:); y(:)]))
        v = NaN;
        return;
    end
    try
        v = interp1(x, y, xq, 'linear', 'extrap');
    catch
        idx = gamrywb.util.nearestIndex(x, xq);
        v = y(idx);
    end
end

function out = formatChargeDensity(Q_C, cic_mCcm2, unitLabel)
    if isfinite(cic_mCcm2)
        switch unitLabel
            case 'uC/cm^2'
                cic = 1e3 * cic_mCcm2;
            otherwise
                cic = cic_mCcm2;
                unitLabel = 'mC/cm^2';
        end
        out = sprintf('%.6e C | %.6f %s', Q_C, cic, unitLabel);
    else
        out = sprintf('%.6e C | area unavailable', Q_C);
    end
end

function s = formatMaybeNum(v, fmt)
    if isfinite(v)
        s = sprintf(fmt, v);
    else
        s = 'NaN';
    end
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end

function shadeWindow(ax, x1, x2, color)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1
        return;
    end
    yl = ylim(ax);
    patch(ax,[x1 x2 x2 x1],[yl(1) yl(1) yl(2) yl(2)],color, ...
        'FaceAlpha',0.25,'EdgeColor','none','HandleVisibility','off');
    uistack(findobj(ax,'Type','patch'),'bottom');
end

function labelPulseCharge(ax, x1, x2, Q, tagText)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1
        return;
    end
    xm = 0.5 * (x1 + x2);
    yl = ylim(ax);
    y0 = yl(1) + 0.90 * (yl(2) - yl(1));
    text(ax, xm, y0, sprintf('%s = %.3e C', tagText, Q), ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'BackgroundColor','w','Margin',2);
end

function addPaperStyleVTAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX)
    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.07*dy;
    yMid = yl(1) + 0.55*dy;
    yLow = yl(1) + 0.18*dy;

    if strcmp(xChoice,'Sample #')
        cOnX = interp1_safe(A.t, A.pt, A.t_conset);
        aOnX = interp1_safe(A.t, A.pt, A.t_aonset);
        cathBase1 = interp1_safe(A.t, A.pt, A.baselineCathWindow(1));
        cathBase2 = interp1_safe(A.t, A.pt, A.baselineCathWindow(2));
        anodBase1 = interp1_safe(A.t, A.pt, A.baselineAnodWindow(1));
        anodBase2 = interp1_safe(A.t, A.pt, A.baselineAnodWindow(2));
    else
        cOnX = A.t_conset;
        aOnX = A.t_aonset;
        cathBase1 = A.baselineCathWindow(1);
        cathBase2 = A.baselineCathWindow(2);
        anodBase1 = A.baselineAnodWindow(1);
        anodBase2 = A.baselineAnodWindow(2);
    end

    plot(ax, emcX, A.Emc, 'o', 'MarkerFaceColor',[0.1 0.7 0.1], 'MarkerEdgeColor','k', 'MarkerSize',7);
    plot(ax, emaX, A.Ema, 'o', 'MarkerFaceColor',[0.95 0.8 0.1], 'MarkerEdgeColor','k', 'MarkerSize',7);
    plot(ax, cOnX, A.Vc_on, 's', 'MarkerFaceColor',[0.2 0.6 1.0], 'MarkerEdgeColor','k', 'MarkerSize',6);
    plot(ax, aOnX, A.Va_on, 's', 'MarkerFaceColor',[1.0 0.6 0.2], 'MarkerEdgeColor','k', 'MarkerSize',6);

    if isfinite(A.Eipp)
        drawBaselineSegment(ax, cathBase1, cathBase2, A.Eipp, [0.25 0.25 0.25], ...
            sprintf('Baseline(cath) = %.3f V [%s]', A.Eipp, shortBaselineSource(A.baselineCathSource)), 'bottom');
    end
    if isfinite(A.Eipp_gap)
        drawBaselineSegment(ax, anodBase1, anodBase2, A.Eipp_gap, [0.45 0.45 0.45], ...
            sprintf('Baseline(anod) = %.3f V [%s]', A.Eipp_gap, shortBaselineSource(A.baselineAnodSource)), 'top');
    end

    if isfinite(A.Eipp) && isfinite(A.Vc_on)
        plot(ax, [cOnX cOnX], [A.Eipp A.Vc_on], '--', 'Color',[0.2 0.6 1.0], 'LineWidth',1.0);
        text(ax, cOnX, 0.5*(A.Eipp + A.Vc_on), sprintf(' Va(c)=%.3f V', A.Va_cath_mag), ...
            'Color',[0.15 0.45 0.8], 'VerticalAlignment','middle', 'HorizontalAlignment','left');
    end
    if isfinite(A.Eipp_gap) && isfinite(A.Va_on)
        plot(ax, [aOnX aOnX], [A.Eipp_gap A.Va_on], '--', 'Color',[0.95 0.55 0.2], 'LineWidth',1.0);
        text(ax, aOnX, 0.5*(A.Eipp_gap + A.Va_on), sprintf(' Va(a)=%.3f V', A.Va_anod_mag), ...
            'Color',[0.75 0.35 0.05], 'VerticalAlignment','middle', 'HorizontalAlignment','left');
    end

    text(ax, emcX, A.Emc, sprintf(' Emc = %.4f V', A.Emc), 'VerticalAlignment','bottom', 'Color',[0.1 0.5 0.1]);
    text(ax, emaX, A.Ema, sprintf(' Ema = %.4f V', A.Ema), 'VerticalAlignment','top', 'Color',[0.6 0.4 0]);

    drawDurationBracket(ax, cathStartX, cathEndX, yTop, sprintf('tc = %.3f ms', 1e3*A.tc_s));
    drawDurationBracket(ax, anodStartX, anodEndX, yTop - 0.06*dy, sprintf('ta = %.3f ms', 1e3*A.ta_s));
    if A.tip_s > 0 && anodStartX > cathEndX
        drawDurationBracket(ax, cathEndX, anodStartX, yLow, sprintf('tip = %.1f us', 1e6*A.tip_s));
    end
    yline(ax, yMid, ':', 'Color',[0.8 0.8 0.8], 'HandleVisibility','off');
end

function addPaperStyleITAnnotations(ax, A, xChoice, cathStartX, cathEndX, anodStartX, anodEndX, emcX, emaX)
    plot(ax, emcX, interp1_safe(chooseX(A,xChoice), A.Im, emcX), 'o', 'MarkerFaceColor',[0.1 0.7 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);
    plot(ax, emaX, interp1_safe(chooseX(A,xChoice), A.Im, emaX), 'o', 'MarkerFaceColor',[0.95 0.8 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

    plot(ax, [cathStartX cathEndX], [A.Ic_est_A A.Ic_est_A], '--', 'Color',[0.1 0.45 0.8], 'LineWidth',1.3);
    plot(ax, [anodStartX anodEndX], [A.Ia_est_A A.Ia_est_A], '--', 'Color',[0.85 0.45 0.1], 'LineWidth',1.3);
    text(ax, cathEndX, A.Ic_est_A, sprintf('  ic = %.3f mA', 1e3*A.Ic_est_A), 'Color',[0.1 0.35 0.75], 'VerticalAlignment','bottom');
    text(ax, anodEndX, A.Ia_est_A, sprintf('  ia = %.3f mA', 1e3*A.Ia_est_A), 'Color',[0.7 0.32 0.05], 'VerticalAlignment','top');

    labelPulseCharge(ax, cathStartX, cathEndX, A.Qc_C, 'Qc');
    labelPulseCharge(ax, anodStartX, anodEndX, A.Qa_C, 'Qa');

    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.08*dy;
    yMid = yl(2) - 0.16*dy;
    drawDurationBracket(ax, cathStartX, cathEndX, yTop, sprintf('tc = %.3f ms', 1e3*A.tc_s));
    drawDurationBracket(ax, anodStartX, anodEndX, yTop, sprintf('ta = %.3f ms', 1e3*A.ta_s));
    if A.tip_s > 0 && anodStartX > cathEndX
        drawDurationBracket(ax, cathEndX, anodStartX, yMid, sprintf('tip = %.1f us', 1e6*A.tip_s));
    end
end

function drawDurationBracket(ax, x1, x2, y, labelText)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1 || ~isfinite(y)
        return;
    end
    yl = ylim(ax);
    h = 0.025 * (yl(2) - yl(1));
    plot(ax, [x1 x2], [y y], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    plot(ax, [x1 x1], [y-h y+h], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    plot(ax, [x2 x2], [y-h y+h], 'k-', 'LineWidth',1.0, 'HandleVisibility','off');
    text(ax, 0.5*(x1+x2), y + 1.4*h, labelText, 'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', 'BackgroundColor','w', 'Margin',1);
end

function drawBaselineSegment(ax, x1, x2, y, color, labelText, verticalAlignment)
    if ~isfinite(y)
        return;
    end
    if isfinite(x1) && isfinite(x2) && x2 > x1
        xStart = x1;
        xEnd = x2;
    else
        xl = xlim(ax);
        xStart = xl(1) + 0.04 * (xl(2) - xl(1));
        xEnd = xStart + 0.18 * (xl(2) - xl(1));
    end
    plot(ax, [xStart xEnd], [y y], '--', 'Color', color, 'LineWidth',1.4, 'HandleVisibility','off');
    text(ax, xStart, y, [' ' labelText], 'Color', color, 'VerticalAlignment', verticalAlignment, ...
        'BackgroundColor','w', 'Margin',1, 'Interpreter','none');
end

function addBaselineYLines(ax, A)
    if isfinite(A.Eipp)
        yline(ax, A.Eipp, '--', ...
            sprintf('Baseline(cath) = %.3f V [%s]', A.Eipp, shortBaselineSource(A.baselineCathSource)), ...
            'Color',[0.20 0.20 0.20], 'LabelHorizontalAlignment','right', 'LabelVerticalAlignment','bottom');
    end
    if isfinite(A.Eipp_gap)
        yline(ax, A.Eipp_gap, '--', ...
            sprintf('Baseline(anod) = %.3f V [%s]', A.Eipp_gap, shortBaselineSource(A.baselineAnodSource)), ...
            'Color',[0.40 0.40 0.40], 'LabelHorizontalAlignment','right', 'LabelVerticalAlignment','top');
    end
end

function x = chooseX(A, xChoice)
    if strcmp(xChoice, 'Sample #')
        x = A.pt;
    else
        x = A.t;
    end
end

function v = chooseFinite(varargin)
    v = NaN;
    for k = 1:nargin
        if isfinite(varargin{k})
            v = varargin{k};
            return;
        end
    end
end

function s = shortBaselineSource(sourceLabel)
    switch sourceLabel
        case 'pre-pulse median'
            s = 'pre';
        case 'interpulse median'
            s = 'gap';
        case 'post-pulse median'
            s = 'post';
        case 'zero fallback'
            s = '0 V fallback';
        case 'cathodic baseline fallback'
            s = 'cath fallback';
        otherwise
            s = sourceLabel;
    end
end
