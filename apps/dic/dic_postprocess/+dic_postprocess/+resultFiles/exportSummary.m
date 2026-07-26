% App-owned implementation for dic_postprocess.resultFiles.exportSummary within the dic_postprocess product workflow.
function applicationState = exportSummary( ...
        applicationState, callbackContext)
%EXPORTSUMMARY Write the ROI strain summary CSV and result manifest.
summary = applicationState.project.results.summaryTable;
if isempty(summary) || height(summary) == 0
    callbackContext.alert( ...
        "Generate a summary before exporting.", "Export summary");
    return;
end
matPath = pathForRole( ...
    applicationState.project.inputs.sources, "strain", callbackContext);
[folder, name] = fileparts(matPath);
defaultName = fullfile(folder, name + "_strain_summary.csv");
choice = callbackContext.chooseOutputFile( ...
    ["*.csv", "CSV files (*.csv)"], defaultName);
if choice.Cancelled
    callbackContext.log("info", "dic_postprocess.resultfiles.exportsummary.status", "Export summary cancelled.");
    return;
end
filepath = string(choice.Value);
writetable(summary, filepath);
[folder, name, extension] = fileparts(filepath);
outputName = string(name) + string(extension);
output = labkit.app.result.File( ...
    "strainSummary", "primary", outputName, MediaType="text/csv");
package = labkit.app.result.Package( ...
    Outputs={output}, ...
    Inputs=struct("sources", applicationState.project.inputs.sources), ...
    Parameters=applicationState.project.parameters, ...
    Summary=struct("metricCount", height(summary)), ...
    ManifestName=string(name) + ".labkit.json");
written = callbackContext.writeResultPackage(folder, package);
applicationState.project.results.summaryManifestPath = ...
    string(written.Value);
callbackContext.log("info", ...
    "dic_postprocess.resultfiles.exportsummary.status", ...
    "Exported the DIC summary.");
end

function filepath = pathForRole(sources, role, context)
filepath = "";
if isempty(sources)
    return;
end
match = find(string({sources.role}) == role, 1);
if isempty(match)
    return;
end
paths = context.resolveSourcePaths(sources(match));
if ~isempty(paths)
    filepath = paths(1);
end
end
