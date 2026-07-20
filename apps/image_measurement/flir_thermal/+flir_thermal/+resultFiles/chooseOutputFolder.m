function applicationState = chooseOutputFolder( ...
        applicationState, callbackContext)
%CHOOSEOUTPUTFOLDER Select the durable FLIR export destination.
choice = callbackContext.chooseOutputFolder( ...
    applicationState.project.parameters.outputFolder);
if choice.Cancelled
    callbackContext.appendStatus("FLIR output-folder selection cancelled.");
    return
end
applicationState.project.parameters.outputFolder = string(choice.Value);
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
callbackContext.appendStatus( ...
    "FLIR output folder: " + string(choice.Value));
end
