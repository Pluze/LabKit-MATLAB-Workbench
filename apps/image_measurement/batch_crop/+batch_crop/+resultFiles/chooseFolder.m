% App-owned implementation for batch_crop.resultFiles.chooseFolder within the batch_crop product workflow.
function applicationState = chooseFolder(applicationState, callbackContext)
choice = callbackContext.chooseOutputFolder( ...
    applicationState.project.parameters.outputFolder);
if choice.Cancelled
    callbackContext.log("info", "batch_crop.resultfiles.choosefolder.cancelled", ...
        "Export folder selection cancelled.");
    return
end
applicationState.project.parameters.outputFolder = string(choice.Value);
applicationState.project.results = ...
    batch_crop.resultFiles.clearExportState(applicationState.project.results);
end
