% App-owned action table for CSC. Expected caller is csc.definition. Output
% maps semantic action ids to handlers used by labkit.ui.app.run. Handlers
% preserve the legacy CSC GUI workflow while moving package-root orchestration
% into the declarative runtime.
function actions = table()
    actions = struct( ...
        "startup", @onStartup, ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @clearAllFiles, ...
        "reloadSelected", @reloadSelectedFile, ...
        "fileSelectionChanged", @onSelectFile, ...
        "curveChanged", @onCurveChanged, ...
        "autoPresetAndRefresh", @autoPresetAndRefresh, ...
        "swapPlots", @onSwapPlots, ...
        "refreshCompare", @refreshCompare, ...
        "refreshPlotsOnly", @refreshPlotsOnly, ...
        "clearBothAxes", @clearBothAxes);
end

function state = onStartup(state, ~, services)
    if services.debug.enabled
        services.debug.trace('CSC debug trace enabled.');
        state = setupDebugSamples(state, services);
    end
end

function state = onOpenFilesChosen(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'Open file canceled.');
        return;
    end
    state = addFiles(state, paths, services);
end

function state = addFiles(state, filepaths, services)
    filepaths = normalizePaths(filepaths);
    if isempty(filepaths)
        return;
    end

    failed = struct('filepath', {}, 'message', {});
    for iFile = 1:numel(filepaths)
        filepath = filepaths(iFile);
        if isLoaded(state, filepath)
            addLog(services, ['Skipped duplicate: ' char(filepath)]);
            continue;
        end

        [item, status] = labkit.dta.loadFile(filepath, "cvct");
        if ~status.ok
            failed(end + 1) = struct( ...
                'filepath', char(filepath), ...
                'message', char(status.message));
            addLog(services, sprintf('Failed to load %s: %s', ...
                char(filepath), char(status.message)));
            continue;
        end

        state.items = appendItem(state.items, item);
        addLoadedItemLog(item, services);
    end
    if ~isempty(state.items) && isempty(state.current)
        state.current = 1;
    end
    state = refreshFileList(state, services);
    state = loadCurrentItem(state, services);

    if ~isempty(failed)
        firstError = failed(1);
        labkit.ui.app.showAlert(services.figure, ...
            sprintf('Failed to load:\n%s\n\n%s', ...
            firstError.filepath, firstError.message), 'Load error');
    end
end

function addLoadedItemLog(item, services)
    for iLog = 1:numel(item.logmsg)
        addLog(services, item.logmsg{iLog});
    end
    addLog(services, ['Loaded: ' item.filepath]);
end

function state = onSelectFile(state, ~, services)
    ui = services.ui;
    files = labkit.ui.view.getValue(ui, 'files');
    paths = labkit.ui.view.filePaths(files);
    if isempty(state.items) || isempty(paths)
        return;
    end
    idx = find(string({state.items.filepath}) == string(paths(1)), 1);
    if isempty(idx)
        idx = 1;
    end
    state.current = idx;
    state = loadCurrentItem(state, services);
end

function state = onRemoveSelected(state, payload, services)
    if isempty(state.items)
        return;
    end
    paths = labkit.ui.view.filePaths(payload.event.removedFiles);
    if isempty(paths)
        return;
    end
    [state, report] = removeItemsByPaths(state, paths);
    for k = 1:numel(report.removed)
        addLog(services, sprintf('Removed: %s', report.removed{k}));
    end
    state.current = min(state.current, numel(state.items));
    if isempty(state.items)
        state.current = [];
        state = clearCurrentItem(state, services);
    end
    state = refreshFileList(state, services);
    state = loadCurrentItem(state, services);
end

function state = clearAllFiles(state, ~, services)
    state.items = struct([]);
    state.current = [];
    state = clearCurrentItem(state, services);
    state = refreshFileList(state, services);
    clearBothAxes(state, [], services);
    addLog(services, 'Cleared all files.');
end

function state = reloadSelectedFile(state, ~, services)
    if isempty(state.items) || isempty(state.current)
        labkit.ui.app.showAlert(services.figure, 'No file selected.', ...
            'Reload');
        addLog(services, 'Reload failed: no file selected.');
        return;
    end
    filepath = state.items(state.current).filepath;
    state = removeItemsByPaths(state, filepath);
    state.current = [];
    state = addFiles(state, {filepath}, services);
end

