% Expected caller: Runtime V2. Input is a validated Response Review Stats
% project with resolved source. Output owns metrics, aligned signals, summary,
% preview selection, output convenience, and workflow messages.
function session = createSession(project)
    filepath = sourcePath(project.inputs.source);
    [metrics, summary, aligned] = emptyCache();
    outputFolder = "";
    status = "No input selected.";
    if strlength(filepath) > 0
        [metrics, summary, aligned] = ...
            response_review_stats.analysisRun.loadMetrics( ...
            filepath, project.parameters);
        outputFolder = string(labkit.ui.runtime.defaultOutputFolder( ...
            filepath, "response_review_stats", ""));
        status = sprintf("Loaded %d metric row(s).", height(metrics));
    end
    session = struct( ...
        "selection", struct(), ...
        "workflow", struct("statusMessage", status, ...
            "lastAction", "Ready", "logLines", strings(0, 1), ...
            "outputFolder", outputFolder), ...
        "view", struct("previewMode", "Summary"), ...
        "cache", struct("filepath", filepath, "metrics", metrics, ...
            "summary", summary, "aligned", aligned));
end

function [metrics, summary, aligned] = emptyCache()
    metrics = table();
    summary = table();
    aligned = [];
end

function filepath = sourcePath(sources)
    filepath = "";
    if ~isempty(sources)
        filepath = string(sources(1).reference.originalPath);
    end
end
