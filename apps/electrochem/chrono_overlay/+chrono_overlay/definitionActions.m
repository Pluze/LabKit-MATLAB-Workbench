% App-owned V2 action table for Chrono Overlay. Handlers receive canonical
% state/events/services and never read or mutate UI controls directly.
function actions = definitionActions()
    actions = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportCSV", @onExportCSV, ...
        "selectionChanged", @onSelectionChanged);
end

function state = onOpenFilesChosen(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        state = addLog(state, services, "Open cancelled.");
        return;
    end
    failed = struct('filepath', {}, 'message', {});
    for k = 1:numel(paths)
        filepath = paths(k);
        if isLoaded(state.project.inputs.items, filepath)
            state = addLog(state, services, ...
                "Skipped already loaded: " + filepath);
            continue;
        end
        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            failed(end + 1) = struct( ...
                'filepath', char(filepath), 'message', char(status.message));
            state = addLog(state, services, ...
                "Failed: " + filepath + " | " + status.message);
            continue;
        end
        [item, alignMessage] = chrono_overlay.sourceFiles.alignByPulseGap(item);
        state.project.inputs.items = appendItem( ...
            state.project.inputs.items, item);
        state.project.inputs.sources = appendSource( ...
            state.project.inputs.sources, filepath, services);
        state.session.selection.paths(end + 1, 1) = filepath;
        state = addLog(state, services, alignMessage);
        for iMessage = 1:numel(item.logmsg)
            state = addLog(state, services, item.logmsg{iMessage});
        end
        state = addLog(state, services, string(item.name) + ": " + item.message);
        state = addLog(state, services, "Loaded: " + filepath);
    end
    if ~isempty(failed)
        firstError = failed(1);
        services.dialogs.alert(sprintf( ...
            'Failed to load:\n%s\n\n%s', firstError.filepath, ...
            firstError.message), 'Load error');
    end
end

function state = onRemoveSelected(state, event, services)
    paths = services.events.paths(event, "removedFiles");
    if isempty(paths)
        return;
    end
    [state.project.inputs.items, removed] = removeItems( ...
        state.project.inputs.items, paths);
    state.project.inputs.sources = removeSources( ...
        state.project.inputs.sources, paths);
    state.session.selection.paths = setdiff( ...
        state.session.selection.paths, paths, 'stable');
    for k = 1:numel(removed)
        state = addLog(state, services, "Removed: " + removed(k));
    end
end

function state = onClearAll(state, ~, services)
    state.project.inputs.items = struct([]);
    state.project.inputs.sources = emptySources();
    state.session.selection.paths = strings(0, 1);
    state = addLog(state, services, "Cleared all files.");
end

function state = onSelectionChanged(state, event, services)
    state.session.selection.paths = ...
        services.events.paths(event, "selectedFiles");
end

function state = onExportCSV(state, ~, services)
    if isempty(state.project.inputs.items)
        services.dialogs.alert( ...
            'No files loaded.', 'Export');
        return;
    end
    items = selectedItems(state);
    if isempty(items)
        services.dialogs.alert( ...
            'No files selected for export.', 'Export');
        return;
    end
    [out, cancelled] = services.dialogs.outputFile( ...
        'gamry_overlay_curves.csv', 'Save overlay curves CSV', ...
        'gamry_overlay_curves.csv');
    if cancelled
        return;
    end
    tableValue = chrono_overlay.resultFiles.buildOverlayExportTable(items);
    writetable(tableValue, out);
    [folder, base, extension] = fileparts(out);
    outputName = string(base) + string(extension);
    outputs = services.results.output( ...
        "overlayCurves", "primary", outputName, "text/csv");
    spec = struct();
    spec.Outputs = outputs;
    spec.Inputs = state.project.inputs.sources;
    spec.Parameters = state.project.parameters;
    spec.Summary = struct("fileCount", numel(items));
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.lastExport = struct( ...
        "csvPath", string(out), "manifestPath", string(manifestPath));
    state = addLog(state, services, "Exported CSV: " + string(out));
end

function items = selectedItems(state)
    items = state.project.inputs.items;
    if isempty(items)
        return;
    end
    selected = state.session.selection.paths;
    keep = ismember(string({items.filepath}), selected(:));
    items = items(keep);
end

function tf = isLoaded(items, filepath)
    tf = ~isempty(items) && ...
        any(string({items.filepath}) == string(filepath));
end

function items = appendItem(items, item)
    if isempty(items)
        items = item;
    else
        items(end + 1) = item;
    end
end

function sources = appendSource(sources, filepath, services)
    source = services.project.sourceRecord( ...
        "dta" + string(numel(sources) + 1), "chrono", filepath, true);
    if isempty(sources)
        sources = source;
    else
        sources(end + 1) = source;
    end
end

function [items, removed] = removeItems(items, paths)
    removed = strings(0, 1);
    if isempty(items)
        return;
    end
    itemPaths = string({items.filepath});
    keep = ~ismember(itemPaths, paths(:));
    removed = itemPaths(~keep).';
    items = items(keep);
end

function sources = removeSources(sources, paths)
    if isempty(sources)
        return;
    end
    sourcePaths = strings(numel(sources), 1);
    for k = 1:numel(sources)
        sourcePaths(k) = string(sources(k).reference.originalPath);
    end
    sources = sources(~ismember(sourcePaths, paths(:)));
end

function sources = emptySources()
    sources = struct("id", {}, "required", {}, "role", {}, ...
        "reference", {});
end

function state = addLog(state, services, message)
    message = string(message);
    state.session.workflow.logLines(end + 1, 1) = message;
    if isstruct(services.debug) && isfield(services.debug, 'enabled') && ...
            logical(services.debug.enabled)
        services.debug.append(char(message));
    end
end