function state = refreshFileList(state, services)
    ui = services.ui;
    if isempty(state.items)
        labkit.ui.view.setListItems(ui, 'files', {});
        ui.controls.files.status.Value = 'No files loaded';
        return;
    end
    paths = string({state.items.filepath}).';
    labkit.ui.view.setValue(ui, 'files', paths);
    if isempty(state.current) || state.current < 1 || ...
            state.current > numel(paths)
        state.current = 1;
    end
    files = labkit.ui.view.getFiles(ui, 'files');
    labkit.ui.view.setFileSelection(ui, 'files', files(state.current));
    ui.controls.files.status.Value = sprintf('%d file(s) loaded', ...
        numel(state.items));
end

function state = loadCurrentItem(state, services)
    ui = services.ui;
    if isempty(state.items)
        state = clearCurrentItem(state, services);
        return;
    end
    if isempty(state.current) || state.current < 1 || ...
            state.current > numel(state.items)
        state.current = 1;
    end
    state.items(state.current).currentCurve = 1;
    state.items(state.current).analysis = [];
    item = state.items(state.current);
    state.filepath = item.filepath;
    state.scanRate = item.scanRate;
    state.curves = item.curves;
    state.currentCurve = 1;
    ui.controls.filePath.valueHandle.Value = item.filepath;

    if isnan(state.scanRate)
        ui.controls.scanRate.valueHandle.Value = 'Not found';
    else
        ui.controls.scanRate.valueHandle.Value = sprintf( ...
            '%.6f V/s (%.3f mV/s)', state.scanRate, ...
            state.scanRate * 1000);
    end

    if isempty(state.curves)
        ui.controls.curve.valueHandle.Items = {'(none)'};
        ui.controls.curve.valueHandle.Value = '(none)';
        ui.controls.status.valueHandle.Value = 'No curve found';
        addLog(services, 'No curve parsed.');
        return;
    end

    items = cell(1, numel(state.curves));
    for k = 1:numel(state.curves)
        items{k} = sprintf('%s (%d rows)', state.curves(k).name, ...
            size(state.curves(k).data, 1));
    end
    ui.controls.curve.valueHandle.Items = items;
    ui.controls.curve.valueHandle.Value = items{1};

    ui.controls.status.valueHandle.Value = sprintf('Loaded %d curve(s)', ...
        numel(state.curves));
    addLog(services, sprintf('Loaded %d curve(s) from %s.', ...
        numel(state.curves), item.name));

    state = updateDropdowns(state, services);
    state = autoSetDefaults(state, services);
    state = refreshAll(state, [], services);
end

function state = clearCurrentItem(state, services)
    ui = services.ui;
    state.filepath = '';
    state.scanRate = NaN;
    state.curves = struct('name', {}, 'headers', {}, 'units', {}, ...
        'data', {}, 'numericMask', {});
    state.currentCurve = 1;
    ui.controls.filePath.valueHandle.Value = '';
    ui.controls.scanRate.valueHandle.Value = '';
    ui.controls.curve.valueHandle.Items = {'(none)'};
    ui.controls.curve.valueHandle.Value = '(none)';
    ui.controls.status.valueHandle.Value = 'Ready';
    ui.controls.qct.valueHandle.Value = '';
    ui.controls.qcv.valueHandle.Value = '';
    ui.controls.diff.valueHandle.Value = '';
    ui.controls.relativeDiff.valueHandle.Value = '';
    ui.controls.dtError.valueHandle.Value = '';
end

function state = onCurveChanged(state, ~, services)
    ui = services.ui;
    if isempty(state.curves)
        return;
    end
    idx = find(strcmp(ui.controls.curve.valueHandle.Items, ...
        ui.controls.curve.valueHandle.Value), 1);
    if isempty(idx)
        idx = 1;
    end
    state.currentCurve = idx;
    state = syncSessionCurrentCurve(state);
    addLog(services, sprintf('Selected curve %d', idx));
    state = updateDropdowns(state, services);
    state = autoSetDefaults(state, services);
    state = refreshAll(state, [], services);
end

function state = autoPresetAndRefresh(state, ~, services)
    state = autoSetDefaults(state, services);
    state = refreshAll(state, [], services);
end

