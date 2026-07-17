% App-owned Runtime V2 action table for Nerve Response Analysis. Handlers own
% source selection, analysis, preview selection, and export without UI reads,
% figure callbacks, closure state, or app-managed lifecycle plumbing.
function actions = definitionActions()
    actions = struct( ...
        "sessionChosen", @onSessionChosen, ...
        "protocolChosen", @onProtocolChosen, ...
        "outputFolderChosen", @onOutputFolderChosen, ...
        "outputFolderCleared", @onOutputFolderCleared, ...
        "settingChanged", @onSettingChanged, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "runAnalysis", @onRunAnalysis, ...
        "exportAnalysis", @onExportAnalysis, ...
        "resetWorkflow", @onResetWorkflow);
end

function state = onSessionChosen(state, event, services)
    filepath = firstEventPath(event, services);
    if strlength(filepath) == 0
        return;
    end
    try
        filterRecord = jsondecode(fileread(char(filepath)));
    catch ME
        services.diagnostics.report("Filter record load failed", ME);
        state.session.workflow.statusMessage = string(ME.message);
        state = services.workflow.log(state, ...
            "Filter record load failed: " + string(ME.message));
        return;
    end
    state.project.inputs.sources = services.project.upsertSource( ...
        state.project.inputs.sources, ...
        "filterRecord", "filterRecord", filepath, true);
    state.project.results.lastExport = [];
    state.session.cache.filterPath = filepath;
    state.session.cache.filterRecord = filterRecord;
    state.session.cache.analysis = [];
    state.session.workflow.outputFolder = string( ...
        services.dialogs.defaultOutputFolder( ...
        filepath, "nerve_response_analysis", ...
        state.session.workflow.outputFolder));
    state.session.workflow.statusMessage = "Filter record selected.";
    state.session.workflow.lastAction = "Selected filter record";
    state = services.workflow.log(state, ...
        "Selected filter record: " + displayPath(filepath));
end

function state = onProtocolChosen(state, event, services)
    filepath = firstEventPath(event, services);
    if strlength(filepath) == 0
        return;
    end
    protocol = loadOptionalProtocol(filepath);
    state.project.inputs.sources = services.project.upsertSource( ...
        state.project.inputs.sources, ...
        "protocol", "protocol", filepath, false);
    state.project.results.lastExport = [];
    state.session.cache.protocolPath = filepath;
    state.session.cache.protocol = protocol;
    if hasAnalysis(state)
        state.session.cache.analysis = [];
        state.session.workflow.statusMessage = ...
            "Protocol selected. Analyze session to refresh.";
    end
    state.session.workflow.lastAction = "Selected protocol";
    state = services.workflow.log(state, ...
        "Selected protocol: " + displayPath(filepath));
end

function state = onOutputFolderChosen(state, ~, services)
    [folder, cancelled] = services.dialogs.outputFolder( ...
        "Select analysis output folder", state.session.workflow.outputFolder);
    if cancelled
        state.session.workflow.lastAction = ...
            "Output folder selection cancelled";
        return;
    end
    state.session.workflow.outputFolder = string(folder);
    state.session.workflow.lastAction = "Selected output folder";
    state = services.workflow.log(state, ...
        "Selected output folder: " + displayPath(folder));
end

function state = onOutputFolderCleared(state, ~, ~)
    state.session.workflow.outputFolder = "";
    state.session.workflow.lastAction = "Cleared output folder";
end

function state = onSettingChanged(state, ~, ~)
    state.project.parameters.maxRecordings = finiteNonnegativeScalar( ...
        state.project.parameters.maxRecordings, 0);
    state.project.parameters.maxDurationSec = finiteNonnegativeScalar( ...
        state.project.parameters.maxDurationSec, 0);
    state.project.results.lastExport = [];
    if hasAnalysis(state)
        state.session.cache.analysis = [];
        state.session.workflow.statusMessage = ...
            "Analysis options changed. Analyze session to refresh.";
    end
    state.session.workflow.lastAction = "Updated analysis options";
end

function state = onPreviewModeChanged(state, event, ~)
    value = string(event.value);
    if isscalar(value) && any(value == ["Counts", "Issues"])
        state.session.view.previewMode = value;
    end
end

