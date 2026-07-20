% App-owned implementation for vt_resistance.resultFiles.exportResults within the vt_resistance product workflow.
function applicationState = exportResults( ...
        applicationState, callbackContext)
%EXPORTRESULTS Write the VT batch CSV and provenance manifest.
items = applicationState.session.cache.items;
if isempty(items)
    callbackContext.alert("No results to export.", "Export");
    return
end
choice = callbackContext.chooseOutputFile( ...
    ["*.csv", "CSV files"], "vt_steady_resistance_results.csv");
if choice.Cancelled
    callbackContext.appendStatus("VT result export cancelled.");
    return
end
filepath = string(choice.Value);
[ok, message] = vt_resistance.resultFiles.writeResultsCSV(items, filepath);
if ~ok
    callbackContext.alert(message, "Export");
    return
end
[folder, name, extension] = fileparts(filepath);
output = labkit.app.result.File("vtResistanceResults", "primary", ...
    string(name) + string(extension), MediaType="text/csv");
package = labkit.app.result.Package( ...
    Outputs={output}, ...
    Inputs=struct("sources", applicationState.project.inputs.sources), ...
    Parameters=applicationState.project.parameters, ...
    Summary=struct("fileCount", numel(items)), ...
    ManifestName="vt_steady_resistance_results.labkit.json");
written = callbackContext.writeResultPackage(folder, package);
applicationState.project.results.lastExport = struct( ...
    "csvPath", filepath, "manifestPath", string(written.Value));
callbackContext.appendStatus("Exported VT CSV: " + filepath);
end
