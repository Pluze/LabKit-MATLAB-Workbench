% App-owned implementation for eis.resultFiles.exportCurrentPlot within the eis product workflow.
function state = exportCurrentPlot(state, context)
%EXPORTCURRENTPLOT Write the selected EIS X/Y overlay data.
arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end
indices = state.session.selection.files.Indices;
items = state.session.cache.items;
indices = indices(indices <= numel(items));
items = items(indices);
if isempty(items)
    context.alert("No files selected for export.", "Export");
    return
end
chosen = context.chooseOutputFile(["*.csv" "CSV files (*.csv)"], pwd);
if chosen.Cancelled
    return
end
path = string(chosen.Value);
p = state.project.parameters;
tableValue = eis.resultFiles.buildExportTable(items, p.xName, p.yName, ...
    p.impedanceUnit, p.logX, p.logY);
writetable(tableValue, path);
state.project.results.lastExport = struct("csvPath", path, "outputPath", path);
context.log("info", "eis.resultfiles.exportcurrentplot.status", ...
    "Exported the current EIS plot data.");
end
