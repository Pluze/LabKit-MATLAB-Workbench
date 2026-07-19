% Rebuild transient metrics, aligned signals, preview selection, output-folder
% convenience, and workflow messages from one validated project.
function session = createSession(project, context)
    paths = context.resolveSourcePaths(project.inputs.sources, "reviewInput");
    filepath = paths(1);
    [metrics, summary, aligned] = emptyCache();
    outputFolder = "";
    status = "No input selected.";
    if strlength(filepath) > 0
        [metrics, summary, aligned] = ...
            response_review_stats.analysisRun.loadMetrics( ...
            filepath, project.parameters);
        outputFolder = string(fileparts(filepath));
        status = sprintf("Loaded %d metric row(s).", height(metrics));
    end
    session = struct( ...
        "workflow", struct("statusMessage", status, ...
            "lastAction", "Ready", ...
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
