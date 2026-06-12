% App-owned runner extracted from labkit_VTResistance_app.m. Expected caller: labkit_VTResistance_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUNVTRESISTANCEAPP Build and run the app body.

    S = struct();
    S.session = labkit.dta.makeSession('vt_resistance');
    S.items = S.session.items;
    S.current = [];

    callbacks = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "openFolder", @onOpenFolder, ...
        "clearAll", @(~,~) clearAllFiles(), ...
        "exportResults", @(~,~) exportResultsCSV(), ...
        "fileSelectionChanged", @(~,~) onSelectFile(), ...
        "analysisChanged", @(~,~) analyzeCurrentFile(), ...
        "reanalyzeFile", @(~,~) analyzeCurrentFile(), ...
        "refreshPlots", @(~,~) refreshPlots(), ...
        "swapPlots", @(~,~) swapPlots(), ...
        "resetAxes", @(~,~) resetAxes());
    spec = vt_resistance.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;
    lbFiles = ui.controls.files.listbox;
    txtLoaded = ui.controls.files.status;
    ddPulseMode = ui.controls.pulseMode.valueHandle;
    ddSteadyWindow = ui.controls.steadyWindow.valueHandle;
    ddVoltageMode = ui.controls.voltageMode.valueHandle;
    cbShowMarkers = ui.controls.showMarkers.valueHandle;
    cbShowShading = ui.controls.showShading.valueHandle;
    S.txtControlMode = ui.controls.controlMode.valueHandle;
    S.txtDetect = ui.controls.detect.valueHandle;
    S.txtWindow = ui.controls.window.valueHandle;
    S.txtCathIV = ui.controls.cathIV.valueHandle;
    S.txtAnodIV = ui.controls.anodIV.valueHandle;
    S.txtCathBase = ui.controls.cathBase.valueHandle;
    S.txtAnodBase = ui.controls.anodBase.valueHandle;
    S.txtCathBaseWin = ui.controls.cathBaseWindow.valueHandle;
    S.txtAnodBaseWin = ui.controls.anodBaseWindow.valueHandle;
    S.txtCathR = ui.controls.cathR.valueHandle;
    S.txtAnodR = ui.controls.anodR.valueHandle;
    S.txtAvgR = ui.controls.averageR.valueHandle;
    S.txtStatus = ui.controls.status.valueHandle;
    tbl = ui.controls.results.table;
    topPlotDefaults = struct('x', 'Time (s)', 'y', 'VT: Vf vs time', 'grid', true);
    bottomPlotDefaults = struct('x', 'Time (s)', 'y', 'IT: Im vs time', 'grid', true);
    ddTopX = ui.controls.topX.valueHandle;
    ddTopY = ui.controls.topY.valueHandle;
    cbTopGrid = ui.controls.topGrid.valueHandle;
    axTop = ui.controls.plotAxes.axesById.top;
    ddBotX = ui.controls.bottomX.valueHandle;
    ddBotY = ui.controls.bottomY.valueHandle;
    cbBotGrid = ui.controls.bottomGrid.valueHandle;
    axBottom = ui.controls.plotAxes.axesById.bottom;
    if debugLog.enabled
        debugLog.trace('VT resistance debug trace enabled.');
    end
    %% App callbacks, session actions, refresh, plotting, and export
    function onOpenFilesChosen(~, event)
        if isempty(event.paths)
            addLog('Open cancelled.');
            return;
        end
        addFiles(event.paths);
    end

    function onOpenFolder(~,~)
        folder = uigetdir(pwd,'Select folder containing DTA files');
        if isequal(folder,0)
            addLog('Folder selection cancelled.');
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
        callbacks = struct();
        callbacks.onAdded = @(~, ~) [];
        callbacks.onSkipped = @(fp) addLog(['Skipped duplicate: ' fp]);
        callbacks.onFailed = @(fp, msg) addLog(sprintf('Failed to load %s: %s', fp, msg));
        [S.session, report] = labkit.dta.addFilesToSession(S.session, filepaths, "chrono", callbacks);
        postProcessAddedItems(report.added);
        S.items = S.session.items;
        if ~isempty(S.items) && isempty(S.current)
            S.current = 1;
        end
        refreshFileList();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();

        if ~isempty(report.failed)
            firstError = report.failed(1);
            uialert(fig, sprintf('Failed to load:\n%s\n\n%s', ...
                firstError.filepath, firstError.message), 'Load error');
        end
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

        A = vt_resistance.ops.computeResistance(item, opts);
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
        S.session = labkit.dta.makeSession('vt_resistance');
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
            labkit.ui.view.setListItems(ui, 'files', {});
            txtLoaded.Value = 'No files loaded';
            S.current = [];
            return;
        end

        names = {S.items.name};
        labkit.ui.view.setListItems(ui, 'files', names);
        if isempty(S.current) || S.current < 1 || S.current > numel(names)
            S.current = 1;
        end
        lbFiles.Value = names{S.current};
        txtLoaded.Value = sprintf('%d file(s) loaded', numel(S.items));
    end

    function refreshBatchTable()
        if isempty(S.items)
            tbl.Data = cell(0, 9);
            return;
        end
        tbl.Data = vt_resistance.view.buildBatchTableData(S.items);
    end

    function refreshResultsSummary()
        S.txtControlMode.Value = '-';
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
        S.txtControlMode.Value = chronoControlModeText(it);
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
        S.txtCathBaseWin.Value = vt_resistance.view.formatDurationUs(A.cathBaselineWindow_s);
        S.txtAnodBaseWin.Value = vt_resistance.view.formatDurationUs(A.anodBaselineWindow_s);
        S.txtCathR.Value = sprintf('%.6g ohm (signed %.6g)', A.Rc_abs_ohm, A.Rc_ohm);
        S.txtAnodR.Value = sprintf('%.6g ohm (signed %.6g)', A.Ra_abs_ohm, A.Ra_ohm);
        S.txtAvgR.Value = sprintf('%.6g ohm', A.Ravg_abs_ohm);
        S.txtStatus.Value = A.message;
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

    function refreshPlots()
        clearAxis(axTop);
        clearAxis(axBottom);
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
            cathStartX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.pulse.cath_start);
            cathEndX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.pulse.cath_end);
            anodStartX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.pulse.anod_start);
            anodEndX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.pulse.anod_end);
            cathBaseStartX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.pulse.pre_start);
            cathBaseEndX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.pulse.pre_end);
            anodBaseStartX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.anodBaselineStart);
            anodBaseEndX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.anodBaselineEnd);
            cSteadyStartX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.cathSteadyStart);
            cSteadyEndX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.cathSteadyEnd);
            aSteadyStartX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.anodSteadyStart);
            aSteadyEndX = vt_resistance.ops.interp1Safe(A.t, A.pt, A.anodSteadyEnd);
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
            vt_resistance.view.shadeWindow(ax, cathStartX, cathEndX, [0.90 0.95 1.00], 0.12);
            vt_resistance.view.shadeWindow(ax, anodStartX, anodEndX, [1.00 0.94 0.88], 0.12);
            vt_resistance.view.shadeWindow(ax, cSteadyStartX, cSteadyEndX, [0.65 0.82 1.00], 0.22);
            vt_resistance.view.shadeWindow(ax, aSteadyStartX, aSteadyEndX, [1.00 0.75 0.55], 0.22);
        end
        if cbShowMarkers.Value
            xline(ax, cathStartX, ':', 'Cath start','Color',[0.2 0.4 0.8]);
            xline(ax, cathEndX, ':', 'Cath end','Color',[0.2 0.4 0.8]);
            xline(ax, anodStartX, ':', 'Anod start','Color',[0.8 0.4 0.2]);
            xline(ax, anodEndX, ':', 'Anod end','Color',[0.8 0.4 0.2]);
            if startsWith(yChoice,'VT')
                vt_resistance.view.addResistanceVTAnnotations(ax, A, cathBaseStartX, cathBaseEndX, anodBaseStartX, anodBaseEndX, ...
                    cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, cathStartX, cathEndX, anodStartX, anodEndX);
            else
                vt_resistance.view.addResistanceITAnnotations(ax, A, cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, ...
                    cathStartX, cathEndX, anodStartX, anodEndX);
            end
        end
        hold(ax,'off');

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
        if isempty(S.items) || isempty(S.current)
            nm = 'file';
        else
            nm = S.items(S.current).name;
        end
    end

    function swapPlots()
        topX = ddTopX.Value;
        topY = ddTopY.Value;
        topGrid = cbTopGrid.Value;
        ddTopX.Value = ddBotX.Value;
        ddTopY.Value = ddBotY.Value;
        cbTopGrid.Value = cbBotGrid.Value;
        ddBotX.Value = topX;
        ddBotY.Value = topY;
        cbBotGrid.Value = topGrid;
        refreshPlots();
    end

    function resetAxes()
        resetAxesToDefaultState();
        refreshPlots();
    end

    function restoreDefaultPlotSelections()
        ddTopX.Value = topPlotDefaults.x;
        ddTopY.Value = topPlotDefaults.y;
        cbTopGrid.Value = topPlotDefaults.grid;
        ddBotX.Value = bottomPlotDefaults.x;
        ddBotY.Value = bottomPlotDefaults.y;
        cbBotGrid.Value = bottomPlotDefaults.grid;
    end

    function resetAxesToDefaultState()
        resetAxis(axTop, 'Top Plot');
        resetAxis(axBottom, 'Bottom Plot');
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
        [ok, msg] = vt_resistance.export.writeResultsCSV(S.items, out);
        if ~ok
            uialert(fig,msg,'Export');
            return;
        end
        addLog(['Exported CSV: ' out]);
    end

    function addLog(msg)
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
    end

end

function clearAxis(ax)
    cla(ax);
end

function resetAxis(ax, titleText)
    cla(ax);
    title(ax, titleText);
    xlabel(ax, '');
    ylabel(ax, '');
end
