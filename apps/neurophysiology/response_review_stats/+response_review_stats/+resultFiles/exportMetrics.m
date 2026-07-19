function state = exportMetrics(state, context)
%EXPORTMETRICS Write the rebuilt metrics table and its portable manifest.
metrics = state.session.cache.metrics;
if height(metrics) == 0
    context.alert("Load metrics before exporting.", "Export metrics");
    return;
end
folder = state.session.workflow.outputFolder;
if strlength(folder) == 0
    chosen = context.chooseOutputFolder(pwd);
    if chosen.Cancelled
        return;
    end
    folder = string(chosen.Value);
    state.session.workflow.outputFolder = folder;
end
if exist(folder, "dir") ~= 7
    mkdir(folder);
end
name = "response_review_metrics.csv";
path = fullfile(folder, name);
response_review_stats.resultFiles.writeMetricsCsv(metrics, path);
output = labkit.app.result.File("responseReviewMetrics", "primary", name, ...
    MediaType="text/csv");
package = labkit.app.result.Package(Outputs={output}, ...
    Inputs=struct("sources", state.project.inputs.sources), ...
    Parameters=state.project.parameters, ...
    Summary=struct("metricCount", height(metrics), ...
        "groupCount", height(state.session.cache.summary)));
written = context.writeResultPackage(folder, package);
state.project.results.lastExport = struct("csvPath", string(path), ...
    "manifestPath", string(written.Value));
context.appendStatus("Exported metrics: " + string(path));
end
