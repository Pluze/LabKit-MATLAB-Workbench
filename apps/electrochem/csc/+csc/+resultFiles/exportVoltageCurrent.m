% App-owned implementation for csc.resultFiles.exportVoltageCurrent within the csc product workflow.
function applicationState = exportVoltageCurrent( ...
        applicationState, callbackContext)
%EXPORTVOLTAGECURRENT Write column-oriented CV data.
items = applicationState.session.cache.items;
if isempty(items)
    callbackContext.alert( ...
        "No voltage/current data to export.", "Export");
    return
end
choice = callbackContext.chooseOutputFile( ...
    ["*.csv", "CSV files"], "csc_cv_data.csv");
if choice.Cancelled
    callbackContext.log("info", "csc.resultfiles.exportvoltagecurrent.status",  ...
        "Voltage/current export cancelled.");
    return
end
options = struct("ignoreEdgeCycles", logical( ...
    applicationState.project.parameters.ignoreEdgeCycles));
[ok, message, info] = csc.resultFiles.writeVoltageCurrentCSV( ...
    items, string(choice.Value), options);
if ~ok
    callbackContext.alert(message, "Export");
    return
end

applicationState.project.results.lastVoltageCurrentExport = struct( ...
    "csvPaths", string(info.files), ...
    "outputPath", string(info.files(1)));
callbackContext.log("info", "csc.resultfiles.exportvoltagecurrent.status", sprintf( ...
    "Exported %d CV data CSV file(s).", numel(info.files)));
end
