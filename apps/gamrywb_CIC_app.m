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
        % Keep CIC numerical/export tests direct while the app owns the local workflow code.
        [handled, testOutputs] = handleCICTestRequest(varargin, nargout);
        if handled
            varargout = testOutputs;
            return;
        end
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

        filepaths = gamrywb.dta.findFiles(folder);
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

        A = computeCIC(item, opts);
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
        S.session = gamrywb.data.makeSession('cic_vt');
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
            lbFiles.Items = {};
            lbFiles.Value = {};
            txtLoaded.Value = 'No files loaded';
            S.current = [];
            return;
        end

        names = {S.items.name};
        lbFiles.Items = names;
        if isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            S.current = 1;
        end
        lbFiles.Value = names{S.current};
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshBatchTable()
        [~, unitLabel] = cicDisplayUnit();
        [C, columnNames] = buildBatchTableData(S.items, unitLabel);
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
        gamrywb.ui.hardResetAxis(axTop, 'Top Plot', true);
        gamrywb.ui.hardResetAxis(axBottom, 'Bottom Plot', true);
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
        [ok, msg] = writeResultsCSV(S.items, out, unitLabel);
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

function [handled, outputs] = handleCICTestRequest(args, nargoutRequested)
    handled = false;
    outputs = {};
    if isempty(args) || ~(ischar(args{1}) || (isstring(args{1}) && isscalar(args{1})))
        return;
    end

    handled = true;
    command = char(args{1});
    switch command
        case '__test_computeCIC__'
            assertCICTestArgCount(args, 3, command);
            if nargoutRequested > 1
                error('gamrywb_CIC_app:TooManyOutputs', 'CIC compute test request returns one result struct.');
            end
            outputs = {computeCIC(args{2}, args{3})};
        case '__test_buildBatchTableData__'
            assertCICTestArgCount(args, 3, command);
            if nargoutRequested > 2
                error('gamrywb_CIC_app:TooManyOutputs', 'CIC batch-table test request returns data and column names.');
            end
            [C, columnNames] = buildBatchTableData(args{2}, args{3});
            outputs = {C, columnNames};
            outputs = outputs(1:nargoutRequested);
        case '__test_buildResultsTable__'
            assertCICTestArgCount(args, 3, command);
            if nargoutRequested > 1
                error('gamrywb_CIC_app:TooManyOutputs', 'CIC result-table test request returns one table.');
            end
            outputs = {buildResultsTable(args{2}, args{3})};
        case '__test_writeResultsCSV__'
            assertCICTestArgCount(args, 4, command);
            if nargoutRequested > 2
                error('gamrywb_CIC_app:TooManyOutputs', 'CIC CSV test request returns at most ok and message.');
            end
            if nargoutRequested == 0
                writeResultsCSV(args{2}, args{3}, args{4});
            else
                [ok, msg] = writeResultsCSV(args{2}, args{3}, args{4});
                outputs = {ok, msg};
                outputs = outputs(1:nargoutRequested);
            end
        otherwise
            handled = false;
    end
end

function assertCICTestArgCount(args, expectedCount, command)
    if numel(args) ~= expectedCount
        error('gamrywb_CIC_app:InvalidTestRequest', ...
            '%s expects %d total input arguments.', command, expectedCount);
    end
end

