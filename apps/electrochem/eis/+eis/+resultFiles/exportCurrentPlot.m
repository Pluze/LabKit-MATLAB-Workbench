function state = exportCurrentPlot(state, context)
%EXPORTCURRENTPLOT Write the selected EIS X/Y overlay data.
arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end
indices = state.session.selection.files.Indices;
items = state.session.cache.items;
indices = indices(indices <= numel(items));
p = state.project.parameters;
if p.groupingEnabled
    items = eis.analysisRun.groupItems(items, state.project.inputs.sources, state.project.groups);
else
    items = items(indices);
end
if isempty(items)
    context.alert("No files selected or groups assigned for export.", "Export");
    return
end
chosen = context.chooseOutputFile(["*.csv" "CSV files (*.csv)"], pwd);
if chosen.Cancelled
    return
end
path = string(chosen.Value);
if p.groupingEnabled
    tableValue = eis.resultFiles.buildGroupExportTable(items, p);
else
    tableValue = eis.resultFiles.buildExportTable(items, p.xName, p.yName, ...
        p.impedanceUnit, p.logX, p.logY);
end
writetable(tableValue, path);

context.log("info", "eis.resultfiles.exportcurrentplot.status", ...
    "Exported the current EIS plot data.");
end
