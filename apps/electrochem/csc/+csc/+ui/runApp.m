% App-owned runner extracted from labkit_CSC_app.m. Expected caller: labkit_CSC_app.
% Input is the debug context prepared by the public launcher. Output is the app
% figure. Side effects are GUI creation, user-driven file I/O, exports,
% plotting, and debug trace attachment exactly as in the original entrypoint body.
function fig = runApp(debugLog)
%RUNCSCAPP Build and run the app body.

    S = struct();
    S.session = labkit.dta.makeSession('cv_csc');
    S.filepath = '';
    S.items = S.session.items;
    S.current = [];
    S.curves = struct('name',{},'headers',{},'units',{},'data',{},'numericMask',{});
    S.scanRate = NaN; % V/s
    S.currentCurve = 1;

    callbacks = struct( ...
        'onOpenFiles', @onOpenFiles, ...
        'onOpenFolder', @onOpenFolder, ...
        'onClearAll', @(~,~) clearAllFiles(), ...
        'onExport', @(~,~) reloadSelectedFile(), ...
        'onSelectFile', @(~,~) onSelectFile(), ...
        'onCurveChanged', @(~,~) onCurveChanged(), ...
        'onAutoPresetAndRefresh', @(~,~) autoPresetAndRefresh(), ...
        'onSwapPlots', @(~,~) onSwapPlots(), ...
        'onRefreshCompare', @(~,~) refreshCompare(), ...
        'onRefreshPlotsOnly', @(~,~) refreshPlotsOnly(), ...
        'onClearBothAxes', @(~,~) clearBothAxes());
    C = csc.ui.buildControls(callbacks);

    fig = C.fig;
    lbFiles = C.lbFiles;
    txtLoaded = C.txtLoaded;
    txtFile = C.txtFile;
    txtScan = C.txtScan;
    ddCurve = C.ddCurve;
    ddMode = C.ddMode;
    edArea = C.edArea;
    txtQct = C.txtQct;
    txtQcv = C.txtQcv;
    txtDiff = C.txtDiff;
    txtRel = C.txtRel;
    txtDtErr = C.txtDtErr;
    lblStatus = C.lblStatus;
    txtLog = C.txtLog;
    plotControls = C.plotControls;
    ddTopX = C.ddTopX;
    ddTopY = C.ddTopY;
    cbTopGrid = C.cbTopGrid;
    ddBotX = C.ddBotX;
    ddBotY = C.ddBotY;
    cbBotGrid = C.cbBotGrid;
    axTop = C.axTop;
    axBottom = C.axBottom;
    cbTopHold = C.cbTopHold;
    cbTopTrim = C.cbTopTrim;
    cbBotHold = C.cbBotHold;
    cbBotTrim = C.cbBotTrim;
    if debugLog.enabled
        debugLog.attachTextLog(txtLog);
        debugLog.trace('CSC debug trace enabled.');
        debugLog.instrumentFigure(fig);
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
        lblStatus.Text = readout.statusText;
    end

    function addLog(msg)
        labkit.ui.view.update(txtLog, 'appendLog', msg);
        debugLog.append(msg);
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
