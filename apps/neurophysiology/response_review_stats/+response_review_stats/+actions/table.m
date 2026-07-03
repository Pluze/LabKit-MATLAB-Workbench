% App-owned action table for Response Review Stats. Expected caller is
% response_review_stats.definition. Output maps semantic action ids to
% handlers used by labkit.ui.app.run. Handlers own workflow transitions,
% metric loading, and export side effects.
function actions = table()
    actions = struct( ...
        "startup", @onStartup, ...
        "inputChosen", @onInputChosen, ...
        "inputCleared", @onInputCleared, ...
        "outputFolderChosen", @onOutputFolderChosen, ...
        "outputFolderCleared", @onOutputFolderCleared, ...
        "settingChanged", @onSettingChanged, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "loadMetrics", @onLoadMetrics, ...
        "exportMetrics", @onExportMetrics, ...
        "resetWorkflow", @onResetWorkflow);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if isDebugEnabled(debugLog)
        debugLog.trace("Response Review Stats debug trace enabled.");
        debugLog.instrumentFigure(services.figure);
        state = setupDebugSamples(state, services);
    end
    addLog(services, "Response Review Stats ready.");
end

function state = onInputChosen(state, payload, services)
    paths = eventPaths(payload.event);
    if isempty(paths)
        return;
    end
    state.inputFile = paths(1);
    state.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
        paths, "response_review_stats", state.outputFolder));
    state.statusMessage = "Input selected.";
    state.lastAction = "Selected input";
    addLog(services, "Selected input: " + displayPath(state.inputFile));
    state = loadMetricsFromState(state, "Auto-loaded metrics", services);
end

function state = onInputCleared(state, ~, ~)
    state.inputFile = "";
    state.metrics = table();
    state.summary = table();
    state.aligned = [];
    state.statusMessage = "No input selected.";
    state.lastAction = "Cleared input";
end

function state = onOutputFolderChosen(state, ~, services)
    [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
        "Select metrics output folder", state.outputFolder);
    if cancelled
        state.lastAction = "Output folder selection cancelled";
        return;
    end
    state.outputFolder = string(folder);
    state.lastAction = "Selected output folder";
    addLog(services, "Selected output folder: " + displayPath(state.outputFolder));
end

function state = onOutputFolderCleared(state, ~, ~)
    state.outputFolder = "";
    state.lastAction = "Cleared output folder";
end

function state = onSettingChanged(state, ~, services)
    state.baselineWindowSec = numericScalar(labkit.ui.view.getValue( ...
        services.ui, "baselineWindowSec"), state.baselineWindowSec);
    state.noiseWindowSec = numericScalar(labkit.ui.view.getValue( ...
        services.ui, "noiseWindowSec"), state.noiseWindowSec);
    state.lastAction = "Updated metric windows";
    if strlength(state.inputFile) > 0
        state = loadMetricsFromState(state, ...
            "Refreshed metrics after window change", services);
    end
end

function state = onPreviewModeChanged(state, payload, ~)
    value = eventValue(payload.event);
    if strlength(value) > 0
        state.previewMode = value;
    end
end

function state = onLoadMetrics(state, ~, services)
    state = loadMetricsFromState(state, "Loaded metrics", services);
end

function state = onExportMetrics(state, ~, services)
    if isempty(state.metrics) || height(state.metrics) == 0
        state.statusMessage = "Load metrics before exporting.";
        return;
    end
    if strlength(state.outputFolder) == 0
        state.statusMessage = "Select an output folder first.";
        return;
    end
    outputPath = fullfile(char(state.outputFolder), ...
        "response_review_metrics.csv");
    response_review_stats.export.writeMetricsCsv(state.metrics, outputPath);
    state.statusMessage = "Exported response-review metrics.";
    state.lastAction = "Exported metrics";
    addLog(services, "Exported metrics CSV: " + displayPath(outputPath));
end

