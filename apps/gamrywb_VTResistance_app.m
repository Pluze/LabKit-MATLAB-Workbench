function varargout = gamrywb_VTResistance_app(varargin)
%GAMRYWB_VTRESISTANCE_APP Launch the VT resistance app.
% Single-file app that composes +gamrywb GUI/DTA APIs and owns VT resistance workflow choices.
% GUI for estimating cathodic/anodic steady-state resistance from Gamry
% MULTI_STEP_CHRONOPOT .DTA files.
%
% The pulse detection and current estimation follow the CIC VT GUI pattern:
%   - Use ISTEP/TSTEP metadata first, with optional current-waveform fallback.
%   - Estimate phase current by median(Im) in the selected pulse window.
%   - Estimate steady phase voltage by median(Vf) in the same selected window.
%   - Compute baseline-corrected resistance as abs((Vss - Vbaseline) / Iss).

    if nargin > 0
        % Keep VT numerical/export tests direct while the app owns the local workflow code.
        [handled, testOutputs] = handleVTTestRequest(varargin, nargout);
        if handled
            varargout = testOutputs;
            return;
        end
        error('gamrywb_VTResistance_app:UnsupportedInput', 'gamrywb_VTResistance_app does not accept input arguments.');
    end
    if nargout > 1
        error('gamrywb_VTResistance_app:TooManyOutputs', 'gamrywb_VTResistance_app returns at most the app figure handle.');
    end

    S = struct();
    S.session = gamrywb.dta.makeSession('vt_resistance');
    S.items = S.session.items;
    S.current = [];
    S.isDragging = false;

    shellLabels = struct( ...
        'controlsPanel', 'Controls', ...
        'filesAnalysisTab', 'Files + Analysis', ...
        'summaryResultsTab', 'Summary + Results', ...
        'logTab', 'Log', ...
        'plotsPanel', 'Plots', ...
        'topPlot', 'Top Plot', ...
        'bottomPlot', 'Bottom Plot');
    ui = gamrywb.ui.createTabbedDualPlotShell( ...
        'Gamry VT Steady Resistance GUI', ...
        [40 30 1680 980], ...
        430, ...
        @startDrag, ...
        shellLabels);
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
    fileLabels = struct( ...
        'panelTitle', 'Files', ...
        'openFiles', 'Open DTA file(s)', ...
        'openFolder', 'Open folder recursively', ...
        'clearAll', 'Clear all', ...
        'export', 'Export results CSV', ...
        'loadedText', 'No files loaded');
    fileUi = gamrywb.ui.createSingleSelectFilePanel(layFA, fileLabels, fileCallbacks);
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

    tableUi = gamrywb.ui.createResultTablePanel(laySR, 'Batch Results', 2, ...
        {'File','Ic(A)','Ia(A)','Vc_ss(V)','Va_ss(V)','R_cath(ohm)','R_anod(ohm)','R_avg(ohm)','Detection'}, ...
        cell(0,9));
    tbl = tableUi.table;

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

    %% App callbacks, session actions, refresh, plotting, and export
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
        filepaths = gamrywb.dta.findFiles(folder);
        if isempty(filepaths)
            uialert(fig,'No .DTA files found in the selected folder.','Open folder');
            return;
        end
        addFiles(filepaths);
    end

    function addFiles(filepaths)
        callbacks = struct();
        callbacks.onAdded = @(~, ~) [];
        callbacks.onSkipped = @(fp) addLog(['Skipped duplicate: ' fp]);
        callbacks.onFailed = @(fp, msg) addLog(sprintf('Failed to load %s: %s', fp, msg));
        [S.session, report] = gamrywb.dta.addFilesToSession(S.session, filepaths, "chrono", callbacks);
        postProcessAddedItems(report.added);
        S.items = S.session.items;
        if ~isempty(S.items) && isempty(S.current)
            S.current = 1;
        end
        refreshFileList();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();
    end

    function postProcessAddedItems(filepaths)
        for iFile = 1:numel(filepaths)
            idx = find(strcmp(string({S.session.items.filepath}), string(filepaths{iFile})), 1, 'first');
            if isempty(idx)
                continue;
            end
            item = S.session.items(idx);
            for ii = 1:numel(item.logmsg)
                addLog(item.logmsg{ii});
            end
            item = analyzeItem(item);
            S.session.items(idx) = item;
            addLog(['Loaded: ' filepaths{iFile}]);
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
        opts.windowMode = ddSteadyWindow.Value;
        opts.voltageMode = ddVoltageMode.Value;
        opts.pulseMode = ddPulseMode.Value;

        A = computeResistance(item, opts);
        if A.ok
            addLog(sprintf('%s: Rc=%.6g ohm, Ra=%.6g ohm, Ravg=%.6g ohm', ...
                item.name, A.Rc_abs_ohm, A.Ra_abs_ohm, A.Ravg_abs_ohm));
        elseif isfield(A, 'logOnFailure') && A.logOnFailure
            addLog(sprintf('%s: %s', item.name, A.message));
        end
        item.analysis = A;
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
        S.session = gamrywb.dta.makeSession('vt_resistance');
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
            txtLoaded.Value = fileLabels.loadedText;
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
        if isempty(S.items)
            tbl.Data = cell(0,9);
            return;
        end
            tbl.Data = buildBatchTableData(S.items);
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
            cathStartX = interp1Safe(A.t, A.pt, A.pulse.cath_start);
            cathEndX = interp1Safe(A.t, A.pt, A.pulse.cath_end);
            anodStartX = interp1Safe(A.t, A.pt, A.pulse.anod_start);
            anodEndX = interp1Safe(A.t, A.pt, A.pulse.anod_end);
            cathBaseStartX = interp1Safe(A.t, A.pt, A.pulse.pre_start);
            cathBaseEndX = interp1Safe(A.t, A.pt, A.pulse.pre_end);
            anodBaseStartX = interp1Safe(A.t, A.pt, A.anodBaselineStart);
            anodBaseEndX = interp1Safe(A.t, A.pt, A.anodBaselineEnd);
            cSteadyStartX = interp1Safe(A.t, A.pt, A.cathSteadyStart);
            cSteadyEndX = interp1Safe(A.t, A.pt, A.cathSteadyEnd);
            aSteadyStartX = interp1Safe(A.t, A.pt, A.anodSteadyStart);
            aSteadyEndX = interp1Safe(A.t, A.pt, A.anodSteadyEnd);
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
        gamrywb.ui.hardResetAxis(axTop, 'Top Plot');
        gamrywb.ui.hardResetAxis(axBottom, 'Bottom Plot');
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
        [ok, msg] = writeResultsCSV(S.items, out);
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

