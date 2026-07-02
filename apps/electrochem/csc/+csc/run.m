% App-owned runner extracted from labkit_CSC_app.m. Expected caller: labkit_CSC_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = run(debugLog)
%RUNCSCAPP Build and run the app body.

    S = struct();
    S.filepath = '';
    S.items = struct([]);
    S.current = [];
    S.curves = struct('name',{},'headers',{},'units',{},'data',{},'numericMask',{});
    S.scanRate = NaN; % V/s
    S.currentCurve = 1;

    callbacks = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @(~,~) clearAllFiles(), ...
        "reloadSelected", @(~,~) reloadSelectedFile(), ...
        "fileSelectionChanged", @(~,~) onSelectFile(), ...
        "curveChanged", @(~,~) onCurveChanged(), ...
        "autoPresetAndRefresh", @(~,~) autoPresetAndRefresh(), ...
        "swapPlots", @(~,~) onSwapPlots(), ...
        "refreshCompare", @(~,~) refreshCompare(), ...
        "refreshPlotsOnly", @(~,~) refreshPlotsOnly(), ...
        "clearBothAxes", @(~,~) clearBothAxes());
    spec = csc.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);

    fig = ui.figure;
    txtLoaded = ui.controls.files.status;
    txtFile = ui.controls.filePath.valueHandle;
    txtScan = ui.controls.scanRate.valueHandle;
    ddCurve = ui.controls.curve.valueHandle;
    ddMode = ui.controls.mode.valueHandle;
    edArea = ui.controls.area.valueHandle;
    txtQct = ui.controls.qct.valueHandle;
    txtQcv = ui.controls.qcv.valueHandle;
    txtDiff = ui.controls.diff.valueHandle;
    txtRel = ui.controls.relativeDiff.valueHandle;
    txtDtErr = ui.controls.dtError.valueHandle;
    txtStatus = ui.controls.status.valueHandle;
    ddTopX = ui.controls.topX.valueHandle;
    ddTopY = ui.controls.topY.valueHandle;
    cbTopGrid = ui.controls.topGrid.valueHandle;
    ddBotX = ui.controls.bottomX.valueHandle;
    ddBotY = ui.controls.bottomY.valueHandle;
    cbBotGrid = ui.controls.bottomGrid.valueHandle;
    axTop = ui.controls.plotAxes.axesById.top;
    axBottom = ui.controls.plotAxes.axesById.bottom;
    cbTopHold = ui.controls.topHold.valueHandle;
    cbTopTrim = ui.controls.topTrim.valueHandle;
    cbBotHold = ui.controls.bottomHold.valueHandle;
    cbBotTrim = ui.controls.bottomTrim.valueHandle;
    if debugLog.enabled
        debugLog.trace('CSC debug trace enabled.');
        setupDebugSamples();
    end
    %% App callbacks, loading, refresh, and plotting
    function onOpenFilesChosen(~, event)
        paths = labkit.ui.view.filePaths(event.addedFiles);
        if isempty(paths)
            addLog('Open file canceled.');
            return;
        end
        addFiles(paths);
    end

    function addFiles(filepaths)
        filepaths = normalizePaths(filepaths);
        if isempty(filepaths)
            return;
        end

        failed = struct('filepath', {}, 'message', {});
        for iFile = 1:numel(filepaths)
            filepath = filepaths(iFile);
            if isLoaded(filepath)
                addLog(['Skipped duplicate: ' char(filepath)]);
                continue;
            end

            [item, status] = labkit.dta.loadFile(filepath, "cvct");
            if ~status.ok
                failed(end + 1) = struct( ...
                    'filepath', char(filepath), ...
                    'message', char(status.message));
                addLog(sprintf('Failed to load %s: %s', char(filepath), char(status.message)));
                continue;
            end

            S.items = appendItem(S.items, item);
            onAddedItem(item);
        end
        if ~isempty(S.items) && isempty(S.current)
            S.current = 1;
        end
        refreshFileList();
        loadCurrentItem();

        if ~isempty(failed)
            firstError = failed(1);
            labkit.ui.app.showAlert(fig, sprintf('Failed to load:\n%s\n\n%s', ...
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
        files = labkit.ui.view.getValue(ui, 'files');
        paths = labkit.ui.view.filePaths(files);
        if isempty(S.items) || isempty(paths)
            return;
        end
        idx = find(string({S.items.filepath}) == string(paths(1)), 1);
        if isempty(idx)
            idx = 1;
        end
        S.current = idx;
        loadCurrentItem();
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
            clearCurrentItem();
        end
        refreshFileList();
        loadCurrentItem();
    end

    function clearAllFiles()
        S.items = struct([]);
        S.current = [];
        clearCurrentItem();
        refreshFileList();
        clearBothAxes();
        addLog('Cleared all files.');
    end

    function reloadSelectedFile()
        if isempty(S.items) || isempty(S.current)
            labkit.ui.app.showAlert(fig,'No file selected.','Reload');
            addLog('Reload failed: no file selected.');
            return;
        end
        filepath = S.items(S.current).filepath;
        removeItemsByPaths(filepath);
        S.current = [];
        addFiles({filepath});
    end

    function refreshFileList()
        if isempty(S.items)
            labkit.ui.view.setListItems(ui, 'files', {});
            txtLoaded.Value = 'No files loaded';
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

    function loadCurrentItem()
        if isempty(S.items)
            clearCurrentItem();
            return;
        end
        if isempty(S.current) || S.current < 1 || S.current > numel(S.items)
            S.current = 1;
        end
        S.items(S.current).currentCurve = 1;
        S.items(S.current).analysis = [];
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
            txtStatus.Value = 'No curve found';
            addLog('No curve parsed.');
            return;
        end

        items = cell(1,numel(S.curves));
        for k = 1:numel(S.curves)
            items{k} = sprintf('%s (%d rows)', S.curves(k).name, size(S.curves(k).data,1));
        end
        ddCurve.Items = items;
        ddCurve.Value = items{1};

        txtStatus.Value = sprintf('Loaded %d curve(s)', numel(S.curves));
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
        txtStatus.Value = 'Ready';
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
        tx = ddTopX.Value;
        ty = ddTopY.Value;
        tg = cbTopGrid.Value;
        th = cbTopHold.Value;
        tt = cbTopTrim.Value;
        bx = ddBotX.Value;
        by = ddBotY.Value;

        if any(strcmp(ddTopX.Items, bx)), ddTopX.Value = bx; end
        if any(strcmp(ddTopY.Items, by)), ddTopY.Value = by; end
        cbTopGrid.Value = cbBotGrid.Value;
        cbTopHold.Value = cbBotHold.Value;
        cbTopTrim.Value = cbBotTrim.Value;
        if any(strcmp(ddBotX.Items, tx)), ddBotX.Value = tx; end
        if any(strcmp(ddBotY.Items, ty)), ddBotY.Value = ty; end
        cbBotGrid.Value = tg;
        cbBotHold.Value = th;
        cbBotTrim.Value = tt;

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
        if ~isempty(S.items) && ~isempty(S.current)
            S.items(S.current).currentCurve = S.currentCurve;
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
        defaults = csc.view.defaultPlotSelections(ddTopX.Items);
        ddTopX.Value = defaults.topX;
        ddTopY.Value = defaults.topY;
        ddBotX.Value = defaults.bottomX;
        ddBotY.Value = defaults.bottomY;
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
        request = csc.view.plotRequest(c, ddTopX.Value, ddTopY.Value, 'Top');
        info = csc.ui.plotXY(axTop, request.x, request.y, request.labels, opts);
        if ~info.ok
            addLog(request.skipLog);
            return;
        end
        addLog(request.successLog);
    end

    function plotBottom()
        if isempty(S.curves), return; end
        c = S.curves(S.currentCurve);
        opts = struct('holdPlot', cbBotHold.Value, 'showGrid', cbBotGrid.Value, 'lineWidth', 1.2);
        request = csc.view.plotRequest(c, ddBotX.Value, ddBotY.Value, 'Bottom');
        info = csc.ui.plotXY(axBottom, request.x, request.y, request.labels, opts);
        if ~info.ok
            addLog(request.skipLog);
            return;
        end
        addLog(request.successLog);
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
        R = csc.ops.computeCSC(c, opts);
        readout = csc.view.comparisonReadout(R, ddMode.Value);

        txtQct.Value = readout.qctText;
        txtQcv.Value = readout.qcvText;
        txtDiff.Value = readout.diffText;
        txtRel.Value = readout.relText;
        txtDtErr.Value = readout.dtErrText;

        if ~readout.ok
            if ~isempty(readout.logMessage)
                addLog(readout.logMessage);
            end
            return;
        end

        clearTrim(axTop);
        clearTrim(axBottom);

        drawTrimOverlay(axTop, cbTopTrim.Value, ddTopX.Value, ddTopY.Value, c, R);
        drawTrimOverlay(axBottom, cbBotTrim.Value, ddBotX.Value, ddBotY.Value, c, R);

        if ~isempty(readout.logMessage)
            addLog(readout.logMessage);
        end
        txtStatus.Value = readout.statusText;
    end

    function addLog(msg)
        labkit.ui.view.appendLog(ui, 'appLog', msg);
        debugLog.append(msg);
    end

    function setupDebugSamples()
        try
            pack = csc.debug.writeSamplePack(debugLog);
            addLog(sprintf('Debug sample files: %s', char(pack.sampleFolder)));
            addLog(sprintf('Debug output folder: %s', char(pack.outputFolder)));
        catch ME
            debugLog.reportException('csc', 'Debug sample setup failed', ME);
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

%% App-local trim overlay drawing

function drawTrimOverlay(ax, enabled, xSelection, ySelection, curve, result)
    if ~enabled || ~strcmp(ySelection, 'Im')
        return;
    end

    [xValues, ~, ~, ~] = labkit.dta.getCurveXY(curve, xSelection, ySelection);
    overlay = csc.view.trimOverlayData(enabled, ySelection, xValues, result);
    if ~overlay.ok
        return;
    end

    hold(ax,'on');
    plot(ax, overlay.x, overlay.cathY, 'Color',[0.1 0.6 0.1], ...
        'LineWidth',1.0,'Tag','trimCath');
    plot(ax, overlay.x, overlay.anodY, 'Color',[0.8 0.3 0.1], ...
        'LineWidth',1.0,'Tag','trimAnod');
    hold(ax,'off');
end

function clearTrim(ax)
    delete(findobj(ax,'Tag','trimCath'));
    delete(findobj(ax,'Tag','trimAnod'));
end
