% Expected caller: labkit_ResponseReviewStats_app. Input is a debug context
% prepared by labkit.ui.app.dispatchRequest. Output is the app figure. Side
% effects are GUI creation, input CSV/JSON reads, optional CSV export, and
% debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the Response Review Stats app.

    S = defaultState();
    callbacks = struct( ...
        "inputChosen", @onInputChosen, ...
        "inputCleared", @onInputCleared, ...
        "outputFolderChosen", @(~, ~) onOutputFolderChosen(), ...
        "outputFolderCleared", @(~, ~) onOutputFolderCleared(), ...
        "settingChanged", @onSettingChanged, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "loadMetrics", @onLoadMetrics, ...
        "exportMetrics", @onExportMetrics, ...
        "resetWorkflow", @onResetWorkflow);

    spec = response_review_stats.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, "debug", debugLog);
    fig = ui.figure;

    if debugLog.enabled
        debugLog.trace("Response Review Stats debug trace enabled.");
        debugLog.instrumentFigure(fig);
    end

    refreshAll();
    addLog("Response Review Stats ready.");

    function onInputChosen(~, event)
        paths = eventPaths(event);
        if isempty(paths)
            return;
        end
        S.inputFile = paths(1);
        S.outputFolder = string(labkit.ui.app.defaultOutputFolder( ...
            paths, "response_review_stats", S.outputFolder));
        S.statusMessage = "Input selected.";
        S.lastAction = "Selected input";
        addLog("Selected input: " + displayPath(S.inputFile));
        loadMetricsFromState("Auto-loaded metrics");
        refreshAll();
    end

    function onInputCleared(~, ~)
        S.inputFile = "";
        S.metrics = table();
        S.summary = table();
        S.aligned = [];
        S.statusMessage = "No input selected.";
        S.lastAction = "Cleared input";
        refreshAll();
    end

    function onOutputFolderChosen()
        [folder, cancelled] = labkit.ui.app.promptOutputFolder( ...
            "Select metrics output folder", S.outputFolder);
        if cancelled
            S.lastAction = "Output folder selection cancelled";
            refreshAll();
            return;
        end
        S.outputFolder = string(folder);
        S.lastAction = "Selected output folder";
        refreshAll();
    end

    function onOutputFolderCleared()
        S.outputFolder = "";
        S.lastAction = "Cleared output folder";
        refreshAll();
    end

    function onSettingChanged(~, ~)
        S.baselineWindowSec = numericScalar(labkit.ui.view.getValue(ui, ...
            "baselineWindowSec"), S.baselineWindowSec);
        S.noiseWindowSec = numericScalar(labkit.ui.view.getValue(ui, ...
            "noiseWindowSec"), S.noiseWindowSec);
        S.lastAction = "Updated metric windows";
        if strlength(S.inputFile) > 0
            loadMetricsFromState("Refreshed metrics after window change");
        end
        refreshAll();
    end

    function onPreviewModeChanged(~, event)
        value = eventValue(event);
        if strlength(value) > 0
            S.previewMode = value;
        end
        refreshAll();
    end

    function onLoadMetrics(~, ~)
        loadMetricsFromState("Loaded metrics");
        refreshAll();
    end

    function onExportMetrics(~, ~)
        if isempty(S.metrics) || height(S.metrics) == 0
            S.statusMessage = "Load metrics before exporting.";
            refreshAll();
            return;
        end
        if strlength(S.outputFolder) == 0
            S.statusMessage = "Select an output folder first.";
            refreshAll();
            return;
        end
        outputPath = fullfile(char(S.outputFolder), ...
            "response_review_metrics.csv");
        response_review_stats.export.writeMetricsCsv(S.metrics, outputPath);
        S.statusMessage = "Exported response-review metrics.";
        S.lastAction = "Exported metrics";
        addLog("Exported metrics CSV: " + displayPath(outputPath));
        refreshAll();
    end

    function onResetWorkflow(~, ~)
        S = defaultState();
        labkit.ui.view.setValue(ui, "baselineWindowSec", S.baselineWindowSec);
        labkit.ui.view.setValue(ui, "noiseWindowSec", S.noiseWindowSec);
        addLog("Reset Response Review Stats state.");
        refreshAll();
    end

    function refreshAll()
        labkit.ui.view.setValue(ui, "inputFile", fileValue(S.inputFile));
        labkit.ui.view.setValue(ui, "outputFolder", char(outputFolderText(S.outputFolder)));
        labkit.ui.view.setEnabled(ui, "loadMetrics", strlength(S.inputFile) > 0);
        labkit.ui.view.setEnabled(ui, "exportMetrics", ...
            istable(S.metrics) && height(S.metrics) > 0 && ...
            strlength(S.outputFolder) > 0);
        labkit.ui.view.setValue(ui, "statusField", char(S.statusMessage));
        ui.controls.summaryTable.table.Data = ...
            response_review_stats.view.summaryTableData(S);
        ui.controls.details.textArea.Value = response_review_stats.view.detailLines(S);
        refreshPreview();
    end

    function refreshPreview()
        response_review_stats.view.drawStatsPreview( ...
            ui.controls.preview.primaryAxes, S);
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, "logPanel", message);
        debugLog.append(message);
    end

    function ok = loadMetricsFromState(actionLabel)
        ok = false;
        if strlength(S.inputFile) == 0
            S.statusMessage = "Select an analysis JSON or segment CSV first.";
            return;
        end

        try
            [~, ~, ext] = fileparts(char(S.inputFile));
            if strcmpi(ext, ".json")
                payload = jsondecode(fileread(char(S.inputFile)));
                S.metrics = metricsFromAnalysisPayload(payload);
                S.aligned = [];
            else
                T = readtable(char(S.inputFile));
                segments = response_review_stats.io.parseSegmentTable(T);
                opts = struct( ...
                    "baselineWindowSec", S.baselineWindowSec, ...
                    "noiseWindowSec", S.noiseWindowSec);
                S.aligned = response_review_stats.ops.alignSegments(segments, opts);
                S.metrics = response_review_stats.ops.measureAlignedSegments( ...
                    S.aligned, opts);
            end
        catch ME
            debugLog.reportException('responseReviewStats', 'Metric load failed', ME);
            S.metrics = table();
            S.summary = table();
            S.aligned = [];
            S.statusMessage = string(ME.message);
            S.lastAction = "Metric load failed";
            addLog("Metric load failed: " + S.statusMessage);
            return;
        end
        S.summary = response_review_stats.ops.summarizeMetrics(S.metrics);
        S.statusMessage = sprintf("Loaded %d metric row(s).", height(S.metrics));
        S.lastAction = string(actionLabel);
        addLog(S.statusMessage);
        ok = true;
    end
end

function value = numericScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function S = defaultState()
    S = struct( ...
        "inputFile", "", ...
        "outputFolder", "", ...
        "baselineWindowSec", [0.007 0.009], ...
        "noiseWindowSec", [0.007 0.009], ...
        "previewMode", "Summary", ...
        "metrics", table(), ...
        "summary", table(), ...
        "aligned", [], ...
        "statusMessage", "No input selected.", ...
        "lastAction", "Ready");
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

function items = fileValue(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        items = strings(0, 1);
        return;
    end
    items = pathValue;
end

function text = outputFolderText(pathValue)
    pathValue = string(pathValue);
    if strlength(pathValue) == 0
        text = "No output folder selected";
        return;
    end
    text = pathValue;
end

function text = displayPath(pathValue)
    pathValue = string(pathValue);
    [~, base, ext] = fileparts(char(pathValue));
    text = string([base ext]);
    if strlength(text) == 0
        text = pathValue;
    end
end
