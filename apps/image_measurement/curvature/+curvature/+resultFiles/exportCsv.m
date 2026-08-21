% App-owned implementation for curvature.resultFiles.exportCsv within the curvature product workflow.
function applicationState = exportCsv( ...
        applicationState, callbackContext)
%EXPORTCSV Write curvature measurements.
fit = applicationState.project.results.fit;
lengthResult = applicationState.project.results.length;
if ~fit.ok && ~lengthResult.ok
    callbackContext.alert( ...
        "Fit curvature or measure curve length before exporting.", ...
        "No measurement result");
    return
end
choice = callbackContext.chooseOutputFile( ...
    ["*.csv", "CSV files (*.csv)"], ...
    defaultOutputPath(applicationState, "curvature_result.csv"));
if choice.Cancelled
    callbackContext.log("info", "curvature.resultfiles.exportcsv.cancelled", ...
        "Result CSV export cancelled.");
    return
end
filepath = string(choice.Value);
try
    resultTable = curvature.resultFiles.buildResultTable( ...
        fit, applicationState.session.cache.imagePath, lengthResult);
    writetable(resultTable, filepath);
catch ME
    callbackContext.log("error", "curvature.resultfiles.exportcsv.exception", "Export Curvature result CSV", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not export result CSV");
    return
end
applicationState.project.results.lastCsvExport = struct( ...
    "csvPath", filepath, "outputPath", filepath);
callbackContext.log("info", "curvature.resultfiles.exportcsv.completed", ...
    "Exported the result CSV.");
end

function filepath = defaultOutputPath(applicationState, filename)
folder = string(fileparts(applicationState.session.cache.imagePath));
if strlength(folder) == 0 || ~isfolder(folder)
    folder = string(pwd);
end
filepath = string(fullfile(folder, filename));
end