function state = onSwapPlots(state, ~, services)
    ui = services.ui;
    tx = ui.controls.topX.valueHandle.Value;
    ty = ui.controls.topY.valueHandle.Value;
    tg = ui.controls.topGrid.valueHandle.Value;
    th = ui.controls.topHold.valueHandle.Value;
    tt = ui.controls.topTrim.valueHandle.Value;
    bx = ui.controls.bottomX.valueHandle.Value;
    by = ui.controls.bottomY.valueHandle.Value;

    if any(strcmp(ui.controls.topX.valueHandle.Items, bx))
        ui.controls.topX.valueHandle.Value = bx;
    end
    if any(strcmp(ui.controls.topY.valueHandle.Items, by))
        ui.controls.topY.valueHandle.Value = by;
    end
    ui.controls.topGrid.valueHandle.Value = ui.controls.bottomGrid.valueHandle.Value;
    ui.controls.topHold.valueHandle.Value = ui.controls.bottomHold.valueHandle.Value;
    ui.controls.topTrim.valueHandle.Value = ui.controls.bottomTrim.valueHandle.Value;
    if any(strcmp(ui.controls.bottomX.valueHandle.Items, tx))
        ui.controls.bottomX.valueHandle.Value = tx;
    end
    if any(strcmp(ui.controls.bottomY.valueHandle.Items, ty))
        ui.controls.bottomY.valueHandle.Value = ty;
    end
    ui.controls.bottomGrid.valueHandle.Value = tg;
    ui.controls.bottomHold.valueHandle.Value = th;
    ui.controls.bottomTrim.valueHandle.Value = tt;

    addLog(services, 'Swapped top/bottom selections.');
    state = refreshPlotsOnly(state, [], services);
    state = refreshCompare(state, [], services);
end

function state = clearBothAxes(state, ~, services)
    axesById = services.ui.controls.plotAxes.axesById;
    cla(axesById.top);
    cla(axesById.bottom);
    title(axesById.top, 'Top Plot');
    xlabel(axesById.top, 'X');
    ylabel(axesById.top, 'Y');
    title(axesById.bottom, 'Bottom Plot');
    xlabel(axesById.bottom, 'X');
    ylabel(axesById.bottom, 'Y');
    addLog(services, 'Cleared both axes.');
end

function state = syncSessionCurrentCurve(state)
    if ~isempty(state.items) && ~isempty(state.current)
        state.items(state.current).currentCurve = state.currentCurve;
    end
end

function state = updateDropdowns(state, services)
    ui = services.ui;
    if isempty(state.curves)
        return;
    end
    curve = state.curves(state.currentCurve);
    cols = curve.headers(curve.numericMask);
    if isempty(cols)
        cols = {'(none)'};
    end
    ui.controls.topX.valueHandle.Items = cols;
    ui.controls.topY.valueHandle.Items = cols;
    ui.controls.bottomX.valueHandle.Items = cols;
    ui.controls.bottomY.valueHandle.Items = cols;
    addLog(services, ['Numeric columns: ' strjoin(cols, ', ')]);
end

function state = autoSetDefaults(state, services)
    ui = services.ui;
    if isempty(state.curves)
        return;
    end
    defaults = csc.view.defaultPlotSelections(ui.controls.topX.valueHandle.Items);
    ui.controls.topX.valueHandle.Value = defaults.topX;
    ui.controls.topY.valueHandle.Value = defaults.topY;
    ui.controls.bottomX.valueHandle.Value = defaults.bottomX;
    ui.controls.bottomY.valueHandle.Value = defaults.bottomY;
end

function state = refreshPlotsOnly(state, ~, services)
    if isempty(state.curves)
        return;
    end
    plotTop(state, services);
    plotBottom(state, services);
end

function state = refreshAll(state, ~, services)
    state = refreshPlotsOnly(state, [], services);
    state = refreshCompare(state, [], services);
end

function plotTop(state, services)
    if isempty(state.curves)
        return;
    end
    ui = services.ui;
    curve = state.curves(state.currentCurve);
    opts = struct('holdPlot', ui.controls.topHold.valueHandle.Value, ...
        'showGrid', ui.controls.topGrid.valueHandle.Value, ...
        'lineWidth', 1.2);
    request = csc.view.plotRequest(curve, ...
        ui.controls.topX.valueHandle.Value, ...
        ui.controls.topY.valueHandle.Value, 'Top');
    info = csc.ui.plotXY(ui.controls.plotAxes.axesById.top, request.x, ...
        request.y, request.labels, opts);
    if ~info.ok
        addLog(services, request.skipLog);
        return;
    end
    addLog(services, request.successLog);
end

function plotBottom(state, services)
    if isempty(state.curves)
        return;
    end
    ui = services.ui;
    curve = state.curves(state.currentCurve);
    opts = struct('holdPlot', ui.controls.bottomHold.valueHandle.Value, ...
        'showGrid', ui.controls.bottomGrid.valueHandle.Value, ...
        'lineWidth', 1.2);
    request = csc.view.plotRequest(curve, ...
        ui.controls.bottomX.valueHandle.Value, ...
        ui.controls.bottomY.valueHandle.Value, 'Bottom');
    info = csc.ui.plotXY(ui.controls.plotAxes.axesById.bottom, request.x, ...
        request.y, request.labels, opts);
    if ~info.ok
        addLog(services, request.skipLog);
        return;
    end
    addLog(services, request.successLog);
