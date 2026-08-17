function state = export(state, context)
%EXPORT Write the current per-branch modulus estimates as standard CSV.
rows = state.session.analysis.resultRows;
if isempty(rows)
    context.alert("Run modulus analysis before exporting.", ...
        "Export Modulus Results");
    return;
end
choice = context.chooseOutputFile( ...
    ["*.csv", "CSV files"], "mark10_modulus_results.csv");
if choice.Cancelled, return; end
filepath = string(choice.Value);
[folder, stem, extension] = fileparts(filepath);
if lower(string(extension)) ~= ".csv"
    filepath = string(fullfile(folder, string(stem) + ".csv"));
end
resultTable = mark10_monitor.analysis.exportTable( ...
    rows, state.session.analysis);
writetable(resultTable, filepath);
state.session.analysis.exportStatus = "Exported: " + filepath;
end
