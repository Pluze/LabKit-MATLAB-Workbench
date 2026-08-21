% App-owned implementation for cic.resultFiles.exportResults within the cic product workflow.
function applicationState = exportResults( ...
        applicationState, callbackContext)
%EXPORTRESULTS Write the loaded CIC batch CSV.
items = applicationState.session.cache.items;
if isempty(items)
    callbackContext.alert("No CIC results to export.", "Export");
    return
end

choice = callbackContext.chooseOutputFile( ...
    ["*.csv", "CSV files"], "cic_results.csv");
if choice.Cancelled
    callbackContext.log("info", "cic.resultfiles.exportresults.status", "CIC result export cancelled.");
    return
end
filepath = string(choice.Value);
[~, unitLabel] = cic.analysisRun.displayUnit( ...
    applicationState.project.parameters.cicUnit);
[ok, message] = cic.resultFiles.writeResultsCSV( ...
    items, filepath, unitLabel);
if ~ok
    callbackContext.alert(message, "Export");
    return
end

applicationState.project.results.lastExport = struct( ...
    "csvPath", filepath, "outputPath", filepath);
callbackContext.log("info", "cic.resultfiles.exportresults.status", ...
    "Exported CIC results.");
end
