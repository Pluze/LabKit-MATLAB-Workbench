% App-owned runner extracted from labkit_CIC_app.m. Expected caller: labkit_CIC_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUNCICAPP Build and run the app body.

    S = struct();
    S.items = struct([]); % loaded files + parsed content + analysis
    S.current = [];

    callbacks = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @(~,~) clearAllFiles(), ...
        "exportResults", @(~,~) exportResultsCSV(), ...
        "fileSelectionChanged", @(~,~) onSelectFile(), ...
        "presetChanged", @(~,~) onPresetChanged(), ...
        "analyzeCurrentFile", @(~,~) analyzeCurrentFile(), ...
        "refreshResultsSummary", @(~,~) refreshResultsSummary(), ...
        "refreshCICUnitDisplays", @(~,~) refreshCICUnitDisplays(), ...
        "refreshPlots", @(~,~) refreshPlots(), ...
        "swapPlots", @(~,~) swapPlots(), ...
        "resetAxes", @(~,~) resetAxes());
    spec = cic.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);

    fig = ui.figure;
    txtLoaded = ui.controls.files.status;
    ddPreset = ui.controls.preset.valueHandle;
    edCathLim = ui.controls.cathLimit.valueHandle;
    edAnodLim = ui.controls.anodLimit.valueHandle;
    edDelayUs = ui.controls.delayUs.valueHandle;
    edArea = ui.controls.area.valueHandle;
    ddPulseMode = ui.controls.pulseMode.valueHandle;
    ddCICMode = ui.controls.cicMode.valueHandle;
    ddCICUnit = ui.controls.cicUnit.valueHandle;
    cbUseMeasuredCurrent = ui.controls.useMeasuredCurrent.valueHandle;
    S.txtControlMode = ui.controls.controlMode.valueHandle;
    S.txtDetect = ui.controls.detect.valueHandle;
    S.txtDelay = ui.controls.delay.valueHandle;
    S.txtArea = ui.controls.areaSummary.valueHandle;
    S.txtEmc = ui.controls.emc.valueHandle;
    S.txtEma = ui.controls.ema.valueHandle;
    S.txtQc = ui.controls.qc.valueHandle;
    S.txtQa = ui.controls.qa.valueHandle;
    S.txtQt = ui.controls.qt.valueHandle;
    S.txtSafe = ui.controls.safe.valueHandle;
    S.txtBest = ui.controls.best.valueHandle;
    cbShowMarkers = ui.controls.showMarkers.valueHandle;
    cbShowLimits = ui.controls.showLimits.valueHandle;
    cbShowShading = ui.controls.showShading.valueHandle;
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
        debugLog.trace('CIC debug trace enabled.');
        setupDebugSamples();
    end
    %% App callbacks, session actions, refresh, plotting, and export
    function onPresetChanged()
        switch ddPreset.Value
            case 'Pt (-0.6 to 0.8 V)'
                labkit.ui.view.setValue(ui, "cathLimit", -0.6);
                labkit.ui.view.setValue(ui, "anodLimit", 0.8);
            case 'PEDOT:PSS (-0.9 to 0.6 V)'
                labkit.ui.view.setValue(ui, "cathLimit", -0.9);
                labkit.ui.view.setValue(ui, "anodLimit", 0.6);
            otherwise
                % keep manual values
        end
        analyzeCurrentFile();
    end

    function onOpenFilesChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Open cancelled.');
            return;
        end
        loadDTAFiles(paths);
    end

    function loadDTAFiles(filepaths)
        filepaths = normalizePaths(filepaths);
        if isempty(filepaths)
            return;
        end

        failed = struct('filepath', {}, 'message', {});
        for iFile = 1:numel(filepaths)
            filepath = filepaths(iFile);
            if isLoaded(filepath)
                addLog(sprintf('Skipped already loaded: %s', char(filepath)));
                continue;
            end

            [item, status] = labkit.dta.loadFile(filepath, "chrono");
            if ~status.ok
                failed(end + 1) = struct( ...
                    'filepath', char(filepath), ...
                    'message', char(status.message));
                addLog(sprintf('Failed: %s | %s', char(filepath), char(status.message)));
                continue;
            end

            item.analysis = [];
            for ii = 1:numel(item.logmsg)
                addLog(item.logmsg{ii});
            end
            item = analyzeItem(item);
            S.items = appendItem(S.items, item);
            addLog(sprintf('Loaded: %s', char(filepath)));
        end

        refreshFileList();
        restoreDefaultPlotSelections();
        resetAxesToDefaultState();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();

        if ~isempty(failed)
            firstError = failed(1);
            labkit.ui.app.showAlert(fig, sprintf('Failed to load:\n%s\n\n%s', firstError.filepath, firstError.message), 'Load error');
        end
    end

    function analyzeCurrentFile()
        if isempty(S.items) || isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            refreshResultsSummary();
            refreshPlots();
            return;
        end
        S.items(S.current) = analyzeItem(S.items(S.current));
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
        files = labkit.ui.view.getValue(ui, 'files');
        paths = labkit.ui.view.filePaths(files);
        if isempty(paths)
            S.current = [];
            resetAxesToDefaultState();
            refreshResultsSummary();
            refreshPlots();
            return;
        end

        idx = find(string({S.items.filepath}) == string(paths(1)), 1);
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

    function onRemoveSelected(~, event)
        if isempty(S.items)
            return;
        end
        paths = labkit.ui.view.filePaths(event.removedFiles);
        if isempty(paths)
            return;
        end
        report = removeItemsByPaths(paths);
        for k = 1:numel(report.removed)
            addLog(sprintf('Removed: %s', report.removed{k}));
        end
        S.current = min(S.current, numel(S.items));
        if isempty(S.items)
            S.current = [];
        end
        restoreDefaultPlotSelections();
        resetAxesToDefaultState();
        refreshFileList();
        refreshBatchTable();
        refreshResultsSummary();
        refreshPlots();
    end

    function clearAllFiles()
        S.items = struct([]);
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

        paths = string({S.items.filepath}).';
        labkit.ui.view.setValue(ui, 'files', paths);
        if isempty(S.current) || S.current < 1 || S.current > numel(paths)
            S.current = 1;
        end
        files = labkit.ui.view.getFiles(ui, 'files');
        labkit.ui.view.setFileSelection(ui, 'files', files(S.current));
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
            labkit.ui.app.showAlert(fig,'No results to export.','Export');
            return;
        end
        [out, cancelled] = labkit.ui.app.promptOutputFile( ...
            'cic_results.csv', 'Save results CSV', 'cic_results.csv');
        if cancelled
            return;
        end
        [~, unitLabel] = cic.view.displayUnit(ddCICUnit.Value);
        [ok, msg] = cic.export.writeResultsCSV(S.items, out, unitLabel);
        if ~ok
            labkit.ui.app.showAlert(fig,msg,'Export');
            return;
        end
        addLog(['Exported CSV: ' char(out)]);
    end

    %% ===================== Logging =====================
    function addLog(msg)
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
    end

    function setupDebugSamples()
        try
            pack = cic.debug.writeSamplePack(debugLog);
            addLog(sprintf('Debug sample files: %s', char(pack.sampleFolder)));
            addLog(sprintf('Debug output folder: %s', char(pack.outputFolder)));
        catch ME
            debugLog.reportException('cic', 'Debug sample setup failed', ME);
            addLog(sprintf('Debug sample setup failed: %s', ME.message));
        end
    end

    function report = removeItemsByPaths(filepaths)
        paths = normalizePaths(filepaths);
        report = struct('removed', {{}}, 'missing', {{}});
        if isempty(paths)
            return;
        end
        if isempty(S.items)
            report.missing = cellstr(paths(:).');
            return;
        end
        keep = true(1, numel(S.items));
        itemPaths = string({S.items.filepath});
        for k = 1:numel(paths)
            idx = find(itemPaths == paths(k) & keep, 1, 'first');
            if isempty(idx)
                report.missing{end + 1} = char(paths(k));
                continue;
            end
            report.removed{end + 1} = char(paths(k));
            keep(idx) = false;
        end
        S.items = S.items(keep);
    end

    function tf = isLoaded(filepath)
        tf = ~isempty(S.items) && any(string({S.items.filepath}) == string(filepath));
    end

    function paths = normalizePaths(paths)
        paths = string(paths(:));
        paths = paths(strlength(paths) > 0);
    end

    function items = appendItem(items, item)
        if isempty(items)
            items = item;
        else
            items(end + 1) = item;
        end
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