end

function state = refreshCompare(state, ~, services)
    ui = services.ui;
    if isempty(state.curves)
        ui.controls.qct.valueHandle.Value = '';
        ui.controls.qcv.valueHandle.Value = '';
        ui.controls.diff.valueHandle.Value = '';
        ui.controls.relativeDiff.valueHandle.Value = '';
        ui.controls.dtError.valueHandle.Value = '';
        return;
    end

    curve = state.curves(state.currentCurve);
    opts = struct();
    opts.mode = ui.controls.mode.valueHandle.Value;
    opts.scanRate = state.scanRate;
    opts.area_cm2 = ui.controls.area.valueHandle.Value;
    result = csc.ops.computeCSC(curve, opts);
    readout = csc.view.comparisonReadout(result, ui.controls.mode.valueHandle.Value);

    ui.controls.qct.valueHandle.Value = readout.qctText;
    ui.controls.qcv.valueHandle.Value = readout.qcvText;
    ui.controls.diff.valueHandle.Value = readout.diffText;
    ui.controls.relativeDiff.valueHandle.Value = readout.relText;
    ui.controls.dtError.valueHandle.Value = readout.dtErrText;

    if ~readout.ok
        if ~isempty(readout.logMessage)
            addLog(services, readout.logMessage);
        end
        return;
    end

    axesById = ui.controls.plotAxes.axesById;
    clearTrim(axesById.top);
    clearTrim(axesById.bottom);

    drawTrimOverlay(axesById.top, ui.controls.topTrim.valueHandle.Value, ...
        ui.controls.topX.valueHandle.Value, ...
        ui.controls.topY.valueHandle.Value, curve, result);
    drawTrimOverlay(axesById.bottom, ui.controls.bottomTrim.valueHandle.Value, ...
        ui.controls.bottomX.valueHandle.Value, ...
        ui.controls.bottomY.valueHandle.Value, curve, result);

    if ~isempty(readout.logMessage)
        addLog(services, readout.logMessage);
    end
    ui.controls.status.valueHandle.Value = readout.statusText;
end

function addLog(services, msg)
    labkit.ui.view.appendLog(services.ui, 'appLog', msg);
    services.debug.append(msg);
end

function state = setupDebugSamples(state, services)
    try
        pack = csc.debug.writeSamplePack(services.debug);
        addLog(services, sprintf('Debug sample files: %s', ...
            char(pack.sampleFolder)));
        addLog(services, sprintf('Debug output folder: %s', ...
            char(pack.outputFolder)));
    catch ME
        services.debug.reportException('csc', 'Debug sample setup failed', ME);
        addLog(services, sprintf('Debug sample setup failed: %s', ME.message));
    end
end

function [state, report] = removeItemsByPaths(state, filepaths)
    paths = normalizePaths(filepaths);
    report = struct('removed', {{}}, 'missing', {{}});
    if isempty(paths)
        return;
    end
    if isempty(state.items)
        report.missing = cellstr(paths(:).');
        return;
    end
    keep = true(1, numel(state.items));
    itemPaths = string({state.items.filepath});
    for k = 1:numel(paths)
        idx = find(itemPaths == paths(k) & keep, 1, 'first');
        if isempty(idx)
            report.missing{end + 1} = char(paths(k));
            continue;
        end
        report.removed{end + 1} = char(paths(k));
        keep(idx) = false;
    end
    state.items = state.items(keep);
end

function tf = isLoaded(state, filepath)
    tf = ~isempty(state.items) && ...
        any(string({state.items.filepath}) == string(filepath));
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

function drawTrimOverlay(ax, enabled, xSelection, ySelection, curve, result)
    if ~enabled || ~strcmp(ySelection, 'Im')
        return;
    end

    [xValues, ~, ~, ~] = labkit.dta.getCurveXY(curve, xSelection, ySelection);
    overlay = csc.view.trimOverlayData(enabled, ySelection, xValues, result);
    if ~overlay.ok
        return;
    end

    hold(ax, 'on');
    plot(ax, overlay.x, overlay.cathY, 'Color', [0.1 0.6 0.1], ...
        'LineWidth', 1.0, 'Tag', 'trimCath');
    plot(ax, overlay.x, overlay.anodY, 'Color', [0.8 0.3 0.1], ...
        'LineWidth', 1.0, 'Tag', 'trimAnod');
    hold(ax, 'off');
end

function clearTrim(ax)
    delete(findobj(ax, 'Tag', 'trimCath'));
    delete(findobj(ax, 'Tag', 'trimAnod'));
end
