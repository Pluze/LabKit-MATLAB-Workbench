% App-owned implementation for ttest_wizard.resultFiles.exportComparisons within the ttest_wizard product workflow.
function state = exportComparisons(state, context)
%EXPORTCOMPARISONS Choose and write a CSV of the latest comparison family.
%
% Expected caller: exportResult button.

arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end

results = state.project.results.current;
if isempty(results)
    context.alert( ...
        "Run comparisons before exporting results.", "Export results");
    return;
end
chosen = context.chooseOutputFile( ...
    ["*.csv", "CSV table (*.csv)"], ...
    fullfile(pwd, "ttest_results.csv"));
if chosen.Cancelled
    return;
end
filepath = ensureCsvExtension(string(chosen.Value));
try
    ttest_wizard.resultFiles.writeResultCsv(filepath, results);
catch ME
    context.reportError("Export t-test results", ME);
    context.alert(ME.message, "Export results");
    return;
end
state.project.results.lastResultExport = filepath;
context.appendStatus("Exported t-test results: " + filepath);
end

function filepath = ensureCsvExtension(filepath)
[folder, name, extension] = fileparts(filepath);
if strlength(string(extension)) == 0
    filepath = string(fullfile(folder, name + ".csv"));
end
end
