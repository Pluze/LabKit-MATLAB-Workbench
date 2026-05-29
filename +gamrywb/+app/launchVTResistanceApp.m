function varargout = launchVTResistanceApp(varargin)
%LAUNCHVTRESISTANCEAPP Launch the package-backed VT resistance app.
% GUI for estimating cathodic/anodic steady-state resistance from Gamry
% MULTI_STEP_CHRONOPOT .DTA files.
%
% The pulse detection and current estimation follow the CIC VT GUI pattern:
%   - Use ISTEP/TSTEP metadata first, with optional current-waveform fallback.
%   - Estimate phase current by median(Im) in the selected pulse window.
%   - Estimate steady phase voltage by median(Vf) in the same selected window.
%   - Compute baseline-corrected resistance as abs((Vss - Vbaseline) / Iss).

    if nargin > 0
        error('gamrywb_VTResistance_app:UnsupportedInput', 'gamrywb_VTResistance_app does not accept input arguments.');
    end
    if nargout > 1
        error('gamrywb_VTResistance_app:TooManyOutputs', 'gamrywb_VTResistance_app returns at most the app figure handle.');
    end

    S = struct();
    S.session = gamrywb.data.makeSession('vt_resistance');
    S.items = S.session.items;
    S.current = [];
    S.isDragging = false;

    ui = gamrywb.ui.createTabbedDualPlotShell( ...
        'Gamry VT Steady Resistance GUI', ...
        [40 30 1680 980], ...
        430, ...
        @startDrag);
    fig = ui.fig;
    main = ui.main;
    layFA = ui.filesAnalysisGrid;
    laySR = ui.summaryResultsGrid;
    layLog = ui.logGrid;

    fileCallbacks = struct();
    fileCallbacks.onOpenFiles = @onOpenFiles;
    fileCallbacks.onOpenFolder = @onOpenFolder;
    fileCallbacks.onClearAll = @(~,~) clearAllFiles();
    fileCallbacks.onExport = @(~,~) exportResultsCSV();
    fileCallbacks.onSelectFile = @(~,~) onSelectFile();
    fileUi = gamrywb.ui.createSingleSelectFilePanel(layFA, 'Export results CSV', fileCallbacks);
    lbFiles = fileUi.listbox;
    txtLoaded = fileUi.loadedText;

    pSet = uipanel(layFA,'Title','Analysis Settings');
    pSet.Layout.Row = 2;
    gs = uigridlayout(pSet,[3 2]);
    gs.RowHeight = repmat({'fit'},1,3);
    gs.ColumnWidth = {'fit','1x'};
    gs.Padding = [8 8 8 8];
    gs.ColumnSpacing = 8;

    uilabel(gs,'Text','Pulse detection:','HorizontalAlignment','right');
    ddPulseMode = uidropdown(gs, ...
        'Items',{'Metadata first, then auto','Metadata only','Auto from Im only'}, ...
        'Value','Metadata first, then auto', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    ddPulseMode.Layout.Row = 1;
    ddPulseMode.Layout.Column = 2;

    uilabel(gs,'Text','Steady window:','HorizontalAlignment','right');
    ddSteadyWindow = uidropdown(gs, ...
        'Items',{'Full pulse median','Center 60% median'}, ...
        'Value','Full pulse median', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    ddSteadyWindow.Layout.Row = 2;
    ddSteadyWindow.Layout.Column = 2;

    uilabel(gs,'Text','Resistance voltage:','HorizontalAlignment','right');
    ddVoltageMode = uidropdown(gs, ...
        'Items',{'Baseline-corrected dV/I','Raw Vf/I'}, ...
        'Value','Baseline-corrected dV/I', ...
        'ValueChangedFcn',@(~,~) analyzeCurrentFile());
    ddVoltageMode.Layout.Row = 3;
    ddVoltageMode.Layout.Column = 2;

    pAct = uipanel(layFA,'Title','Plot / Debug');
    pAct.Layout.Row = 3;
    ga = uigridlayout(pAct,[2 3]);
    ga.RowHeight = {'fit','fit'};
    ga.ColumnWidth = {'1x','1x','1x'};
    ga.Padding = [8 8 8 8];
    ga.ColumnSpacing = 8;

    btnReanalyze = uibutton(ga,'Text','Re-analyze file','ButtonPushedFcn',@(~,~) analyzeCurrentFile());
    btnReanalyze.Layout.Row = 1; btnReanalyze.Layout.Column = 1;
    btnRefresh = uibutton(ga,'Text','Refresh plots','ButtonPushedFcn',@(~,~) refreshPlots());
    btnRefresh.Layout.Row = 1; btnRefresh.Layout.Column = 2;
    btnSwap = uibutton(ga,'Text','Swap top / bottom','ButtonPushedFcn',@(~,~) swapPlots());
    btnSwap.Layout.Row = 1; btnSwap.Layout.Column = 3;

    btnReset = uibutton(ga,'Text','Reset axes','ButtonPushedFcn',@(~,~) resetAxes());
    btnReset.Layout.Row = 2; btnReset.Layout.Column = 1;
    cbShowMarkers = uicheckbox(ga,'Text','Show markers','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowMarkers.Layout.Row = 2; cbShowMarkers.Layout.Column = 2;
    cbShowShading = uicheckbox(ga,'Text','Shade windows','Value',true,'ValueChangedFcn',@(~,~) refreshPlots());
    cbShowShading.Layout.Row = 2; cbShowShading.Layout.Column = 3;

    pInfo = uipanel(laySR,'Title','Current File Summary');
    pInfo.Layout.Row = 1;
    gi = uigridlayout(pInfo,[12 2]);
    gi.RowHeight = repmat({'fit'},1,12);
    gi.ColumnWidth = {'fit','1x'};
    gi.Padding = [8 8 8 8];
    gi.ColumnSpacing = 8;

    S.txtDetect = gamrywb.ui.createReadOnlyInfoRow(gi,1,'Detection:');
    S.txtWindow = gamrywb.ui.createReadOnlyInfoRow(gi,2,'Window:');
    S.txtCathIV = gamrywb.ui.createReadOnlyInfoRow(gi,3,'Cathodic I / Vss:');
    S.txtAnodIV = gamrywb.ui.createReadOnlyInfoRow(gi,4,'Anodic I / Vss:');
    S.txtCathBase = gamrywb.ui.createReadOnlyInfoRow(gi,5,'Cathodic baseline:');
    S.txtAnodBase = gamrywb.ui.createReadOnlyInfoRow(gi,6,'Anodic baseline:');
    S.txtCathBaseWin = gamrywb.ui.createReadOnlyInfoRow(gi,7,'Cath baseline window:');
    S.txtAnodBaseWin = gamrywb.ui.createReadOnlyInfoRow(gi,8,'Anod baseline window:');
    S.txtCathR = gamrywb.ui.createReadOnlyInfoRow(gi,9,'Cathodic R:');
    S.txtAnodR = gamrywb.ui.createReadOnlyInfoRow(gi,10,'Anodic R:');
    S.txtAvgR = gamrywb.ui.createReadOnlyInfoRow(gi,11,'Average R:');
    S.txtStatus = gamrywb.ui.createReadOnlyInfoRow(gi,12,'Status:');

    pTab = uipanel(laySR,'Title','Batch Results');
    pTab.Layout.Row = 2;
    gt = uigridlayout(pTab,[1 1]);
    gt.Padding = [8 8 8 8];
    tbl = uitable(gt);
    tbl.ColumnName = {'File','Ic(A)','Ia(A)','Vc_ss(V)','Va_ss(V)','R_cath(ohm)','R_anod(ohm)','R_avg(ohm)','Detection'};
    tbl.Data = cell(0,9);

    logUi = gamrywb.ui.createLogPanel(layLog, 1);
    txtLog = logUi.textArea;

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

    function onOpenFiles(~,~)
        [files,path] = uigetfile({'*.DTA;*.dta','Gamry DTA files (*.DTA)'}, ...
            'Select Gamry DTA file(s)','MultiSelect','on');
        if isequal(files,0)
            return;
        end
        if ischar(files)
            files = {files};
        end
        filepaths = cellfun(@(f) fullfile(path,f), files, 'UniformOutput', false);
        addFiles(filepaths);
    end

    function onOpenFolder(~,~)
        folder = uigetdir(pwd,'Select folder containing DTA files');
        if isequal(folder,0)
            return;
        end
        filepaths = gamrywb.io.findDTAFilesRecursive(folder);
        if isempty(filepaths)
            uialert(fig,'No .DTA files found in the selected folder.','Open folder');
            return;
        end
        addFiles(filepaths);
    end

    function addFiles(filepaths)
        callbacks = struct();
        callbacks.onAdded = @(fp, item) addLog(['Loaded: ' fp]); %#ok<INUSD>
        callbacks.onSkipped = @(fp) addLog(['Skipped duplicate: ' fp]);
        callbacks.onFailed = @(fp, msg) addLog(sprintf('Failed to load %s: %s', fp, msg));
        [S.session, ~] = gamrywb.data.addFilesToSession(S.session, filepaths, @loadAndAnalyzeFile, callbacks);
        S.items = S.session.items;
        if ~isempty(S.items) && isempty(S.current)
            S.current = 1;
        end
        refreshFileList();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();
    end

    function item = loadAndAnalyzeFile(filepath)
        [~,name,ext] = fileparts(filepath);
        item = struct();
        item.filepath = filepath;
        item.name = [name ext];
        item.meta = [];
        item.tables = [];
        item.logmsg = {};
        item.analysis = [];

        [item.meta, item.tables, item.logmsg] = gamrywb.io.parseChronoDTA(filepath);
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
        opts.windowMode = ddSteadyWindow.Value;
        opts.voltageMode = ddVoltageMode.Value;
        opts.pulseMode = ddPulseMode.Value;

        A = gamrywb.analysis.computeVTResistance(item, opts);
        if A.ok
            addLog(sprintf('%s: Rc=%.6g ohm, Ra=%.6g ohm, Ravg=%.6g ohm', ...
                item.name, A.Rc_abs_ohm, A.Ra_abs_ohm, A.Ravg_abs_ohm));
        elseif isfield(A, 'logOnFailure') && A.logOnFailure
            addLog(sprintf('%s: %s', item.name, A.message));
        end
        item.analysis = A;
    end

    function onSelectFile()
        selectionCallbacks = struct();
        selectionCallbacks.restoreDefaultPlotSelections = @restoreDefaultPlotSelections;
        selectionCallbacks.resetAxesToDefaultState = @resetAxesToDefaultState;
        selectionCallbacks.refreshResultsSummary = @refreshResultsSummary;
        selectionCallbacks.refreshPlots = @refreshPlots;
        S.current = gamrywb.app.handleSingleFileSelection(lbFiles, selectionCallbacks);
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
        gamrywb.app.handleClearSingleFileSession('vt_resistance', clearCallbacks);
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
        if isempty(S.items)
            tbl.Data = cell(0,9);
            return;
        end
        tbl.Data = gamrywb.ui.buildVTResistanceBatchTableData(S.items);
    end

    function refreshResultsSummary()
        S.txtDetect.Value = '-';
        S.txtWindow.Value = '-';
        S.txtCathIV.Value = '-';
        S.txtAnodIV.Value = '-';
        S.txtCathBase.Value = '-';
        S.txtAnodBase.Value = '-';
        S.txtCathBaseWin.Value = '-';
        S.txtAnodBaseWin.Value = '-';
        S.txtCathR.Value = '-';
        S.txtAnodR.Value = '-';
        S.txtAvgR.Value = '-';
        S.txtStatus.Value = '-';

        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            return;
        end
        it = S.items(S.current);
        if isempty(it.analysis) || ~it.analysis.ok
            if ~isempty(it.analysis) && isfield(it.analysis,'message')
                S.txtStatus.Value = it.analysis.message;
            else
                S.txtStatus.Value = 'No valid analysis';
            end
            return;
        end

        A = it.analysis;
        S.txtDetect.Value = sprintf('%s | %s', A.detectMode, A.detectMsg);
        S.txtWindow.Value = sprintf('%s | %s', A.windowMode, A.voltageMode);
        S.txtCathIV.Value = sprintf('I=%.6e A | Vss=%.6f V | dV=%.6f V', A.Ic_est_A, A.Vc_ss_V, A.dVc_V);
        S.txtAnodIV.Value = sprintf('I=%.6e A | Vss=%.6f V | dV=%.6f V', A.Ia_est_A, A.Va_ss_V, A.dVa_V);
        S.txtCathBase.Value = sprintf('%.6f V', A.Vc_baseline_V);
        S.txtAnodBase.Value = sprintf('%.6f V', A.Va_baseline_V);
        S.txtCathBaseWin.Value = formatDurationUs(A.cathBaselineWindow_s);
        S.txtAnodBaseWin.Value = formatDurationUs(A.anodBaselineWindow_s);
        S.txtCathR.Value = sprintf('%.6g ohm (signed %.6g)', A.Rc_abs_ohm, A.Rc_ohm);
        S.txtAnodR.Value = sprintf('%.6g ohm (signed %.6g)', A.Ra_abs_ohm, A.Ra_ohm);
        S.txtAvgR.Value = sprintf('%.6g ohm', A.Ravg_abs_ohm);
        S.txtStatus.Value = A.message;
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
            cathEndX = interp1_safe(A.t, A.pt, A.pulse.cath_end);
            anodStartX = interp1_safe(A.t, A.pt, A.pulse.anod_start);
            anodEndX = interp1_safe(A.t, A.pt, A.pulse.anod_end);
            cathBaseStartX = interp1_safe(A.t, A.pt, A.pulse.pre_start);
            cathBaseEndX = interp1_safe(A.t, A.pt, A.pulse.pre_end);
            anodBaseStartX = interp1_safe(A.t, A.pt, A.anodBaselineStart);
            anodBaseEndX = interp1_safe(A.t, A.pt, A.anodBaselineEnd);
            cSteadyStartX = interp1_safe(A.t, A.pt, A.cathSteadyStart);
            cSteadyEndX = interp1_safe(A.t, A.pt, A.cathSteadyEnd);
            aSteadyStartX = interp1_safe(A.t, A.pt, A.anodSteadyStart);
            aSteadyEndX = interp1_safe(A.t, A.pt, A.anodSteadyEnd);
        else
            x = A.t;
            xlab = 'Time (s)';
            cathStartX = A.pulse.cath_start;
            cathEndX = A.pulse.cath_end;
            anodStartX = A.pulse.anod_start;
            anodEndX = A.pulse.anod_end;
            cathBaseStartX = A.pulse.pre_start;
            cathBaseEndX = A.pulse.pre_end;
            anodBaseStartX = A.anodBaselineStart;
            anodBaseEndX = A.anodBaselineEnd;
            cSteadyStartX = A.cathSteadyStart;
            cSteadyEndX = A.cathSteadyEnd;
            aSteadyStartX = A.anodSteadyStart;
            aSteadyEndX = A.anodSteadyEnd;
        end

        if startsWith(yChoice,'VT')
            plot(ax, x, A.Vf, 'LineWidth',1.25, 'Color',[0 0.4470 0.7410]);
            ylab = 'Vf (V vs Ref.)';
            ttl = sprintf('%s | VT | Ravg = %.6g ohm', itName(), A.Ravg_abs_ohm);
            hold(ax,'on');
        else
            plot(ax, x, A.Im, 'LineWidth',1.25, 'Color',[0.8500 0.3250 0.0980]);
            ylab = 'Im (A)';
            ttl = sprintf('%s | IT | Ic %.4g A, Ia %.4g A', itName(), A.Ic_est_A, A.Ia_est_A);
            hold(ax,'on');
        end

        if cbShowShading.Value
            shadeWindow(ax, cathStartX, cathEndX, [0.90 0.95 1.00], 0.12);
            shadeWindow(ax, anodStartX, anodEndX, [1.00 0.94 0.88], 0.12);
            shadeWindow(ax, cSteadyStartX, cSteadyEndX, [0.65 0.82 1.00], 0.22);
            shadeWindow(ax, aSteadyStartX, aSteadyEndX, [1.00 0.75 0.55], 0.22);
        end
        if cbShowMarkers.Value
            xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
            xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
            xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
            xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
            if startsWith(yChoice,'VT')
                addResistanceVTAnnotations(ax, A, cathBaseStartX, cathBaseEndX, anodBaseStartX, anodBaseEndX, ...
                    cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, cathStartX, cathEndX, anodStartX, anodEndX);
            else
                addResistanceITAnnotations(ax, A, cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, ...
                    cathStartX, cathEndX, anodStartX, anodEndX);
            end
        end
        hold(ax,'off');

        title(ax, ttl, 'Interpreter','none');
        xlabel(ax, xlab);
        ylabel(ax, ylab);
        grid(ax, ternary(showGrid,'on','off'));
    end

    function nm = itName()
        if isempty(S.items) || isempty(S.current)
            nm = 'file';
        else
            nm = S.items(S.current).name;
        end
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
        gamrywb.ui.resetTopBottomAxes(axTop, axBottom);
    end

    function exportResultsCSV()
        if isempty(S.items)
            uialert(fig,'No results to export.','Export');
            return;
        end
        [f,p] = uiputfile('vt_steady_resistance_results.csv','Save results CSV');
        if isequal(f,0)
            return;
        end
        out = fullfile(p,f);
        [ok, msg] = gamrywb.io.writeVTResistanceResultsCSV(S.items, out);
        if ~ok
            uialert(fig,msg,'Export');
            return;
        end
        addLog(['Exported CSV: ' out]);
    end

    function startDrag(~,~)
        S.isDragging = true;
        fig.WindowButtonMotionFcn = @doDrag;
        fig.WindowButtonUpFcn = @stopDrag;
        fig.Pointer = 'left';
    end

    function doDrag(~,~)
        if ~S.isDragging
            return;
        end
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

    function addLog(msg)
        gamrywb.ui.appendLog(txtLog, msg);
    end

end

function idx = nearestIndex(x, xq)
    [~, idx] = min(abs(x - xq));
end

function v = interp1_safe(x, y, xq)
    if numel(x) < 2 || any(~isfinite([x(:); y(:)]))
        v = NaN;
        return;
    end
    try
        v = interp1(x, y, xq, 'linear', 'extrap');
    catch
        idx = nearestIndex(x, xq);
        v = y(idx);
    end
end

function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end

function shadeWindow(ax, x1, x2, color, alphaVal)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1
        return;
    end
    yl = ylim(ax);
    if any(~isfinite(yl)) || yl(1) == yl(2)
        return;
    end
    p = patch(ax, [x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], color, ...
        'FaceAlpha',alphaVal,'EdgeColor','none','HandleVisibility','off');
    uistack(p,'bottom');
end

function addResistanceVTAnnotations(ax, A, cathBaseStartX, cathBaseEndX, anodBaseStartX, anodBaseEndX, ...
    cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, cathStartX, cathEndX, anodStartX, anodEndX)
    cSteadyMidX = midpointFinite(cSteadyStartX, cSteadyEndX);
    aSteadyMidX = midpointFinite(aSteadyStartX, aSteadyEndX);

    drawBaselineSegment(ax, cathBaseStartX, cathBaseEndX, A.Vc_baseline_V, [0.20 0.20 0.20], ...
        sprintf('Cath baseline = %.4f V', A.Vc_baseline_V), 'bottom');
    drawBaselineSegment(ax, anodBaseStartX, anodBaseEndX, A.Va_baseline_V, [0.35 0.35 0.35], ...
        sprintf('Anod baseline = %.4f V', A.Va_baseline_V), 'top');

    drawLevelSegment(ax, cSteadyStartX, cSteadyEndX, A.Vc_ss_V, [0.10 0.35 0.80], '--');
    drawLevelSegment(ax, aSteadyStartX, aSteadyEndX, A.Va_ss_V, [0.80 0.35 0.10], '--');

    plot(ax, cSteadyEndX, A.Vc_ss_V, 'o', 'MarkerFaceColor',[0.10 0.35 0.80], ...
        'MarkerEdgeColor','k', 'MarkerSize',6, 'HandleVisibility','off');
    plot(ax, aSteadyEndX, A.Va_ss_V, 'o', 'MarkerFaceColor',[0.80 0.35 0.10], ...
        'MarkerEdgeColor','k', 'MarkerSize',6, 'HandleVisibility','off');

    text(ax, cSteadyEndX, A.Vc_ss_V, sprintf('  Cath steady V = %.4f V', A.Vc_ss_V), ...
        'Color',[0.10 0.35 0.80], 'VerticalAlignment','bottom', 'Interpreter','tex');
    text(ax, aSteadyEndX, A.Va_ss_V, sprintf('  Anod steady V = %.4f V', A.Va_ss_V), ...
        'Color',[0.80 0.35 0.10], 'VerticalAlignment','top', 'Interpreter','tex');

    if isfinite(cSteadyMidX) && isfinite(A.Vc_baseline_V) && isfinite(A.Vc_ss_V)
        plot(ax, [cSteadyMidX cSteadyMidX], [A.Vc_baseline_V A.Vc_ss_V], '--', ...
            'Color',[0.10 0.35 0.80], 'LineWidth',1.0, 'HandleVisibility','off');
        text(ax, cSteadyMidX, 0.5*(A.Vc_baseline_V + A.Vc_ss_V), sprintf('  Cath dV = %.4f V', A.dVc_V), ...
            'Color',[0.10 0.35 0.80], 'VerticalAlignment','middle', 'Interpreter','tex');
    end
    if isfinite(aSteadyMidX) && isfinite(A.Va_baseline_V) && isfinite(A.Va_ss_V)
        plot(ax, [aSteadyMidX aSteadyMidX], [A.Va_baseline_V A.Va_ss_V], '--', ...
            'Color',[0.80 0.35 0.10], 'LineWidth',1.0, 'HandleVisibility','off');
        text(ax, aSteadyMidX, 0.5*(A.Va_baseline_V + A.Va_ss_V), sprintf('  Anod dV = %.4f V', A.dVa_V), ...
            'Color',[0.80 0.35 0.10], 'VerticalAlignment','middle', 'Interpreter','tex');
    end

    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.08 * dy;
    yLow = yl(2) - 0.16 * dy;
    drawDurationBracket(ax, cathStartX, cathEndX, yTop, 'Cathodic pulse');
    drawDurationBracket(ax, anodStartX, anodEndX, yLow, 'Anodic pulse');
end

function addResistanceITAnnotations(ax, A, cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, ...
    cathStartX, cathEndX, anodStartX, anodEndX)
    drawLevelSegment(ax, cSteadyStartX, cSteadyEndX, A.Ic_est_A, [0.10 0.35 0.80], '--');
    drawLevelSegment(ax, aSteadyStartX, aSteadyEndX, A.Ia_est_A, [0.80 0.35 0.10], '--');

    plot(ax, cSteadyEndX, A.Ic_est_A, 'o', 'MarkerFaceColor',[0.10 0.35 0.80], ...
        'MarkerEdgeColor','k', 'MarkerSize',6, 'HandleVisibility','off');
    plot(ax, aSteadyEndX, A.Ia_est_A, 'o', 'MarkerFaceColor',[0.80 0.35 0.10], ...
        'MarkerEdgeColor','k', 'MarkerSize',6, 'HandleVisibility','off');

    text(ax, cSteadyEndX, A.Ic_est_A, sprintf('  Cath current = %.3f mA', 1e3 * A.Ic_est_A), ...
        'Color',[0.10 0.35 0.80], 'VerticalAlignment','bottom', 'Interpreter','tex');
    text(ax, aSteadyEndX, A.Ia_est_A, sprintf('  Anod current = %.3f mA', 1e3 * A.Ia_est_A), ...
        'Color',[0.80 0.35 0.10], 'VerticalAlignment','top', 'Interpreter','tex');

    yl = ylim(ax);
    dy = yl(2) - yl(1);
    yTop = yl(2) - 0.08 * dy;
    yLow = yl(2) - 0.16 * dy;
    drawDurationBracket(ax, cathStartX, cathEndX, yTop, 'Cathodic pulse');
    drawDurationBracket(ax, anodStartX, anodEndX, yLow, 'Anodic pulse');
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
    text(ax, 0.5 * (x1 + x2), y + 1.4 * h, labelText, 'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', 'BackgroundColor','w', 'Margin',1, 'HandleVisibility','off');
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
        'BackgroundColor','w', 'Margin',1, 'Interpreter','none', 'HandleVisibility','off');
end

function drawLevelSegment(ax, x1, x2, y, color, lineStyle)
    if ~isfinite(x1) || ~isfinite(x2) || x2 <= x1 || ~isfinite(y)
        return;
    end
    plot(ax, [x1 x2], [y y], lineStyle, 'Color', color, 'LineWidth',1.3, 'HandleVisibility','off');
end

function xm = midpointFinite(x1, x2)
    if isfinite(x1) && isfinite(x2)
        xm = 0.5 * (x1 + x2);
    else
        xm = NaN;
    end
end

function txt = formatDurationUs(dt_s)
    if ~isscalar(dt_s) || ~isfinite(dt_s) || dt_s < 0
        txt = '-';
    else
        txt = sprintf('%.3f us', 1e6 * dt_s);
    end
end
