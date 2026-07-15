% App-owned Runtime V2 action table for CIC. Handlers receive canonical
% state/events/services and own DTA selection, CIC analysis, and result export
% without reading or mutating UI controls.
function actions = definitionActions()
    actions = struct( ...
        "openFilesChosen", @onOpenFilesChosen, ...
        "removeSelected", @onRemoveSelected, ...
        "clearAll", @onClearAll, ...
        "exportResults", @onExportResults, ...
        "fileSelectionChanged", @onFileSelectionChanged, ...
        "presetChanged", @onPresetChanged, ...
        "analysisChanged", @onAnalysisChanged);
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

    failures = struct("filepath", {}, "message", {});
    for k = 1:numel(paths)
        filepath = paths(k);
        if isLoaded(state.session.cache.items, filepath)
            state = services.workflow.log(state, ...
                "Skipped already loaded: " + filepath);
            continue;
        end
        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            failures(end + 1) = struct( ...
                "filepath", filepath, "message", string(status.message));
            state = services.workflow.log(state, ...
                "Failed: " + filepath + " | " + string(status.message));
            continue;
        end
        item.analysis = cic.analysisRun.computeCIC( ...
            item, cic.analysisRun.optionsFromParameters( ...
            state.project.parameters));
        state.session.cache.items = appendItem( ...
            state.session.cache.items, item);
        source = services.project.sourceRecord( ...
            nextSourceId(state.project.inputs.sources), ...
            "chrono", filepath, true);
        state.project.inputs.sources = appendSource( ...
            state.project.inputs.sources, source);
        state.session.selection.currentIndex = ...
            numel(state.session.cache.items);
        for messageIndex = 1:numel(item.logmsg)
            state = services.workflow.log(state, item.logmsg{messageIndex});
        end
        state = logAnalysis(state, item);
        state = services.workflow.log(state, "Loaded: " + filepath);
    end
    state.project.parameters = resetPlotSelections(state.project.parameters);
    state.project.results.lastExport = [];
    if ~isempty(failures)
        first = failures(1);
        services.dialogs.alert(sprintf('Failed to load:\n%s\n\n%s', ...
            first.filepath, first.message), 'Load error');
    end
end

function state = onRemoveSelected(state, event, services)
    items = state.session.cache.items;
    indices = services.events.indices(event, "removedFiles", numel(items));
    if isempty(indices)
        return;
    end
    removedSourceFiles = string({items(indices).filepath});
    state.session.cache.items(indices) = [];
    state.project.inputs.sources(indices) = [];
    state.session.selection.currentIndex = boundedCurrentIndex( ...
        state.session.selection.currentIndex, numel(state.session.cache.items));
    state.project.parameters = resetPlotSelections(state.project.parameters);
    state.project.results.lastExport = [];
    for k = 1:numel(removedSourceFiles)
        state = services.workflow.log(state, "Removed: " + removedSourceFiles(k));
    end
end

function state = onClearAll(state, ~, services)
    state.project.inputs.sources = state.project.inputs.sources([]);
    state.project.results.lastExport = [];
    state.session.cache.items = struct([]);
    state.session.selection.currentIndex = 0;
    state.project.parameters = resetPlotSelections(state.project.parameters);
    state = services.workflow.log(state, "Cleared all files.");
end

function state = onFileSelectionChanged(state, event, services)
    indices = services.events.indices(event, "selectedFiles", ...
        numel(state.session.cache.items));
    if isempty(indices)
        state.session.selection.currentIndex = 0;
    else
        state.session.selection.currentIndex = indices(1);
    end
    state.project.parameters = resetPlotSelections(state.project.parameters);
end

function state = onPresetChanged(state, ~, services)
    choices = cic.userInterface.analysisChoices();
    preset = string(state.project.parameters.preset);
    if preset == choices.presets(1)
        state.project.parameters.cathLimit = -0.6;
        state.project.parameters.anodLimit = 0.8;
    elseif preset == choices.presets(2)
        state.project.parameters.cathLimit = -0.9;
        state.project.parameters.anodLimit = 0.6;
    end
    state = analyzeAllFiles(state, services);
end

function state = onAnalysisChanged(state, ~, services)
    state = analyzeAllFiles(state, services);
end

function state = analyzeAllFiles(state, services)
    if isempty(state.session.cache.items)
        state.project.results.lastExport = [];
        return;
    end
    opts = cic.analysisRun.optionsFromParameters(state.project.parameters);
    state.session.cache.items = cic.analysisRun.recomputeItems( ...
        state.session.cache.items, opts);
    state.project.results.lastExport = [];
    state = services.workflow.log(state, sprintf( ...
        'Reanalyzed %d loaded file(s) with shared analysis settings.', ...
        numel(state.session.cache.items)));
end

function state = onExportResults(state, ~, services)
    if isempty(state.session.cache.items)
        services.dialogs.alert('No results to export.', 'Export');
        return;
    end
    state = analyzeAllFiles(state, services);
    [out, cancelled] = services.dialogs.outputFile( ...
        'cic_results.csv', 'Save results CSV', 'cic_results.csv');
    if cancelled
        state = services.workflow.log(state, "Result export cancelled.");
        return;
    end
    [~, unitLabel] = cic.userInterface.displayUnit( ...
        state.project.parameters.cicUnit);
    [ok, message] = cic.resultFiles.writeResultsCSV( ...
        state.session.cache.items, out, unitLabel);
    if ~ok
        services.dialogs.alert(message, 'Export');
        return;
    end
    [folder, name, extension] = fileparts(out);
    output = services.results.output("cicResults", "primary", ...
        string(name) + string(extension), "text/csv");
    spec = struct( ...
        "Outputs", output, ...
        "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, ...
        "Summary", struct("fileCount", numel(state.session.cache.items)), ...
        "ManifestName", "cic_results.labkit.json");
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.lastExport = struct( ...
        "csvPath", string(out), "manifestPath", string(manifestPath));
    state = services.workflow.log(state, "Exported CSV: " + string(out));
end

function state = logAnalysis(state, item)
    analysis = item.analysis;
    if analysis.ok
        state.session.workflow.logLines(end + 1, 1) = string(sprintf( ...
            '%s: Emc=%.6f V, Ema=%.6f V, safe=%d', ...
            item.name, analysis.Emc, analysis.Ema, analysis.safe));
    elseif isfield(analysis, 'logOnFailure') && analysis.logOnFailure
        state.session.workflow.logLines(end + 1, 1) = ...
            string(item.name) + ": " + string(analysis.message);
    end
end

function parameters = resetPlotSelections(parameters)
    choices = cic.userInterface.analysisChoices();
    parameters.topX = choices.xAxes(1);
    parameters.topY = choices.yAxes(1);
    parameters.topGrid = true;
    parameters.bottomX = choices.xAxes(1);
    parameters.bottomY = choices.yAxes(2);
    parameters.bottomGrid = true;
end

function index = boundedCurrentIndex(index, count)
    if count == 0
        index = 0;
    else
        index = min(max(1, round(double(index))), count);
    end
end

function tf = isLoaded(items, filepath)
    tf = ~isempty(items) && ...
        any(string({items.filepath}) == string(filepath));
end

function id = nextSourceId(sources)
    ids = string({sources.id});
    number = numel(ids) + 1;
    id = "dta" + string(number);
    while any(ids == id)
        number = number + 1;
        id = "dta" + string(number);
    end
end

function items = appendItem(items, item)
    if isempty(items)
        items = item;
    else
        items(end + 1) = item;
    end
end

function sources = appendSource(sources, source)
    if isempty(sources)
        sources = source;
    else
        sources(end + 1) = source;
    end
end
