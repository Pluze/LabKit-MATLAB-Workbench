% App-owned Runtime V2 action table for EIS Overlay. Handlers own source
% loading/removal, semantic selection, and plot-data export side effects.
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
        paths = services.events.paths(event, "files");
    end
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
        [item, status] = labkit.dta.loadFile(filepath, "eis");
        if ~status.ok
            if ~hasFailure
                firstFailure = struct( ...
                    "filepath", filepath, ...
                    "message", string(status.message));
                hasFailure = true;
            end
            state = services.workflow.log(state, ...
                "Failed: " + filepath + " | " + string(status.message));
            continue;
        end
        state.session.cache.items = appendItem( ...
            state.session.cache.items, item);
        state = logLoadedItem(state, item, services);
    end
    state = reconcileProjectSources(state, services);
    state.session.selection.paths = ...
        string({state.session.cache.items.filepath}).';
    state.project.results.lastExport = [];
    if hasFailure
        services.dialogs.alert(sprintf('Failed to load:\n%s\n\n%s', ...
            firstFailure.filepath, firstFailure.message), 'Load error');
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
        state.session.selection.paths, removed, 'stable');
    state.project.results.lastExport = [];
    for k = 1:numel(removed)
        state = services.workflow.log(state, "Removed: " + removed(k));
    end
end

function state = onClearAll(state, ~, services)
    state.project.results.lastExport = [];
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
    items = selectedItems(state);
    if isempty(items)
        services.dialogs.alert('No files selected for export.', 'Export');
        return;
    end
    [out, cancelled] = services.dialogs.outputFile( ...
        'gamry_eis_plot_export.csv', 'Save current X/Y plot CSV', ...
        'gamry_eis_plot_export.csv');
    if cancelled
        state = services.workflow.log(state, "Plot export cancelled.");
        return;
    end
    p = state.project.parameters;
    tableValue = eis.resultFiles.buildExportTable( ...
        items, p.xName, p.yName, p.logX, p.logY);
    writetable(tableValue, out);
    [folder, name, extension] = fileparts(out);
    output = services.results.output("eisPlotData", "primary", ...
        string(name) + string(extension), "text/csv");
    spec = struct( ...
        "Outputs", output, ...
        "Inputs", selectedSources(state), ...
        "Parameters", p, ...
        "Summary", struct("fileCount", numel(items)), ...
        "ManifestName", "gamry_eis_plot_export.labkit.json");
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
    keep = ismember(string({items.filepath}), ...
        state.session.selection.paths(:));
    items = items(keep);
end

function sources = selectedSources(state)
    sources = state.project.inputs.sources;
    if isempty(sources)
        return;
    end
    paths = labkit.ui.runtime.sourcePaths(sources);
    sources = sources(ismember(paths, state.session.selection.paths(:)));
end

function state = logLoadedItem(state, item, services)
    for k = 1:numel(item.logmsg)
        state = services.workflow.log(state, item.logmsg{k});
    end
    state = services.workflow.log(state, ...
        string(item.name) + ": " + string(item.message));
    state = services.workflow.log(state, ...
        "Loaded: " + string(item.filepath));
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
        state.project.inputs.sources, paths, "eis", "dta", true);
end
