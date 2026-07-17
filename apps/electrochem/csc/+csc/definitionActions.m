% App-owned Runtime V2 action table for CSC. Handlers receive canonical
% state/events/services and own DTA sources, selection, reload, and exports.
function actions = definitionActions()
    actions = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "reloadSelected", @onReloadSelected, ...
        "exportResults", @onExportResults, ...
        "exportVoltageCurrent", @onExportVoltageCurrent, ...
        "fileSelectionChanged", @onFileSelectionChanged);
end

function state = onOpenFilesChosen(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    if isempty(paths)
        state = services.workflow.log(state, "Open file canceled.");
        return;
    end

    firstFailure = struct("filepath", "", "message", "");
    hasFailure = false;
    for k = 1:numel(paths)
        filepath = paths(k);
        if isLoaded(state.session.cache.items, filepath)
            state = services.workflow.log(state, ...
                "Skipped duplicate: " + filepath);
            continue;
        end
        [item, status] = labkit.dta.loadFile(filepath, "cvct");
        if ~status.ok
            if ~hasFailure
                firstFailure = struct( ...
                    "filepath", filepath, ...
                    "message", string(status.message));
                hasFailure = true;
            end
            state = services.workflow.log(state, ...
                "Failed to load " + filepath + ": " + string(status.message));
            continue;
        end
        state.session.cache.items = appendItem( ...
            state.session.cache.items, item);
        state.session.selection.currentIndex = ...
            numel(state.session.cache.items);
        state = logLoadedItem(state, item, services);
    end
    state = reconcileProjectSources(state, services);
    state = resetCurrentView(state);
    state = clearExportReferences(state);
    if hasFailure
        services.dialogs.alert(sprintf('Failed to load:\n%s\n\n%s', ...
            firstFailure.filepath, firstFailure.message), 'Load error');
    end
end

function state = onRemoveSelected(state, event, services)
    items = state.session.cache.items;
    indices = services.events.indices(event, "removedFiles", numel(items));
    if isempty(indices)
        return;
    end
    removed = string({items(indices).filepath});
    state.session.cache.items(indices) = [];
    state = reconcileProjectSources(state, services);
    state.session.selection.currentIndex = boundedIndex( ...
        state.session.selection.currentIndex, numel(state.session.cache.items));
    state = resetCurrentView(state);
    state = clearExportReferences(state);
    for k = 1:numel(removed)
        state = services.workflow.log(state, "Removed: " + removed(k));
    end
end

function state = onClearAll(state, ~, services)
    state.session.cache.items = struct([]);
    state = reconcileProjectSources(state, services);
    state.session.selection.currentIndex = 0;
    state = resetCurrentView(state);
    state = clearExportReferences(state);
    state = services.workflow.log(state, "Cleared all files.");
end

function state = onReloadSelected(state, ~, services)
    index = boundedIndex(state.session.selection.currentIndex, ...
        numel(state.session.cache.items));
    if index == 0
        services.dialogs.alert('No file selected.', 'Reload');
        state = services.workflow.log(state, ...
            "Reload failed: no file selected.");
        return;
    end
    filepath = string(state.session.cache.items(index).filepath);
    [item, status] = labkit.dta.loadFile(filepath, "cvct");
    if ~status.ok
        services.dialogs.alert(status.message, 'Reload');
        state = services.workflow.log(state, ...
            "Reload failed: " + filepath + " | " + string(status.message));
        return;
    end
    state.session.cache.items(index) = item;
    state = resetCurrentView(state);
    state = clearExportReferences(state);
    state = services.workflow.log(state, "Reloaded: " + filepath);
end

function state = onFileSelectionChanged(state, event, services)
    indices = services.events.indices(event, "selectedFiles", ...
        numel(state.session.cache.items));
    if isempty(indices)
        state.session.selection.currentIndex = 0;
    else
        state.session.selection.currentIndex = indices(1);
    end
    state = resetCurrentView(state);
end

function state = onExportResults(state, ~, services)
    items = state.session.cache.items;
    if isempty(items)
        services.dialogs.alert('No results to export.', 'Export');
        return;
    end
    [out, cancelled] = services.dialogs.outputFile( ...
        'csc_all_cycles.csv', 'Save all-cycle CSC CSV', ...
        'csc_all_cycles.csv');
    if cancelled
        state = services.workflow.log(state, "Result export cancelled.");
        return;
    end
    parameters = state.project.parameters;
    opts = struct( ...
        "mode", char(parameters.mode), ...
        "area_cm2", parameters.area, ...
        "ignoreEdgeCycles", logical(parameters.ignoreEdgeCycles));
    [ok, message] = csc.resultFiles.writeResultsCSV(items, out, opts);
    if ~ok
        services.dialogs.alert(message, 'Export');
        return;
    end
    [folder, name, extension] = fileparts(out);
    output = services.results.output("cscResults", "primary", ...
        string(name) + string(extension), "text/csv");
    spec = resultSpec(state, output, "csc_all_cycles.labkit.json");
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.lastResultsExport = struct( ...
        "csvPath", string(out), "manifestPath", string(manifestPath));
    state = services.workflow.log(state, ...
        "Exported CSC CSV: " + string(out));
end

function state = onExportVoltageCurrent(state, ~, services)
    items = state.session.cache.items;
    if isempty(items)
        services.dialogs.alert( ...
            'No voltage/current data to export.', 'Export');
        return;
    end
    [out, cancelled] = services.dialogs.outputFile( ...
        'csc_cv_data.csv', 'Export CV data CSV', 'csc_cv_data.csv');
    if cancelled
        state = services.workflow.log(state, ...
            "Voltage/current export cancelled.");
        return;
    end
    opts = struct("ignoreEdgeCycles", ...
        logical(state.project.parameters.ignoreEdgeCycles));
    [ok, message, info] = ...
        csc.resultFiles.writeVoltageCurrentCSV(items, out, opts);
    if ~ok
        services.dialogs.alert(message, 'Export');
        return;
    end
    outputs = outputRecords(info.files, services);
    folder = fileparts(char(info.files(1)));
    spec = resultSpec(state, outputs, "csc_cv_data.labkit.json");
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.lastVoltageCurrentExport = struct( ...
        "csvPaths", string(info.files), ...
        "manifestPath", string(manifestPath));
    if isscalar(info.files)
        message = sprintf('Exported CV data CSV: %s (%d voltage rows)', ...
            info.files(1), info.rows);
    else
        message = sprintf( ...
            'Exported %d CV data CSV files in %s (%d voltage rows)', ...
            numel(info.files), folder, info.rows);
    end
    state = services.workflow.log(state, message);
end

function spec = resultSpec(state, outputs, manifestName)
    spec = struct( ...
        "Outputs", outputs, ...
        "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, ...
        "Summary", struct("fileCount", ...
            numel(state.session.cache.items)), ...
        "ManifestName", manifestName);
end

function outputs = outputRecords(files, services)
    records = cell(numel(files), 1);
    for k = 1:numel(files)
        [~, name, extension] = fileparts(files(k));
        records{k} = services.results.output( ...
            "cvData" + string(k), outputRole(k), ...
            string(name) + string(extension), "text/csv");
    end
    outputs = vertcat(records{:});
end

function role = outputRole(index)
    if index == 1
        role = "primary";
    else
        role = "additional";
    end
end

function state = resetCurrentView(state)
    choices = csc.userInterface.analysisChoices();
    index = boundedIndex(state.session.selection.currentIndex, ...
        numel(state.session.cache.items));
    state.session.selection.currentIndex = index;
    if index == 0
        state.session.selection.currentCurve = choices.empty;
        defaults = struct( ...
            "topX", choices.empty, "topY", choices.empty, ...
            "bottomX", choices.empty, "bottomY", choices.empty);
    else
        item = state.session.cache.items(index);
        state.session.selection.currentCurve = choices.allCycles;
        columns = numericColumns(item.curves, choices.empty);
        defaults = csc.userInterface.defaultPlotSelections(cellstr(columns));
    end
    fields = ["topX", "topY", "bottomX", "bottomY"];
    for field = fields
        value = string(defaults.(field));
        if strlength(value) == 0
            value = choices.empty;
        end
        state.project.parameters.(field) = value;
    end
end

function columns = numericColumns(curves, emptyChoice)
    if isempty(curves)
        columns = emptyChoice;
        return;
    end
    columns = string(curves(1).headers(curves(1).numericMask));
    if isempty(columns)
        columns = emptyChoice;
    end
end

function state = clearExportReferences(state)
    state.project.results.lastResultsExport = [];
    state.project.results.lastVoltageCurrentExport = [];
end

function state = logLoadedItem(state, item, services)
    for k = 1:numel(item.logmsg)
        state = services.workflow.log(state, item.logmsg{k});
    end
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

function state = reconcileProjectSources(state, services)
    paths = strings(0, 1);
    if ~isempty(state.session.cache.items)
        paths = string({state.session.cache.items.filepath}).';
    end
    state.project.inputs.sources = services.project.reconcileSources( ...
        state.project.inputs.sources, paths, "cvct", "dta", true);
end

function index = boundedIndex(index, count)
    if count == 0
        index = 0;
    else
        index = min(max(1, round(double(index))), count);
    end
end
