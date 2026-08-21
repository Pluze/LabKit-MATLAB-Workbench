% App-owned implementation for rhs_preview.resultFiles.saveFilterRecord within the rhs_preview product workflow.
function applicationState = saveFilterRecord( ...
        applicationState, callbackContext)
%SAVEFILTERRECORD Write manual file labels.
rows = applicationState.session.cache.filterRows;
if ~istable(rows) || height(rows) == 0
    applicationState.session.workflow.statusMessage = ...
        "Select RHS filter files before saving a filter record.";
    return;
end
chosen = callbackContext.chooseOutputFile( ...
    ["*.json", "Filter JSON"], "rhs_filter_record.json");
if chosen.Cancelled
    return;
end
[folder, name, extension] = outputParts(chosen.Value);
outputPath = fullfile(folder, name + extension);
model = struct( ...
    "rhsFolder", commonParent(string(rows.filePath)), ...
    "filterRows", rows);
rhs_preview.resultFiles.writeFilterRecordJson(model, outputPath);
applicationState.project.results.lastFilterExport = struct( ...
    "jsonPath", string(outputPath), ...
    "outputPath", string(outputPath));
applicationState.session.workflow.statusMessage = ...
    "Saved filter record.";
applicationState.session.workflow.lastAction = "Saved filter record";
callbackContext.log("info", ...
    "rhs_preview.resultfiles.savefilterrecord.completed", ...
    "Saved the filter record JSON.");
end

function [folder, name, extension] = outputParts(path)
[folder, name, extension] = fileparts(string(path));
folder = string(folder);
name = string(name);
extension = string(extension);
if strlength(folder) == 0
    folder = string(pwd);
end
end

function folder = commonParent(paths)
folder = "";
if ~isempty(paths)
    folder = string(fileparts(char(paths(1))));
end
end