function state = onRunAnalysis(state, ~, services)
    if strlength(sourcePath(state, "filterRecord")) == 0
        state.session.workflow.statusMessage = "Select a filter record first.";
        return;
    end
    try
        opts = analysisOptions(state.project.parameters);
        state.session.cache.analysis = ...
            nerve_response_analysis.analysisRun.analyzeSession( ...
            state.session.cache.filterRecord, state.session.cache.protocol, opts);
    catch ME
        services.diagnostics.report("Analysis failed", ME);
        state.session.cache.analysis = [];
        state.session.workflow.statusMessage = string(ME.message);
        state.session.workflow.lastAction = "Analysis failed";
        state = services.workflow.log(state, ...
            "Analysis failed: " + state.session.workflow.statusMessage);
        return;
    end
    state.project.results.lastExport = [];
    state.session.workflow.statusMessage = sprintf( ...
        "Analyzed %d recording(s).", ...
        state.session.cache.analysis.analyzedCount);
    state.session.workflow.lastAction = "Analyzed filter record";
    state = services.workflow.log(state, state.session.workflow.statusMessage);
end

function state = onExportAnalysis(state, ~, services)
    if ~hasAnalysis(state)
        state.session.workflow.statusMessage = "Run analysis before exporting.";
        return;
    end
    folder = state.session.workflow.outputFolder;
    if strlength(folder) == 0
        state.session.workflow.statusMessage = "Select an output folder first.";
        return;
    end
    outputName = "nerve_response_analysis.json";
    outputPath = fullfile(char(folder), outputName);
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
    nerve_response_analysis.resultFiles.writeAnalysisJson( ...
        state.session.cache.analysis, outputPath);
    output = services.results.output( ...
        "nerveResponseAnalysis", "primary", outputName, "application/json");
    spec = struct( ...
        "Outputs", output, ...
        "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, ...
        "Summary", analysisSummary(state.session.cache.analysis), ...
        "ManifestName", "nerve_response_analysis.labkit.json");
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.lastExport = struct( ...
        "jsonPath", string(outputPath), ...
        "manifestPath", string(manifestPath));
    state.session.workflow.statusMessage = ...
        "Exported nerve-response analysis.";
    state.session.workflow.lastAction = "Exported analysis";
    state = services.workflow.log(state, ...
        "Exported analysis JSON: " + displayPath(outputPath));
end

function state = onResetWorkflow(~, ~, services)
    state = services.project.newState();
    state = services.workflow.log(state, ...
        "Reset Nerve Response Analysis state.");
end

function opts = analysisOptions(parameters)
    opts = struct();
    if parameters.maxRecordings > 0
        opts.maxRecordings = parameters.maxRecordings;
    end
    if parameters.maxDurationSec > 0
        opts.maxDurationSec = parameters.maxDurationSec;
    end
end

function summary = analysisSummary(analysis)
    summary = struct( ...
        "recordingCount", double(analysis.recordingCount), ...
        "analyzedCount", double(analysis.analyzedCount), ...
        "eventCount", tableHeight(analysis, "events"), ...
        "trainCount", tableHeight(analysis, "trains"), ...
        "metricCount", tableHeight(analysis, "metrics"), ...
        "issueCount", tableHeight(analysis, "issues"));
end

function count = tableHeight(analysis, fieldName)
    count = 0;
    if isfield(analysis, fieldName) && istable(analysis.(fieldName))
        count = height(analysis.(fieldName));
    end
end

function filepath = sourcePath(state, id)
    filepath = labkit.ui.runtime.sourcePaths( ...
        state.project.inputs.sources, id);
end

function protocol = loadOptionalProtocol(filepath)
    try
        protocol = jsondecode(fileread(char(filepath)));
    catch
        protocol = struct();
    end
end

function filepath = firstEventPath(event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    filepath = "";
    if ~isempty(paths)
        filepath = paths(1);
    end
end

function tf = hasAnalysis(state)
    value = state.session.cache.analysis;
    tf = isstruct(value) && isscalar(value) && ~isempty(fieldnames(value));
end

function value = finiteNonnegativeScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
        return;
    end
    value = max(0, value);
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    [~, base, extension] = fileparts(char(pathValue));
    text = string(base) + string(extension);
    if strlength(text) == 0
        text = pathValue;
    end
end
