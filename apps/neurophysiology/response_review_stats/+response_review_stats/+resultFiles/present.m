% App-owned implementation for response_review_stats.resultFiles.present within the response_review_stats product workflow.
function view = present(state, model)
folder = state.session.workflow.outputFolder;
text = "No output folder selected";
if strlength(folder) > 0
    text = folder;
end
view = labkit.app.view.Snapshot() ...
    .text("outputFolder", text) ...
    .enabled("exportMetrics", ...
        height(model.metrics) > 0 && strlength(folder) > 0);
end
