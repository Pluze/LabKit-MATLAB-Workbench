% Rebuild transient metrics, aligned signals, preview selection, output-folder
% convenience, and workflow messages from one validated project.
function session = createSession(project, ~)
    filepath = pathForRole( ...
        project.inputs.sources, "reviewInput");
    [metrics, summary, aligned] = emptyCache();
    outputFolder = "";
    status = "No input selected.";
    lastAction = "Ready";
    if strlength(filepath) > 0
        [metrics, summary, aligned] = ...
            response_review_stats.analysisRun.loadMetrics( ...
            filepath, project.parameters);
        outputFolder = defaultOutputFolder(filepath);
        status = sprintf("Loaded %d metric row(s).", height(metrics));
        lastAction = "Auto-loaded metrics";
    end
    session = struct( ...
        "workflow", struct("statusMessage", status, ...
            "lastAction", lastAction, ...
            "outputFolder", outputFolder), ...
        "view", struct("previewMode", "Summary"), ...
        "cache", struct("filepath", filepath, "metrics", metrics, ...
            "summary", summary, "aligned", aligned));
end

function folder = defaultOutputFolder(filepath)
    parent = string(fileparts(filepath));
    folder = string(fullfile(parent, "response_review_stats"));
    if exist(folder, "dir") == 7
        return;
    end
    [created, ~, ~] = mkdir(folder);
    if ~created
        folder = parent;
    end
end

function filepath = pathForRole(sources, role)
    filepath = "";
    if isempty(sources)
        return;
    end
    match = find(string({sources.role}) == role, 1);
    if isempty(match)
        return;
    end
    paths = labkit.app.source.paths(sources(match));
    if ~isempty(paths)
        filepath = paths(1);
    end
end

function [metrics, summary, aligned] = emptyCache()
    metrics = table();
    summary = table();
    aligned = [];
end