%% App test hook
function [handled, outputs] = handleVTTestRequest(args, nargoutRequested)
    handled = false;
    outputs = {};
    if isempty(args) || ~(ischar(args{1}) || (isstring(args{1}) && isscalar(args{1})))
        return;
    end

    handled = true;
    command = char(args{1});
    switch command
        case '__test_computeResistance__'
            assertVTTestArgCount(args, 3, command);
            if nargoutRequested > 1
                error('gamrywb_VTResistance_app:TooManyOutputs', 'VT compute test request returns one result struct.');
            end
            outputs = {computeResistance(args{2}, args{3})};
        case '__test_buildBatchTableData__'
            assertVTTestArgCount(args, 2, command);
            if nargoutRequested > 1
                error('gamrywb_VTResistance_app:TooManyOutputs', 'VT batch-table test request returns one cell array.');
            end
            outputs = {buildBatchTableData(args{2})};
        case '__test_buildResultsTable__'
            assertVTTestArgCount(args, 2, command);
            if nargoutRequested > 1
                error('gamrywb_VTResistance_app:TooManyOutputs', 'VT result-table test request returns one table.');
            end
            outputs = {buildResultsTable(args{2})};
        case '__test_writeResultsCSV__'
            assertVTTestArgCount(args, 3, command);
            if nargoutRequested > 2
                error('gamrywb_VTResistance_app:TooManyOutputs', 'VT CSV test request returns at most ok and message.');
            end
            if nargoutRequested == 0
                writeResultsCSV(args{2}, args{3});
            else
                [ok, msg] = writeResultsCSV(args{2}, args{3});
                outputs = {ok, msg};
                outputs = outputs(1:nargoutRequested);
            end
        otherwise
            handled = false;
    end
end

function assertVTTestArgCount(args, expectedCount, command)
    if numel(args) ~= expectedCount
        error('gamrywb_VTResistance_app:InvalidTestRequest', ...
            '%s expects %d total input arguments.', command, expectedCount);
    end
end

