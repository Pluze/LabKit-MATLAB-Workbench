% App-owned implementation for gait_analysis.resultFiles.exportResults within the gait_analysis product workflow.
function applicationState = exportResults( ...
        applicationState, callbackContext)
%EXPORTRESULTS Write the App-owned gait CSV outputs.
result = applicationState.project.results.analysis;
if ~result.ok
    callbackContext.alert( ...
        "Run gait analysis before exporting CSV files.", "No result");
    return
end
folder = applicationState.session.workflow.outputFolder;
if strlength(folder) == 0
    choice = callbackContext.chooseOutputFolder( ...
        fileparts(applicationState.session.cache.filepath));
    if choice.Cancelled
        callbackContext.log("info", "gait_analysis.resultfiles.exportresults.status", "Gait export cancelled.");
        return
    end
    folder = string(choice.Value);
    applicationState.session.workflow.outputFolder = folder;
end
[~, stem] = fileparts(applicationState.session.cache.filepath);
if strlength(string(stem)) == 0
    stem = "gait_analysis";
end
try
    outputs = gait_analysis.resultFiles.writeOutputs(folder, stem, result);
catch exception
    callbackContext.log("error", "gait_analysis.resultfiles.exportresults.exception", "Gait export failed", ...
        Category="failure", Audience="developer", Exception=exception);
    callbackContext.alert(exception.message, ...
        "Could not export gait CSV files");
    return
end
applicationState.project.results.lastExport = struct( ...
    "outputs", outputs, "outputPath", outputs.summaryCsv);
callbackContext.log("info", "gait_analysis.resultfiles.exportresults.status",  ...
    "Exported the gait CSV set.");
end