function A = computeCIC(item, opts)
%COMPUTECIC Compute legacy-compatible CIC / voltage-transient metrics.

    if nargin < 2
        opts = struct();
    end
    opts = fillCICOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.delay_s = opts.delay_s;
    A.cathLimit = opts.cathLimit;
    A.anodLimit = opts.anodLimit;
    A.area_cm2 = chooseArea(item, opts);
    A.usedMeasuredCurrent = opts.usedMeasuredCurrent;
    A.logOnFailure = false;

    [curve, okCurve, msgCurve] = mainCurve(item);
    if ~okCurve
        A.message = msgCurve;
        A.logOnFailure = true;
        return;
    end

    t = gamrywb.data.getColumn(curve, 'T');
    Vf = gamrywb.data.getColumn(curve, 'Vf');
    Im = gamrywb.data.getColumn(curve, 'Im');
    pt = gamrywb.data.getColumn(curve, 'Pt');
    if isempty(pt)
        pt = (0:numel(t)-1).';
    end

    valid = ~(isnan(t) | isnan(Vf) | isnan(Im));
    t = t(valid);
    Vf = Vf(valid);
    Im = Im(valid);
    pt = pt(valid);
    if numel(t) < 5
        A.message = 'Not enough valid T/Vf/Im points.';
        return;
    end

    A.t = t;
    A.Vf = Vf;
    A.Im = Im;
    A.pt = pt;
    A.sample_dt = median(diff(t));
    A.sample_dt_report = A.sample_dt;
    A.ampEstimate_A = max(abs(Im));

    meta = struct();
    if isfield(item, 'meta')
        meta = item.meta;
    end
    [pulse, pulseMsg] = gamrywb.analysis.detectPulses(t, Im, meta, opts.pulseMode);
    A.pulse = pulse;
    A.detectMode = pulse.method;
    A.detectMsg = pulseMsg;

    if ~pulse.ok
        A.message = pulseMsg;
        A.logOnFailure = true;
        return;
    end

    V = computeVoltageTransientMetrics(t, Vf, pulse, A.delay_s);
    A = mergeStructs(A, V);

    Q = computeInjectedCharge(t, Im, pulse, A.usedMeasuredCurrent);
    A = mergeStructs(A, Q);
    if ~Q.ok
        A.message = Q.message;
        return;
    end

    if isfinite(A.area_cm2) && A.area_cm2 > 0
        A.CICc_mCcm2 = 1e3 * A.Qc_C / A.area_cm2;
        A.CICa_mCcm2 = 1e3 * A.Qa_C / A.area_cm2;
        A.CICt_mCcm2 = 1e3 * A.Qt_C / A.area_cm2;
    else
        A.CICc_mCcm2 = NaN;
        A.CICa_mCcm2 = NaN;
        A.CICt_mCcm2 = NaN;
    end

    safety = checkWaterWindowSafety(A.Emc, A.Ema, A.cathLimit, A.anodLimit);
    A = mergeStructs(A, safety);

    A.ok = true;
    A.message = 'OK';
end

function opts = fillCICOptions(opts)
    if ~isfield(opts, 'delay_s')
        opts.delay_s = 10e-6;
    end
    if ~isfield(opts, 'cathLimit')
        opts.cathLimit = -0.6;
    end
    if ~isfield(opts, 'anodLimit')
        opts.anodLimit = 0.8;
    end
    if ~isfield(opts, 'areaOverride')
        opts.areaOverride = '';
    end
    if ~isfield(opts, 'area_cm2')
        opts.area_cm2 = NaN;
    end
    if ~isfield(opts, 'pulseMode')
        opts.pulseMode = 'Metadata first, then auto';
    end
    if ~isfield(opts, 'usedMeasuredCurrent')
        opts.usedMeasuredCurrent = true;
    end
end

function area = chooseArea(item, opts)
    area = NaN;
    if isfield(opts, 'areaOverride')
        area = gamrywb.util.parsePositiveScalar(opts.areaOverride);
    end
    if ~isfinite(area) && isfield(opts, 'area_cm2')
        area = gamrywb.util.parsePositiveScalar(opts.area_cm2);
    end
    if ~isfinite(area) && isfield(item, 'meta') && isfield(item.meta, 'area_cm2') ...
            && isfinite(item.meta.area_cm2) && item.meta.area_cm2 > 0
        area = item.meta.area_cm2;
    end
end

function [curve, ok, msg] = mainCurve(item)
    if isfield(item, 'curve') && ~isempty(item.curve)
        curve = item.curve;
        ok = true;
        msg = sprintf('Using table: %s', curve.name);
    elseif isfield(item, 'tables')
        [curve, ok, msg] = gamrywb.data.getMainCurve(item.tables);
    else
        curve = struct();
        ok = false;
        msg = 'Main transient table not found.';
    end
end

function out = mergeStructs(out, in)
    names = fieldnames(in);
    for i = 1:numel(names)
        out.(names{i}) = in.(names{i});
    end
end