%% App-local analysis
function A = computeResistance(item, opts)
%COMPUTERESISTANCE Compute VT resistance metrics for the VT app.

    if nargin < 2
        opts = struct();
    end
    opts = fillResistanceOptions(opts);

    A = struct();
    A.ok = false;
    A.message = '';
    A.windowMode = opts.windowMode;
    A.voltageMode = opts.voltageMode;
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

    meta = struct();
    if isfield(item, 'meta')
        meta = item.meta;
    end
    [pulse, pulseMsg] = gamrywb.dta.detectPulses(t, Im, meta, opts.pulseMode);
    A.pulse = pulse;
    A.detectMode = pulse.method;
    A.detectMsg = pulseMsg;
    if ~pulse.ok
        A.message = pulseMsg;
        A.logOnFailure = true;
        return;
    end

    [cStart, cEnd] = selectSteadyWindow(pulse.cath_start, pulse.cath_end, A.windowMode);
    [aStart, aEnd] = selectSteadyWindow(pulse.anod_start, pulse.anod_end, A.windowMode);
    cathMask = t >= cStart & t <= cEnd;
    anodMask = t >= aStart & t <= aEnd;
    if nnz(cathMask) < 2 || nnz(anodMask) < 2
        A.message = 'Steady windows are too short after pulse detection.';
        return;
    end

    A.cathMask = cathMask;
    A.anodMask = anodMask;
    A.cathSteadyStart = cStart;
    A.cathSteadyEnd = cEnd;
    A.anodSteadyStart = aStart;
    A.anodSteadyEnd = aEnd;

    A.Ic_est_A = median(Im(cathMask), 'omitnan');
    A.Ia_est_A = median(Im(anodMask), 'omitnan');
    A.Vc_ss_V = median(Vf(cathMask), 'omitnan');
    A.Va_ss_V = median(Vf(anodMask), 'omitnan');

    A.cathBaselineStart = pulse.pre_start;
    A.cathBaselineEnd = pulse.pre_end;
    A.anodBaselineStart = pulse.post_start;
    A.anodBaselineEnd = pulse.post_end;
    [A.Vc_baseline_V, A.cathBaselineWindow_s] = estimateBaseline( ...
        t, Vf, pulse.pre_start, pulse.pre_end, 0);
    [A.Va_baseline_V, A.anodBaselineWindow_s] = estimateBaseline( ...
        t, Vf, pulse.post_start, pulse.post_end, chooseFinite(A.Vc_baseline_V, 0));

    A.dVc_V = A.Vc_ss_V - A.Vc_baseline_V;
    A.dVa_V = A.Va_ss_V - A.Va_baseline_V;
    A.Rc_raw_ohm = safeDivide(A.Vc_ss_V, A.Ic_est_A);
    A.Ra_raw_ohm = safeDivide(A.Va_ss_V, A.Ia_est_A);
    A.Rc_dV_ohm = safeDivide(A.dVc_V, A.Ic_est_A);
    A.Ra_dV_ohm = safeDivide(A.dVa_V, A.Ia_est_A);

    if strcmp(A.voltageMode, 'Raw Vf/I')
        A.Rc_ohm = A.Rc_raw_ohm;
        A.Ra_ohm = A.Ra_raw_ohm;
    else
        A.Rc_ohm = A.Rc_dV_ohm;
        A.Ra_ohm = A.Ra_dV_ohm;
    end
    A.Rc_abs_ohm = abs(A.Rc_ohm);
    A.Ra_abs_ohm = abs(A.Ra_ohm);
    A.Ravg_abs_ohm = mean([A.Rc_abs_ohm, A.Ra_abs_ohm], 'omitnan');

    A.ok = isfinite(A.Ravg_abs_ohm);
    if A.ok
        A.message = 'OK';
    else
        A.message = 'Resistance could not be computed; check current and pulse detection.';
        A.logOnFailure = true;
    end
end

function opts = fillResistanceOptions(opts)
    if ~isfield(opts, 'windowMode')
        opts.windowMode = 'Full pulse median';
    end
    if ~isfield(opts, 'voltageMode')
        opts.voltageMode = 'Baseline-corrected dV/I';
    end
    if ~isfield(opts, 'pulseMode')
        opts.pulseMode = 'Metadata first, then auto';
    end
end

%% App-local table/export helpers
function C = buildBatchTableData(items)
%BUILDBATCHTABLEDATA Build VT resistance uitable data.

    C = cell(numel(items), 9);
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
            C{i, 8} = NaN;
            C{i, 9} = 'parse/analyze failed';
            continue;
        end

        C{i, 2} = A.Ic_est_A;
        C{i, 3} = A.Ia_est_A;
        C{i, 4} = A.Vc_ss_V;
        C{i, 5} = A.Va_ss_V;
        C{i, 6} = A.Rc_abs_ohm;
        C{i, 7} = A.Ra_abs_ohm;
        C{i, 8} = A.Ravg_abs_ohm;
        C{i, 9} = A.detectMode;
    end
end

