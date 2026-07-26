% App-owned implementation for response_review_stats.resultFiles.exportMetrics within the response_review_stats product workflow.
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
        "groupCount", height(state.session.cache.summary)), ...
    ManifestName="response_review_metrics.labkit.json");
written = context.writeResultPackage(folder, package);
state.project.results.lastExport = struct("csvPath", string(path), ...
    "manifestPath", string(written.Value));
state.session.workflow.statusMessage = "Exported response-review metrics.";
state.session.workflow.lastAction = "Exported metrics";
context.log("info", "response_review_stats.resultfiles.exportmetrics.completed", ...
    "Exported the response-review metrics.");
end
