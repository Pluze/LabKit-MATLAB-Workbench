% App-owned implementation for csc.resultFiles.exportResults within the csc product workflow.
function applicationState = exportResults( ...
        applicationState, callbackContext)
%EXPORTRESULTS Write the all-cycle CSC table.
items = applicationState.session.cache.items;
if isempty(items)
    callbackContext.alert("No CSC results to export.", "Export");
    return
end
choice = callbackContext.chooseOutputFile( ...
    ["*.csv", "CSV files"], "csc_all_cycles.csv");
if choice.Cancelled
    callbackContext.log("info", "csc.resultfiles.exportresults.status", "CSC result export cancelled.");
    return
end
filepath = string(choice.Value);
parameters = applicationState.project.parameters;
options = struct( ...
    "mode", char(parameters.mode), ...
    "area_cm2", parameters.area, ...
    "ignoreEdgeCycles", logical(parameters.ignoreEdgeCycles));
[ok, message] = csc.resultFiles.writeResultsCSV( ...
    items, filepath, options);
if ~ok
    callbackContext.alert(message, "Export");
    return
end

applicationState.project.results.lastResultsExport = struct( ...
    "csvPath", filepath, "outputPath", filepath);
callbackContext.log("info", "csc.resultfiles.exportresults.status", ...
    "Exported CSC results.");
end
