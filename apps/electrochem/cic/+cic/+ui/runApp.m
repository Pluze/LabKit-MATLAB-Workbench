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

    callbacks = struct( ...
        'onOpenFiles', @onOpenFiles, ...
        'onOpenFolder', @onOpenFolder, ...
        'onClearAll', @(~,~) clearAllFiles(), ...
        'onExport', @(~,~) exportResultsCSV(), ...
        'onSelectFile', @(~,~) onSelectFile(), ...
        'onPresetChanged', @(~,~) onPresetChanged(), ...
        'onAnalyzeCurrentFile', @(~,~) analyzeCurrentFile(), ...
        'onRefreshResultsSummary', @(~,~) refreshResultsSummary(), ...
        'onRefreshCICUnitDisplays', @(~,~) refreshCICUnitDisplays(), ...
        'onRefreshPlots', @(~,~) refreshPlots(), ...
        'onSwapPlots', @(~,~) swapPlots(), ...
        'onResetAxes', @(~,~) resetAxes());
    C = cic.ui.buildControls(callbacks);

    fig = C.fig;
    lbFiles = C.lbFiles;
    txtLoaded = C.txtLoaded;
    ddPreset = C.ddPreset;
    edCathLim = C.edCathLim;
    edAnodLim = C.edAnodLim;
    edDelayUs = C.edDelayUs;
    edArea = C.edArea;
    ddPulseMode = C.ddPulseMode;
    ddCICMode = C.ddCICMode;
    ddCICUnit = C.ddCICUnit;
    cbUseMeasuredCurrent = C.cbUseMeasuredCurrent;
    S.txtControlMode = C.txtControlMode;
    S.txtDetect = C.txtDetect;
    S.txtDelay = C.txtDelay;
    S.txtArea = C.txtArea;
    S.txtEmc = C.txtEmc;
    S.txtEma = C.txtEma;
    S.txtQc = C.txtQc;
    S.txtQa = C.txtQa;
    S.txtQt = C.txtQt;
    S.txtSafe = C.txtSafe;
    S.txtBest = C.txtBest;
    cbShowMarkers = C.cbShowMarkers;
    cbShowLimits = C.cbShowLimits;
    cbShowShading = C.cbShowShading;
    tbl = C.tbl;
    txtLog = C.txtLog;
    topPlotDefaults = C.topPlotDefaults;
    bottomPlotDefaults = C.bottomPlotDefaults;
    plotControls = C.plotControls;
    ddTopX = C.ddTopX;
    ddTopY = C.ddTopY;
    cbTopGrid = C.cbTopGrid;
    axTop = C.axTop;
    ddBotX = C.ddBotX;
    ddBotY = C.ddBotY;
    cbBotGrid = C.cbBotGrid;
    axBottom = C.axBottom;
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
            txtLoaded.Value = C.loadedText;
            S.current = [];
            return;
        end

        names = {S.items.name};
        [~, idx] = labkit.ui.view.update(lbFiles, 'listSelection', names, S.current);
        S.current = idx(1);
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshBatchTable()
        [~, unitLabel] = cic.view.displayUnit(ddCICUnit.Value);
        [C, columnNames] = cic.view.buildBatchTableData(S.items, unitLabel);
        tbl.ColumnName = columnNames;
        if isempty(S.items)
            tbl.Data = cell(0,8);
            return;
        end
        tbl.Data = C;
    end

    function refreshResultsSummary()
        summary = cic.view.buildCurrentSummary(S.items, S.current, ...
            ddCICMode.Value, ddCICUnit.Value);
        S.txtControlMode.Value = summary.controlMode;
        S.txtDetect.Value = summary.detect;
        S.txtDelay.Value = summary.delay;
        S.txtArea.Value = summary.area;
        S.txtEmc.Value = summary.emc;
        S.txtEma.Value = summary.ema;
        S.txtQc.Value = summary.qc;
        S.txtQa.Value = summary.qa;
        S.txtQt.Value = summary.qt;
        S.txtSafe.Value = summary.safe;
        S.txtBest.Value = summary.bestSafe;
    end

    function refreshCICUnitDisplays()
        refreshBatchTable();
        refreshResultsSummary();
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
        request = cic.view.plotRequest(A, itName(), xChoice, yChoice);
        coords = request.coords;

        if strcmp(request.kind, 'VT')
            plot(ax, request.x, request.y, 'LineWidth',1.25, 'Color', request.baseColor);
            hold(ax,'on');

            if cbShowShading.Value
                cic.view.shadeWindow(ax, coords.cathStartX, coords.cathEndX, [0.85 0.93 1.00]);
                cic.view.shadeWindow(ax, coords.anodStartX, coords.anodEndX, [1.00 0.92 0.85]);
            end

            if cbShowLimits.Value
                yline(ax, A.cathLimit, '--', sprintf('Cath limit = %.3f V', A.cathLimit), ...
                    'Color',[0.85 0.2 0.2],'LabelHorizontalAlignment','left');
                yline(ax, A.anodLimit, '--', sprintf('Anod limit = %.3f V', A.anodLimit), ...
                    'Color',[0.85 0.2 0.2],'LabelHorizontalAlignment','left');
            end

            cic.view.addBaselineYLines(ax, A);

            if cbShowMarkers.Value
                xline(ax, coords.cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
                xline(ax, coords.cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
                xline(ax, coords.anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
                xline(ax, coords.anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
                cic.view.addPaperStyleVTAnnotations(ax, A, xChoice, ...
                    coords.cathStartX, coords.cathEndX, coords.anodStartX, ...
                    coords.anodEndX, coords.emcX, coords.emaX);
            end
            hold(ax,'off');
        else
            plot(ax, request.x, request.y, 'LineWidth',1.25, 'Color', request.baseColor);
            hold(ax,'on');

            if cbShowShading.Value
                cic.view.shadeWindow(ax, coords.cathStartX, coords.cathEndX, [0.85 0.93 1.00]);
                cic.view.shadeWindow(ax, coords.anodStartX, coords.anodEndX, [1.00 0.92 0.85]);
            end

            if cbShowMarkers.Value
                xline(ax, coords.cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
                xline(ax, coords.cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
                xline(ax, coords.anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
                xline(ax, coords.anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
                cic.view.addPaperStyleITAnnotations(ax, A, xChoice, ...
                    coords.cathStartX, coords.cathEndX, coords.anodStartX, ...
                    coords.anodEndX, coords.emcX, coords.emaX);
            end
            hold(ax,'off');
        end

        title(ax, request.title, 'Interpreter','none');
        xlabel(ax, request.xLabel);
        ylabel(ax, request.yLabel);
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
        [~, unitLabel] = cic.view.displayUnit(ddCICUnit.Value);
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
