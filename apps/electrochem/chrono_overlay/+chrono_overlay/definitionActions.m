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
        state = services.workflow.log(state, "Open cancelled.");
        return;
    end
    firstFailure = struct("filepath", "", "message", "");
    hasFailure = false;
    for k = 1:numel(paths)
        filepath = paths(k);
        if isLoaded(state.session.cache.items, filepath)
            state = services.workflow.log(state, ...
                "Skipped already loaded: " + filepath);
            continue;
        end
        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            if ~hasFailure
                firstFailure = struct( ...
                    "filepath", filepath, ...
                    "message", string(status.message));
                hasFailure = true;
            end
            state = services.workflow.log(state, ...
                "Failed: " + filepath + " | " + status.message);
            continue;
        end
        [item, alignMessage] = chrono_overlay.sourceFiles.alignByPulseGap(item);
        state.session.cache.items = appendItem( ...
            state.session.cache.items, item);
        state.session.selection.paths(end + 1, 1) = filepath;
        state = services.workflow.log(state, alignMessage);
        for iMessage = 1:numel(item.logmsg)
            state = services.workflow.log(state, item.logmsg{iMessage});
        end
        state = services.workflow.log(state, string(item.name) + ": " + item.message);
        state = services.workflow.log(state, "Loaded: " + filepath);
    end
    state = reconcileProjectSources(state, services);
    if hasFailure
        services.dialogs.alert(sprintf( ...
            'Failed to load:\n%s\n\n%s', firstFailure.filepath, ...
            firstFailure.message), 'Load error');
    end
end

function state = onRemoveSelected(state, event, services)
    paths = services.events.paths(event, "removedFiles");
    if isempty(paths)
        return;
    end
    [state.session.cache.items, removed] = removeItems( ...
        state.session.cache.items, paths);
    state = reconcileProjectSources(state, services);
    state.session.selection.paths = setdiff( ...
        state.session.selection.paths, paths, 'stable');
    for k = 1:numel(removed)
        state = services.workflow.log(state, "Removed: " + removed(k));
    end
end

function state = onClearAll(state, ~, services)
    state.session.cache.items = struct([]);
    state = reconcileProjectSources(state, services);
    state.session.selection.paths = strings(0, 1);
    state = services.workflow.log(state, "Cleared all files.");
end

function state = onSelectionChanged(state, event, services)
    state.session.selection.paths = ...
        services.events.paths(event, "selectedFiles");
end

function state = onExportCSV(state, ~, services)
    if isempty(state.session.cache.items)
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
    state = services.workflow.log(state, "Exported CSV: " + string(out));
end

function items = selectedItems(state)
    items = state.session.cache.items;
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

function state = reconcileProjectSources(state, services)
    paths = strings(0, 1);
    if ~isempty(state.session.cache.items)
        paths = string({state.session.cache.items.filepath}).';
    end
    state.project.inputs.sources = services.project.reconcileSources( ...
        state.project.inputs.sources, paths, "chrono", "dta", true);
end