function V = computeVoltageTransientMetrics(t, Vf, pulse, delay_s)
    V = struct();
    V.t_emc = pulse.cath_end + delay_s;
    V.t_ema = pulse.anod_end + delay_s;
    V.emc_idx = gamrywb.util.nearestIndex(t, V.t_emc);
    V.ema_idx = gamrywb.util.nearestIndex(t, V.t_ema);
    V.Emc = interp1Safe(t, Vf, V.t_emc);
    V.Ema = interp1Safe(t, Vf, V.t_ema);

    V.Epre = gamrywb.util.medianInWindow(t, Vf, pulse.pre_start, pulse.pre_end);
    V.Ebetween = gamrywb.util.medianInWindow(t, Vf, pulse.gap_start, pulse.gap_end);
    V.Epost = gamrywb.util.medianInWindow(t, Vf, pulse.post_start, pulse.post_end);
    [V.Eipp, V.baselineCathSource, V.baselineCathWindow] = chooseBaselineCandidate( ...
        [V.Epre, V.Ebetween, V.Epost, 0], ...
        {'pre-pulse median', 'interpulse median', 'post-pulse median', 'zero fallback'}, ...
        [pulse.pre_start pulse.pre_end; pulse.gap_start pulse.gap_end; pulse.post_start pulse.post_end; NaN NaN]);
    [V.Eipp_gap, V.baselineAnodSource, V.baselineAnodWindow] = chooseBaselineCandidate( ...
        [V.Ebetween, V.Epre, V.Epost, V.Eipp], ...
        {'interpulse median', 'pre-pulse median', 'post-pulse median', 'cathodic baseline fallback'}, ...
        [pulse.gap_start pulse.gap_end; pulse.pre_start pulse.pre_end; pulse.post_start pulse.post_end; V.baselineCathWindow]);

    V.tc_s = max(0, pulse.cath_end - pulse.cath_start);
    V.ta_s = max(0, pulse.anod_end - pulse.anod_start);
    V.tip_s = max(0, pulse.anod_start - pulse.cath_end);
    V.t_conset = pulse.cath_start + delay_s;
    V.t_aonset = pulse.anod_start + delay_s;
    V.Vc_on = interp1Safe(t, Vf, V.t_conset);
    V.Va_on = interp1Safe(t, Vf, V.t_aonset);
    V.Va_cath_mag = abs(V.Eipp - V.Vc_on);
    V.Va_anod_mag = abs(V.Eipp_gap - V.Va_on);
end

function Q = computeInjectedCharge(t, Im, pulse, useMeasuredCurrent)
    if nargin < 4
        useMeasuredCurrent = true;
    end

    Q = struct();
    cathMask = (t >= pulse.cath_start) & (t <= pulse.cath_end);
    anodMask = (t >= pulse.anod_start) & (t <= pulse.anod_end);
    Q.cathMask = cathMask;
    Q.anodMask = anodMask;

    if sum(cathMask) < 2 || sum(anodMask) < 2
        Q.ok = false;
        Q.message = 'Pulse windows too short after detection.';
        return;
    end

    Q.Ic_est_A = median(Im(cathMask), 'omitnan');
    Q.Ia_est_A = median(Im(anodMask), 'omitnan');
    if ~isfinite(Q.Ic_est_A)
        Q.Ic_est_A = pulse.Ic_nominal;
    end
    if ~isfinite(Q.Ia_est_A)
        Q.Ia_est_A = pulse.Ia_nominal;
    end

    if useMeasuredCurrent
        Qc = abs(trapz(t(cathMask), Im(cathMask)));
        Qa = abs(trapz(t(anodMask), Im(anodMask)));
    else
        Qc = abs(pulse.Ic_nominal * (pulse.cath_end - pulse.cath_start));
        Qa = abs(pulse.Ia_nominal * (pulse.anod_end - pulse.anod_start));
    end

    Q.Qc_C = Qc;
    Q.Qa_C = Qa;
    Q.Qt_C = Qc + Qa;
    Q.ok = true;
    Q.message = 'OK';
end

function safety = checkWaterWindowSafety(Emc, Ema, cathLimit, anodLimit)
    safety = struct();
    safety.cathOK = Emc >= cathLimit;
    safety.anodOK = Ema <= anodLimit;
    safety.safe = safety.cathOK && safety.anodOK;

    if safety.safe
        safety.limitSide = 'safe';
    elseif ~safety.cathOK && ~safety.anodOK
        safety.limitSide = 'both exceeded';
    elseif ~safety.cathOK
        safety.limitSide = 'cathodic exceeded';
    else
        safety.limitSide = 'anodic exceeded';
    end
end

function [C, columnNames] = buildBatchTableData(items, unitLabel)
%BUILDBATCHTABLEDATA Build legacy CIC batch uitable data.

    if nargin < 2
        unitLabel = 'mC/cm^2';
    end
    [scale, unitLabel] = displayScale(unitLabel);
    columnNames = {'File', 'Amp(A)', 'Emc(V)', 'Ema(V)', ...
        ['Qc(' unitLabel ')'], ['Qa(' unitLabel ')'], ['Qtot(' unitLabel ')'], 'Safe'};

    C = cell(numel(items), 8);
    for i = 1:numel(items)
        item = items(i);
        C{i, 1} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            C{i, 2} = NaN;
            C{i, 3} = NaN;
            C{i, 4} = NaN;
            C{i, 5} = NaN;
            C{i, 6} = NaN;
            C{i, 7} = NaN;
            C{i, 8} = 'parse/analyze failed';
            continue;
        end

        C{i, 2} = A.ampEstimate_A;
        C{i, 3} = A.Emc;
        C{i, 4} = A.Ema;
        C{i, 5} = scale * A.CICc_mCcm2;
        C{i, 6} = scale * A.CICa_mCcm2;
        C{i, 7} = scale * A.CICt_mCcm2;
        C{i, 8} = ternary(A.safe, 'safe', A.limitSide);
    end
