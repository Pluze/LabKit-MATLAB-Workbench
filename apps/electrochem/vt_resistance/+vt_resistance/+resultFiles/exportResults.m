function applicationState = exportResults( ...
        applicationState, callbackContext)
%EXPORTRESULTS Write the VT batch CSV.
items = applicationState.session.cache.items;
if isempty(items)
    callbackContext.alert("No results to export.", "Export");
    return
end
choice = callbackContext.chooseOutputFile( ...
    ["*.csv", "CSV files"], "vt_steady_resistance_results.csv");
if choice.Cancelled
    callbackContext.log("info", "vt_resistance.resultfiles.exportresults.status", "VT result export cancelled.");
    return
end
filepath = string(choice.Value);
[ok, message] = vt_resistance.resultFiles.writeResultsCSV(items, filepath);
if ~ok
    callbackContext.alert(message, "Export");
    return
end

callbackContext.log("info", ...
    "vt_resistance.resultfiles.exportresults.status", ...
    "Exported VT results.");
end
