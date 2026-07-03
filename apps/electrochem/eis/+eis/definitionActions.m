% App-owned action table for EIS Overlay. Expected caller is eis.definition.
% Output maps semantic action ids to handlers used by labkit.ui.app.run.
% Handlers own app workflow transitions and IO/export side effects.
function actions = definitionActions()
    actions = struct( ...
        "startup", @onStartup, ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportCSV", @onExportCSV, ...
        "selectionChanged", @onRefreshOnly, ...
        "plotOptionsChanged", @onRefreshOnly);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if ~isDebugEnabled(debugLog)
        return;
    end
    debugLog.trace('EIS debug trace enabled.');
    try
        pack = eis.debug.writeSamplePack(debugLog);
        addLog(services, sprintf('Debug sample files: %s', char(pack.sampleFolder)));
        addLog(services, sprintf('Debug output folder: %s', char(pack.outputFolder)));
    catch ME
        debugLog.reportException('eis', 'Debug sample setup failed', ME);
        addLog(services, sprintf('Debug sample setup failed: %s', ME.message));
    end
end

function state = onOpenFilesChosen(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'Open cancelled.');
        return;
    end
    state = loadFiles(state, paths, services);
end

function state = loadFiles(state, filepaths, services)
    filepaths = normalizePaths(filepaths);
    if isempty(filepaths)
        return;
    end

    failed = struct('filepath', {}, 'message', {});
    for iFile = 1:numel(filepaths)
        filepath = filepaths(iFile);
        if isLoaded(state, filepath)
            addLog(services, sprintf('Skipped already loaded: %s', char(filepath)));
            continue;
        end

        [item, status] = labkit.dta.loadFile(filepath, "eis");
        if ~status.ok
            failed(end + 1) = struct( ...
                'filepath', char(filepath), ...
                'message', char(status.message));
            addLog(services, sprintf('Failed: %s | %s', ...
                char(filepath), char(status.message)));
            continue;
        end

        state.items = appendItem(state.items, item);
        addLoadedLog(services, char(filepath), item);
    end

    if ~isempty(failed)
        firstError = failed(1);
        labkit.ui.app.showAlert(services.figure, ...
            sprintf('Failed to load:\n%s\n\n%s', ...
            firstError.filepath, firstError.message), ...
            'Load error');
    end
end

function addLoadedLog(services, filepath, item)
    for ii = 1:numel(item.logmsg)
        addLog(services, item.logmsg{ii});
    end
    addLog(services, sprintf('%s: %s', item.name, item.message));
    addLog(services, sprintf('Loaded: %s', filepath));
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
end

function state = onClearAll(state, ~, services)
    state.items = struct([]);
    addLog(services, 'Cleared all files.');
end

function state = onExportCSV(state, ~, services)
    items = selectedItems(state, services.ui);
    if isempty(items)
        labkit.ui.app.showAlert(services.figure, ...
            'No files selected for export.', 'Export');
        return;
    end

    [out, cancelled] = labkit.ui.app.promptOutputFile( ...
        'gamry_eis_plot_export.csv', 'Save current X/Y plot CSV', ...
        'gamry_eis_plot_export.csv');
    if cancelled
        return;
    end

    opts = plotOptions(services.ui);
    T = eis.resultFiles.buildExportTable(items, opts.xName, opts.yName, ...
        opts.logX, opts.logY);
    writetable(T, out);
    addLog(services, sprintf('Exported CSV: %s', char(out)));
end

function state = onRefreshOnly(state, ~, ~)
end

function items = selectedItems(state, ui)
    files = labkit.ui.view.getValue(ui, 'files');
    paths = labkit.ui.view.filePaths(files);
    if isempty(paths)
        items = struct([]);
        return;
    end
    keep = ismember(string({state.items.filepath}), string(paths(:)));
    items = state.items(keep);
end

function opts = plotOptions(ui)
    opts = struct();
    opts.xName = ui.controls.xAxis.valueHandle.Value;
    opts.yName = ui.controls.yAxis.valueHandle.Value;
    opts.logX = ui.controls.logX.valueHandle.Value;
    opts.logY = ui.controls.logY.valueHandle.Value;
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
    labkit.ui.view.appendLog(services.ui, 'appLog', msg);
    if isDebugEnabled(services.debug)
        services.debug.append(msg);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
