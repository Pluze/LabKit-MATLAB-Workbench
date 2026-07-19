function state = refreshMetrics(state, context)
if isempty(state.project.inputs.sources)
    state.session.workflow.statusMessage = "Select an analysis JSON or segment CSV first.";
    return;
end
paths = context.resolveSourcePaths(state.project.inputs.sources, "reviewInput");
try
    [metrics, summary, aligned] = response_review_stats.analysisRun.loadMetrics( ...
        paths(1), state.project.parameters);
catch ME
    context.reportError("Metric load", ME);
    state.session.cache.metrics = table();
    state.session.cache.summary = table();
    state.session.cache.aligned = [];
    state.session.workflow.statusMessage = string(ME.message);
    return;
end
state.session.cache.metrics = metrics;
state.session.cache.summary = summary;
state.session.cache.aligned = aligned;
state.session.workflow.statusMessage = sprintf("Loaded %d metric row(s).", height(metrics));
context.appendStatus(state.session.workflow.statusMessage);
end
