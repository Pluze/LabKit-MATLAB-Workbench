% App-owned implementation for dic_postprocess.resultFiles.exportSummary within the dic_postprocess product workflow.
function applicationState = exportSummary( ...
        applicationState, callbackContext)
%EXPORTSUMMARY Write the ROI strain summary CSV.
summary = applicationState.project.results.summaryTable;
if isempty(summary) || height(summary) == 0
    callbackContext.alert( ...
        "Generate a summary before exporting.", "Export summary");
    return;
end
matPath = pathForRole( ...
    applicationState.project.inputs.sources, "strain");
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
applicationState.project.results.summaryOutputPath = ...
    filepath;
callbackContext.log("info", ...
    "dic_postprocess.resultfiles.exportsummary.status", ...
    "Exported the DIC summary.");
end

function filepath = pathForRole(sources, role)
filepath = "";
if isempty(sources)
    return;
end
match = find(string({sources.role}) == role, 1);
if isempty(match)
    return;
end
paths = labkit.app.source.paths(sources(match));
if ~isempty(paths)
    filepath = paths(1);
end
end
