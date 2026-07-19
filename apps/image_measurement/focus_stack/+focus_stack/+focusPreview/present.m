function view = present(state)
%PRESENT Build the Focus Stack result summary and paired preview model.
result = state.session.cache.result;
view = labkit.app.view.Snapshot();
view = view.enabled("exportFused", result.ok);
view = view.enabled("exportFocusMap", result.ok);
view = view.enabled("exportSummary", result.ok);
if result.ok
    data = {"Images fused", result.inputCount; "Method", char(result.method)};
    details = "Focus stack result is ready for export.";
else
    data = {"Images loaded", numel(state.session.cache.images); "Status", "Awaiting run"};
    details = "Load at least two images, then run focus stacking.";
end
view = view.tableData("resultTable", data, Columns=["Metric" "Value"]);
view = view.text("details", details);
view = view.renderPlot("preview", struct( ...
    "images", {state.session.cache.images}, "result", result));
end