end

function T = buildResultsTable(items, unitLabel)
%BUILDRESULTSTABLE Build legacy CIC CSV result table.

    if nargin < 2
        unitLabel = 'mC/cm^2';
    end
    [scale, unitSuffix] = displayScaleSuffix(unitLabel);

    file = cell(numel(items), 1);
    amp_A = NaN(numel(items), 1);
    Emc_V = NaN(numel(items), 1);
    Ema_V = NaN(numel(items), 1);
    Qc_C = NaN(numel(items), 1);
    Qa_C = NaN(numel(items), 1);
    Qt_C = NaN(numel(items), 1);
    CICc = NaN(numel(items), 1);
    CICa = NaN(numel(items), 1);
    CICt = NaN(numel(items), 1);
    safe = zeros(numel(items), 1);
    detection = cell(numel(items), 1);

    for i = 1:numel(items)
        item = items(i);
        file{i} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            detection{i} = 'failed';
            continue;
        end

        amp_A(i) = A.ampEstimate_A;
        Emc_V(i) = A.Emc;
        Ema_V(i) = A.Ema;
        Qc_C(i) = A.Qc_C;
        Qa_C(i) = A.Qa_C;
        Qt_C(i) = A.Qt_C;
        CICc(i) = scale * A.CICc_mCcm2;
        CICa(i) = scale * A.CICa_mCcm2;
        CICt(i) = scale * A.CICt_mCcm2;
        safe(i) = A.safe;
        detection{i} = A.detectMode;
    end

    T = table(file, amp_A, Emc_V, Ema_V, Qc_C, Qa_C, Qt_C, CICc, CICa, CICt, safe, detection, ...
        'VariableNames', {'File', 'Amp_A', 'Emc_V', 'Ema_V', 'Qc_C', 'Qa_C', 'Qt_C', ...
        ['CICc_' unitSuffix], ['CICa_' unitSuffix], ['CICt_' unitSuffix], 'Safe', 'Detection'});
end

function [ok, msg] = writeResultsCSV(items, filepath, unitLabel)
%WRITERESULTSCSV Write CIC results in legacy CSV format.

    if nargin < 3
        unitLabel = 'mC/cm^2';
    end

    ok = true;
    msg = '';

    fid = fopen(filepath, 'w');
    if fid < 0
        ok = false;
        msg = 'Could not open file for writing.';
        if nargout == 0
            error(msg);
        end
        return;
    end
    cleaner = onCleanup(@() fclose(fid));

    try
        T = buildResultsTable(items, unitLabel);
        names = T.Properties.VariableNames;
        fprintf(fid, 'File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,%s,%s,%s,Safe,Detection\n', ...
            names{8}, names{9}, names{10});
        for i = 1:height(T)
            if strcmp(T.Detection{i}, 'failed')
                fprintf(fid, '"%s",,,,,,,,,,0,"failed"\n', T.File{i});
            else
                fprintf(fid, '"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%d,"%s"\n', ...
                    T.File{i}, T.Amp_A(i), T.Emc_V(i), T.Ema_V(i), T.Qc_C(i), T.Qa_C(i), T.Qt_C(i), ...
                    T.(names{8})(i), T.(names{9})(i), T.(names{10})(i), T.Safe(i), T.Detection{i});
            end
        end
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end

function v = interp1Safe(x, y, xq)
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

function [v, sourceLabel, window] = chooseBaselineCandidate(candidates, sourceLabels, windows)
    v = NaN;
    sourceLabel = 'unavailable';
    window = [NaN NaN];
    for k = 1:numel(candidates)
        if isfinite(candidates(k))
            v = candidates(k);
            sourceLabel = sourceLabels{k};
            if size(windows, 1) >= k
                window = windows(k, :);
            end
            return;
        end
    end
end

function [scale, unitLabel] = displayScale(unitLabel)
    switch unitLabel
        case 'uC/cm^2'
            scale = 1e3;
        otherwise
            scale = 1;
            unitLabel = 'mC/cm^2';
    end
end

function [scale, unitSuffix] = displayScaleSuffix(unitLabel)
    [scale, unitLabel] = displayScale(unitLabel);
    unitSuffix = regexprep(unitLabel, '[\^/]', '');
end

function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
    else
        name = '';
    end
end

function A = itemAnalysis(item)
    if isfield(item, 'analysis')
        A = item.analysis;
    else
        A = [];
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