function T = buildResultsTable(items)
%BUILDRESULTSTABLE Build VT resistance CSV result table.

    file = cell(numel(items), 1);
    Ic_A = NaN(numel(items), 1);
    Ia_A = NaN(numel(items), 1);
    Vc_ss_V = NaN(numel(items), 1);
    Va_ss_V = NaN(numel(items), 1);
    Vc_baseline_V = NaN(numel(items), 1);
    Va_baseline_V = NaN(numel(items), 1);
    dVc_V = NaN(numel(items), 1);
    dVa_V = NaN(numel(items), 1);
    Rc_bc_ohm = NaN(numel(items), 1);
    Ra_bc_ohm = NaN(numel(items), 1);
    Ravg_bc_ohm = NaN(numel(items), 1);
    windowMode = cell(numel(items), 1);
    detection = cell(numel(items), 1);
    status = cell(numel(items), 1);

    for i = 1:numel(items)
        item = items(i);
        file{i} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            windowMode{i} = '';
            detection{i} = 'failed';
            status{i} = analysisMessage(A);
            continue;
        end

        Ic_A(i) = A.Ic_est_A;
        Ia_A(i) = A.Ia_est_A;
        Vc_ss_V(i) = A.Vc_ss_V;
        Va_ss_V(i) = A.Va_ss_V;
        Vc_baseline_V(i) = A.Vc_baseline_V;
        Va_baseline_V(i) = A.Va_baseline_V;
        dVc_V(i) = A.dVc_V;
        dVa_V(i) = A.dVa_V;
        Rc_bc_ohm(i) = abs(A.Rc_dV_ohm);
        Ra_bc_ohm(i) = abs(A.Ra_dV_ohm);
        Ravg_bc_ohm(i) = mean([Rc_bc_ohm(i), Ra_bc_ohm(i)], 'omitnan');
        windowMode{i} = A.windowMode;
        detection{i} = A.detectMode;
        status{i} = A.message;
    end

    T = table(file, Ic_A, Ia_A, Vc_ss_V, Va_ss_V, Vc_baseline_V, Va_baseline_V, ...
        dVc_V, dVa_V, Rc_bc_ohm, Ra_bc_ohm, Ravg_bc_ohm, windowMode, detection, status, ...
        'VariableNames', {'File', 'Ic_A', 'Ia_A', 'Vc_ss_V', 'Va_ss_V', ...
        'Vc_baseline_V', 'Va_baseline_V', 'dVc_V', 'dVa_V', 'Rc_bc_ohm', ...
        'Ra_bc_ohm', 'Ravg_bc_ohm', 'WindowMode', 'Detection', 'Status'});
end

function [ok, msg] = writeResultsCSV(items, filepath)
%WRITERESULTSCSV Write VT resistance results in legacy CSV format.

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
        T = buildResultsTable(items);
        fprintf(fid, 'File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status\n');
        for i = 1:height(T)
            fprintf(fid, '"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,"%s","%s","%s"\n', ...
                csvEscape(T.File{i}), ...
                T.Ic_A(i), T.Ia_A(i), T.Vc_ss_V(i), T.Va_ss_V(i), ...
                T.Vc_baseline_V(i), T.Va_baseline_V(i), T.dVc_V(i), T.dVa_V(i), ...
                T.Rc_bc_ohm(i), T.Ra_bc_ohm(i), T.Ravg_bc_ohm(i), ...
                csvEscape(T.WindowMode{i}), ...
                csvEscape(T.Detection{i}), ...
                csvEscape(T.Status{i}));
        end
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end

%% App-local plotting helpers
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

function q = safeDivide(a, b)
    if ~isscalar(a) || ~isscalar(b) || ~isfinite(a) || ~isfinite(b) || abs(b) < eps
        q = NaN;
    else
        q = a / b;
    end
end

function v = chooseFinite(varargin)
    v = NaN;
    for k = 1:nargin
        x = varargin{k};
        if isscalar(x) && isfinite(x)
            v = x;
            return;
        end
    end
end

function [t1, t2] = selectSteadyWindow(p1, p2, modeText)
    t1 = p1;
    t2 = p2;
    if strcmp(modeText, 'Center 60% median') && isfinite(p1) && isfinite(p2) && p2 > p1
        dt = p2 - p1;
        t1 = p1 + 0.20 * dt;
        t2 = p1 + 0.80 * dt;
    end
end

function [v, window_s] = estimateBaseline(t, y, t1, t2, fallbackValue)
    if nargin < 5
        fallbackValue = NaN;
    end

    v = medianInWindow(t, y, t1, t2);
    if ~isfinite(v)
        v = fallbackValue;
    end
    window_s = max(0, t2 - t1);
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

function msg = analysisMessage(A)
    msg = '';
    if ~isempty(A) && isfield(A, 'message')
        msg = A.message;
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

function s = csvEscape(x)
    s = strrep(char(x), '"', '""');
end

function v = interp1Safe(x, y, xq)
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

function idx = nearestIndex(x, xq)
    [~, idx] = min(abs(x - xq));
end

function m = medianInWindow(t, y, t1, t2)
    if ~isfinite(t1) || ~isfinite(t2) || t2 < t1
        m = NaN;
        return;
    end

    mask = t >= t1 & t <= t2;
    if ~any(mask)
        m = NaN;
    else
        m = median(y(mask), 'omitnan');
    end
end
