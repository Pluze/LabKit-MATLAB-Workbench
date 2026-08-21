% App-owned implementation for response_review_stats.analysisRun.refreshMetrics within the response_review_stats product workflow.
function state = refreshMetrics(state, context)
if isempty(state.project.inputs.sources)
    state.session.workflow.statusMessage = "Select an analysis JSON or segment CSV first.";
    return;
end
sources = state.project.inputs.sources;
roleMatch = string({sources.role}) == "reviewInput";
paths = labkit.app.source.paths(sources(roleMatch));
if isempty(paths)
    state.session.workflow.statusMessage = "Select an analysis JSON or segment CSV first.";
    return;
end
try
    [metrics, summary, aligned] = response_review_stats.analysisRun.loadMetrics( ...
        paths(1), state.project.parameters);
catch ME
    context.log("error", "response_review_stats.analysisrun.refreshmetrics.exception", "Metric load", ...
        Category="failure", Audience="developer", Exception=ME);
    state.session.cache.metrics = table();
    state.session.cache.summary = table();
    state.session.cache.aligned = [];
    state.session.workflow.statusMessage = string(ME.message);
    state.session.workflow.lastAction = "Metric load failed";
    return;
end
state.project.results.lastExport = [];
state.session.cache.filepath = paths(1);
state.session.cache.metrics = metrics;
state.session.cache.summary = summary;
state.session.cache.aligned = aligned;
state.session.workflow.statusMessage = sprintf("Loaded %d metric row(s).", height(metrics));
state.session.workflow.lastAction = "Loaded metrics";
context.log("info", "response_review_stats.analysisrun.refreshmetrics.completed", ...
    state.session.workflow.statusMessage);
end
