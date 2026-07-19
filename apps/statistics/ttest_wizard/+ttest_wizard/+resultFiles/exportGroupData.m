function state = exportGroupData(state, context)
%EXPORTGROUPDATA Choose and write a portable CSV of current group values.
%
% Expected caller: exportData button.

arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end

groups = state.project.inputs.groups;
if isempty(groups)
    context.alert("Enter group data before exporting.", "Export data");
    return;
end
chosen = context.chooseOutputFile( ...
    ["*.csv", "CSV table (*.csv)"], ...
    fullfile(pwd, "ttest_group_data.csv"));
if chosen.Cancelled
    return;
end
filepath = ensureCsvExtension(string(chosen.Value));
try
    ttest_wizard.sourceTable.writeGroupCsv(filepath, groups);
catch ME
    context.reportError("Export group data", ME);
    context.alert(ME.message, "Export data");
    return;
end
state.project.results.lastDataExport = filepath;
context.appendStatus("Exported group data: " + filepath);
end

function filepath = ensureCsvExtension(filepath)
[folder, name, extension] = fileparts(filepath);
if strlength(string(extension)) == 0
    filepath = string(fullfile(folder, name + ".csv"));
end
end
