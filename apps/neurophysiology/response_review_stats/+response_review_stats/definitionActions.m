% App-owned Runtime V2 actions for Response Review Stats. Handlers own source
% selection, cache rebuild, preview selection, and export without direct UI or
% lifecycle plumbing.
function actions = definitionActions()
    actions = struct( ...
        "inputChosen", @onInputChosen, ...
        "outputFolderChosen", @onOutputFolderChosen, ...
        "outputFolderCleared", @onOutputFolderCleared, ...
        "settingChanged", @onSettingChanged, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "loadMetrics", @onLoadMetrics, ...
        "exportMetrics", @onExportMetrics, ...
        "resetWorkflow", @onResetWorkflow);
end

function state = onInputChosen(state, event, services)
    filepath = firstEventPath(event, services);
    if strlength(filepath) == 0
        return;
    end
    state.project.inputs.sources = services.project.sourceRecord( ...
        "reviewInput", "reviewInput", filepath, true);
    state.project.results.lastExport = [];
    state.session.cache.filepath = filepath;
    state.session.workflow.outputFolder = string( ...
        services.dialogs.defaultOutputFolder(filepath, ...
        "response_review_stats", state.session.workflow.outputFolder));
    state.session.workflow.lastAction = "Selected input";
    state = services.workflow.log(state, ...
        "Selected input: " + displayPath(filepath));
    state = rebuildMetrics(state, "Auto-loaded metrics", services);
end

function state = onOutputFolderChosen(state, ~, services)
    [folder, cancelled] = services.dialogs.outputFolder( ...
        "Select metrics output folder", state.session.workflow.outputFolder);
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

function state = onSettingChanged(state, ~, services)
    state.project.parameters.baselineWindowSec = validRange( ...
        state.project.parameters.baselineWindowSec, [0.007 0.009]);
    state.project.parameters.noiseWindowSec = validRange( ...
        state.project.parameters.noiseWindowSec, [0.007 0.009]);
    state.project.results.lastExport = [];
    if ~isempty(state.project.inputs.sources)
        state = rebuildMetrics(state, ...
            "Refreshed metrics after window change", services);
    end
end

function state = onPreviewModeChanged(state, event, ~)
    value = string(event.value);
    if isscalar(value) && any(value == ["Summary", "Aligned"])
        state.session.view.previewMode = value;
    end
end

function state = onLoadMetrics(state, ~, services)
    state = rebuildMetrics(state, "Loaded metrics", services);
end

function state = rebuildMetrics(state, actionLabel, services)
    if isempty(state.project.inputs.sources)
        state.session.workflow.statusMessage = ...
            "Select an analysis JSON or segment CSV first.";
        return;
    end
    try
        [metrics, summary, aligned] = ...
            response_review_stats.analysisRun.loadMetrics( ...
            state.session.cache.filepath, state.project.parameters);
    catch ME
        services.diagnostics.report("Metric load failed", ME);
        state.session.cache.metrics = table();
        state.session.cache.summary = table();
        state.session.cache.aligned = [];
        state.session.workflow.statusMessage = string(ME.message);
        state.session.workflow.lastAction = "Metric load failed";
        state = services.workflow.log(state, ...
            "Metric load failed: " + state.session.workflow.statusMessage);
        return;
    end
    state.session.cache.metrics = metrics;
    state.session.cache.summary = summary;
    state.session.cache.aligned = aligned;
    state.session.workflow.statusMessage = sprintf( ...
        "Loaded %d metric row(s).", height(metrics));
    state.session.workflow.lastAction = string(actionLabel);
    state = services.workflow.log(state, state.session.workflow.statusMessage);
end

function state = onExportMetrics(state, ~, services)
    metrics = state.session.cache.metrics;
    if height(metrics) == 0
        state.session.workflow.statusMessage = "Load metrics before exporting.";
        return;
    end
    folder = state.session.workflow.outputFolder;
    if strlength(folder) == 0
        state.session.workflow.statusMessage = "Select an output folder first.";
        return;
    end
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
    outputName = "response_review_metrics.csv";
    outputPath = fullfile(char(folder), outputName);
    response_review_stats.resultFiles.writeMetricsCsv(metrics, outputPath);
    output = services.results.output( ...
        "responseReviewMetrics", "primary", outputName, "text/csv");
    spec = struct( ...
        "Outputs", output, "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, ...
        "Summary", struct("metricCount", height(metrics), ...
        "groupCount", height(state.session.cache.summary)), ...
        "ManifestName", "response_review_metrics.labkit.json");
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
    state.project.results.lastExport = struct( ...
        "csvPath", string(outputPath), ...
        "manifestPath", string(manifestPath));
    state.session.workflow.statusMessage = "Exported response-review metrics.";
    state.session.workflow.lastAction = "Exported metrics";
    state = services.workflow.log(state, ...
        "Exported metrics CSV: " + displayPath(outputPath));
end

function state = onResetWorkflow(~, ~, services)
    spec = response_review_stats.projectSpec();
    project = spec.Create();
    state = struct("project", project, ...
        "session", response_review_stats.createSession(project));
    state = services.workflow.log(state, ...
        "Reset Response Review Stats state.");
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

function value = validRange(value, fallback)
    value = double(value);
    if ~isequal(size(value), [1 2]) || any(~isfinite(value))
        value = fallback;
    end
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    [~, base, extension] = fileparts(char(pathValue));
    text = string(base) + string(extension);
    if strlength(text) == 0
        text = pathValue;
    end
end