function state = onResetWorkflow(~, ~, services)
    state = response_review_stats.state.initial();
    addLog(services, "Reset Response Review Stats state.");
end

function state = setupDebugSamples(state, services)
    debugLog = services.debug;
    try
        pack = response_review_stats.debug.writeSamplePack(debugLog);
        addLog(services, "Debug sample files: " + string(pack.sampleFolder));
        addLog(services, "Debug output folder: " + string(pack.outputFolder));
    catch ME
        debugLog.reportException('responseReviewStats', ...
            'Debug sample setup failed', ME);
        addLog(services, "Debug sample setup failed: " + string(ME.message));
    end
end

function state = loadMetricsFromState(state, actionLabel, services)
    if strlength(state.inputFile) == 0
        state.statusMessage = "Select an analysis JSON or segment CSV first.";
        return;
    end

    try
        [~, ~, ext] = fileparts(char(state.inputFile));
        if strcmpi(ext, ".json")
            payload = jsondecode(fileread(char(state.inputFile)));
            state.metrics = metricsFromAnalysisPayload(payload);
            state.aligned = [];
        else
            T = readtable(char(state.inputFile));
            segments = response_review_stats.io.parseSegmentTable(T);
            opts = struct( ...
                "baselineWindowSec", state.baselineWindowSec, ...
                "noiseWindowSec", state.noiseWindowSec);
            state.aligned = response_review_stats.ops.alignSegments( ...
                segments, opts);
            state.metrics = response_review_stats.ops.measureAlignedSegments( ...
                state.aligned, opts);
        end
    catch ME
        services.debug.reportException('responseReviewStats', ...
            'Metric load failed', ME);
        state.metrics = table();
        state.summary = table();
        state.aligned = [];
        state.statusMessage = string(ME.message);
        state.lastAction = "Metric load failed";
        addLog(services, "Metric load failed: " + state.statusMessage);
        return;
    end
    state.summary = response_review_stats.ops.summarizeMetrics(state.metrics);
    state.statusMessage = sprintf("Loaded %d metric row(s).", ...
        height(state.metrics));
    state.lastAction = string(actionLabel);
    addLog(services, state.statusMessage);
end

function value = numericScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function metrics = metricsFromAnalysisPayload(payload)
    if isfield(payload, "metrics") && isstruct(payload.metrics)
        metrics = struct2table(payload.metrics);
    else
        metrics = table();
    end
    if height(metrics) == 0
        return;
    end
    vars = string(metrics.Properties.VariableNames);
    for k = 1:numel(vars)
        if iscell(metrics.(vars(k)))
            try
                metrics.(vars(k)) = string(metrics.(vars(k)));
            catch
            end
        end
    end
end

function paths = eventPaths(event)
    files = struct([]);
    if isstruct(event) && isfield(event, "addedFiles")
        files = event.addedFiles;
    elseif isobject(event) && isprop(event, "addedFiles")
        files = event.addedFiles;
    elseif isstruct(event) && isfield(event, "selectedFiles")
        files = event.selectedFiles;
    elseif isobject(event) && isprop(event, "selectedFiles")
        files = event.selectedFiles;
    end
    paths = labkit.ui.view.filePaths(files);
    if ~(isstring(paths) && iscolumn(paths))
        error('response_review_stats:InvalidPathEvent', ...
            'filePanel event file paths must be a string column.');
    end
end

function value = eventValue(event)
    value = "";
    if isstruct(event) && isfield(event, "value")
        value = string(event.value);
    elseif isobject(event) && isprop(event, "value")
        value = string(event.value);
    end
    if numel(value) > 1
        value = value(1);
    end
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    [~, base, ext] = fileparts(char(pathValue));
    text = string([base ext]);
    if strlength(text) == 0
        text = pathValue;
    end
end

function addLog(services, message)
    labkit.ui.view.appendLog(services.ui, "logPanel", message);
    if isDebugEnabled(services.debug)
        services.debug.append(message);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
