% App-owned action table for CIC. Expected caller is cic.definition. Output
% maps semantic action ids to handlers used by labkit.ui.runtime.run. Handlers
% own workflow transitions, DTA loading, analysis, and export side effects.
function actions = definitionActions()
    actions = struct( ...
        "startup", @onStartup, ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportResults", @onExportResults, ...
        "fileSelectionChanged", @onFileSelectionChanged, ...
        "presetChanged", @onPresetChanged, ...
        "analysisChanged", @onAnalyzeAllFiles, ...
        "refreshResultsSummary", @onRefreshOnly, ...
        "refreshCICUnitDisplays", @onRefreshOnly, ...
        "refreshPlots", @onRefreshOnly);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if ~isDebugEnabled(debugLog)
        return;
    end
    debugLog.trace('CIC debug trace enabled.');
    try
        pack = cic.debug.writeSamplePack(debugLog);
        addLog(services, sprintf('Debug sample files: %s', char(pack.sampleFolder)));
        addLog(services, sprintf('Debug output folder: %s', char(pack.outputFolder)));
    catch ME
        debugLog.reportException('cic', 'Debug sample setup failed', ME);
        addLog(services, sprintf('Debug sample setup failed: %s', ME.message));
    end
end

function state = onPresetChanged(state, ~, services)
    switch services.ui.controls.preset.valueHandle.Value
        case 'Pt (-0.6 to 0.8 V)'
            labkit.ui.control.setValue(services.ui, "cathLimit", -0.6);
            labkit.ui.control.setValue(services.ui, "anodLimit", 0.8);
        case 'PEDOT:PSS (-0.9 to 0.6 V)'
            labkit.ui.control.setValue(services.ui, "cathLimit", -0.9);
            labkit.ui.control.setValue(services.ui, "anodLimit", 0.6);
    end
    state = analyzeAllFiles(state, services);
end

function state = onOpenFilesChosen(state, payload, services)
    paths = labkit.ui.control.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'Open cancelled.');
        return;
    end
    state = loadDTAFiles(state, paths, services);
end

function state = loadDTAFiles(state, filepaths, services)
    filepaths = normalizePaths(filepaths);
    if isempty(filepaths)
        return;
    end

    failed = struct('filepath', {}, 'message', {});
    lastAddedIndex = [];
    for iFile = 1:numel(filepaths)
        filepath = filepaths(iFile);
        if isLoaded(state, filepath)
            addLog(services, sprintf('Skipped already loaded: %s', char(filepath)));
            continue;
        end

        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            failed(end + 1) = struct( ...
                'filepath', char(filepath), ...
                'message', char(status.message));
            addLog(services, sprintf('Failed: %s | %s', ...
                char(filepath), char(status.message)));
            continue;
        end

        item.analysis = [];
        for ii = 1:numel(item.logmsg)
            addLog(services, item.logmsg{ii});
        end
        item = analyzeItem(item, services);
        state.items = appendItem(state.items, item);
        lastAddedIndex = numel(state.items);
        addLog(services, sprintf('Loaded: %s', char(filepath)));
    end
    if ~isempty(lastAddedIndex)
        state.current = lastAddedIndex;
    elseif ~isempty(state.items) && isempty(state.current)
        state.current = 1;
    end
    restoreDefaultPlotSelections(services.ui);

    if ~isempty(failed)
        firstError = failed(1);
        labkit.ui.runtime.showAlert(services.figure, ...
            sprintf('Failed to load:\n%s\n\n%s', ...
            firstError.filepath, firstError.message), ...
            'Load error');
    end
end

function state = onAnalyzeAllFiles(state, ~, services)
    state = analyzeAllFiles(state, services);
end

function state = analyzeAllFiles(state, services)
    if isempty(state.items)
        return;
    end
    opts = analysisOptions(services.ui);
    state.items = cic.analysisRun.recomputeItems(state.items, opts);
    addLog(services, sprintf('Reanalyzed %d loaded file(s) with shared analysis settings.', ...
        numel(state.items)));
end

function item = analyzeItem(item, services)
    opts = analysisOptions(services.ui);
    analysis = cic.analysisRun.computeCIC(item, opts);
    item.analysis = analysis;
    if analysis.ok
        addLog(services, sprintf('%s: Emc=%.6f V, Ema=%.6f V, safe=%d', ...
            item.name, analysis.Emc, analysis.Ema, analysis.safe));
    elseif isfield(analysis, 'logOnFailure') && analysis.logOnFailure
        addLog(services, sprintf('%s: %s', item.name, analysis.message));
    end
end

function opts = analysisOptions(ui)
    opts = struct();
    opts.delay_s = finiteScalar(ui.controls.delayUs.valueHandle.Value, 10) * 1e-6;
    opts.cathLimit = finiteScalar(ui.controls.cathLimit.valueHandle.Value, -0.6);
    opts.anodLimit = finiteScalar(ui.controls.anodLimit.valueHandle.Value, 0.8);
    opts.areaOverride = ui.controls.area.valueHandle.Value;
    opts.pulseMode = ui.controls.pulseMode.valueHandle.Value;
    opts.usedMeasuredCurrent = ui.controls.useMeasuredCurrent.valueHandle.Value;
end

function value = finiteScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function state = onFileSelectionChanged(state, ~, services)
    files = labkit.ui.control.getValue(services.ui, 'files');
    paths = labkit.ui.control.filePaths(files);
    if isempty(paths) || isempty(state.items)
        state.current = [];
        restoreDefaultPlotSelections(services.ui);
        return;
    end

    idx = find(string({state.items.filepath}) == string(paths(1)), 1);
    if isempty(idx)
        state.current = [];
    else
        state.current = idx;
    end
    restoreDefaultPlotSelections(services.ui);
end

function state = onRemoveSelected(state, payload, services)
    if isempty(state.items)
        return;
    end
    paths = labkit.ui.control.filePaths(payload.event.removedFiles);
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
    end
    restoreDefaultPlotSelections(services.ui);
end

function state = onClearAll(state, ~, services)
    state.items = struct([]);
    state.current = [];
    restoreDefaultPlotSelections(services.ui);
    addLog(services, 'Cleared all files.');
end

function state = onExportResults(state, ~, services)
    if isempty(state.items)
        labkit.ui.runtime.showAlert(services.figure, ...
            'No results to export.', 'Export');
        return;
    end
    state = analyzeAllFiles(state, services);
    [out, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        'cic_results.csv', 'Save results CSV', 'cic_results.csv');
    if cancelled
        return;
    end
    [~, unitLabel] = cic.userInterface.displayUnit( ...
        services.ui.controls.cicUnit.valueHandle.Value);
    [ok, msg] = cic.resultFiles.writeResultsCSV(state.items, out, unitLabel);
    if ~ok
        labkit.ui.runtime.showAlert(services.figure, msg, 'Export');
        return;
    end
    addLog(services, ['Exported CSV: ' char(out)]);
end

function state = onRefreshOnly(state, ~, ~)
end

function restoreDefaultPlotSelections(ui)
    ui.controls.topX.valueHandle.Value = 'Time (s)';
    ui.controls.topY.valueHandle.Value = 'VT: Vf vs time';
    ui.controls.topGrid.valueHandle.Value = true;
    ui.controls.bottomX.valueHandle.Value = 'Time (s)';
    ui.controls.bottomY.valueHandle.Value = 'IT: Im vs time';
    ui.controls.bottomGrid.valueHandle.Value = true;
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

function addLog(services, msg)
    labkit.ui.control.appendLog(services.ui, 'appLog', msg);
    if isDebugEnabled(services.debug)
        services.debug.append(msg);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
