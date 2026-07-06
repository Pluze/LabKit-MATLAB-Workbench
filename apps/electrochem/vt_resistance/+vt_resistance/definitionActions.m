% App-owned action table for VT Resistance. Expected caller is
% vt_resistance.definition. Output maps semantic action ids to handlers used
% by labkit.ui.runtime.run. Handlers own workflow transitions, DTA loading,
% analysis, and export side effects.
function actions = definitionActions()
    actions = struct( ...
        "startup", @onStartup, ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportResults", @onExportResults, ...
        "fileSelectionChanged", @onFileSelectionChanged, ...
        "analysisChanged", @onAnalyzeCurrentFile, ...
        "refreshPlots", @onRefreshOnly);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if ~isDebugEnabled(debugLog)
        return;
    end
    debugLog.trace('VT resistance debug trace enabled.');
    try
        pack = vt_resistance.debug.writeSamplePack(debugLog);
        addLog(services, sprintf('Debug sample files: %s', char(pack.sampleFolder)));
        addLog(services, sprintf('Debug output folder: %s', char(pack.outputFolder)));
    catch ME
        debugLog.reportException('vtResistance', ...
            'Debug sample setup failed', ME);
        addLog(services, sprintf('Debug sample setup failed: %s', ME.message));
    end
end

function state = onOpenFilesChosen(state, payload, services)
    paths = labkit.ui.control.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'Open cancelled.');
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
    lastAddedIndex = [];
    for iFile = 1:numel(filepaths)
        filepath = filepaths(iFile);
        if isLoaded(state, filepath)
            addLog(services, ['Skipped duplicate: ' char(filepath)]);
            continue;
        end

        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            failed(end + 1) = struct( ...
                'filepath', char(filepath), ...
                'message', char(status.message));
            addLog(services, sprintf('Failed to load %s: %s', ...
                char(filepath), char(status.message)));
            continue;
        end

        for ii = 1:numel(item.logmsg)
            addLog(services, item.logmsg{ii});
        end
        item = analyzeItem(item, services);
        state.items = appendItem(state.items, item);
        lastAddedIndex = numel(state.items);
        addLog(services, ['Loaded: ' char(filepath)]);
    end
    if ~isempty(lastAddedIndex)
        state.current = lastAddedIndex;
    elseif ~isempty(state.items) && isempty(state.current)
        state.current = 1;
    end

    if ~isempty(failed)
        firstError = failed(1);
        labkit.ui.runtime.showAlert(services.figure, ...
            sprintf('Failed to load:\n%s\n\n%s', ...
            firstError.filepath, firstError.message), ...
            'Load error');
    end
end

function state = onAnalyzeCurrentFile(state, ~, services)
    if isempty(state.items) || isempty(state.current) || ...
            state.current < 1 || state.current > numel(state.items)
        return;
    end
    state.items(state.current) = analyzeItem(state.items(state.current), services);
end

function item = analyzeItem(item, services)
    ui = services.ui;
    opts = struct();
    opts.windowMode = ui.controls.steadyWindow.valueHandle.Value;
    opts.voltageMode = ui.controls.voltageMode.valueHandle.Value;
    opts.pulseMode = ui.controls.pulseMode.valueHandle.Value;

    analysis = vt_resistance.analysisRun.computeResistance(item, opts);
    if analysis.ok
        addLog(services, sprintf('%s: Rc=%.6g ohm, Ra=%.6g ohm, Ravg=%.6g ohm', ...
            item.name, analysis.Rc_abs_ohm, analysis.Ra_abs_ohm, ...
            analysis.Ravg_abs_ohm));
    elseif isfield(analysis, 'logOnFailure') && analysis.logOnFailure
        addLog(services, sprintf('%s: %s', item.name, analysis.message));
    end
    item.analysis = analysis;
end

function state = onFileSelectionChanged(state, ~, services)
    files = labkit.ui.control.getValue(services.ui, 'files');
    paths = labkit.ui.control.filePaths(files);
    if isempty(paths) || isempty(state.items)
        state.current = [];
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
    [out, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        'vt_steady_resistance_results.csv', 'Save results CSV', ...
        'vt_steady_resistance_results.csv');
    if cancelled
        return;
    end
    [ok, msg] = vt_resistance.resultFiles.writeResultsCSV(state.items, out);
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
