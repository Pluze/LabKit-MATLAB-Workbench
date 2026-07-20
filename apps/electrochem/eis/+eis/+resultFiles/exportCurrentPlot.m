% App-owned implementation for eis.resultFiles.exportCurrentPlot within the eis product workflow.
function state = exportCurrentPlot(state, context)
%EXPORTCURRENTPLOT Write the selected EIS X/Y overlay data and result package.
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
tableValue = eis.resultFiles.buildExportTable(items, p.xName, p.yName, p.logX, p.logY);
writetable(tableValue, path);
[folder, base, extension] = fileparts(path);
output = labkit.app.result.File("eisPlotData", "primary", string(base) + string(extension), MediaType="text/csv");
package = labkit.app.result.Package(Outputs={output}, Inputs=struct("sources", state.project.inputs.sources), Parameters=p, Summary=struct("fileCount", numel(items)));
written = context.writeResultPackage(folder, package);
state.project.results.lastExport = struct("csvPath", path, "manifestPath", string(written.Value));
context.appendStatus("Exported CSV: " + path);
end
