function applicationState = chooseFolder(applicationState, callbackContext)
choice = callbackContext.chooseOutputFolder( ...
    applicationState.project.parameters.outputFolder);
if choice.Cancelled
    callbackContext.appendStatus("Export folder selection cancelled.");
    return
end
applicationState.project.parameters.outputFolder = string(choice.Value);
applicationState.project.results = ...
    batch_crop.resultFiles.clearExportState(applicationState.project.results);
end
