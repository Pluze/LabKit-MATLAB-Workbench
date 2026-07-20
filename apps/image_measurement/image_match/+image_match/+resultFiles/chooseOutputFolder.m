function applicationState = chooseOutputFolder( ...
        applicationState, callbackContext)
%CHOOSEOUTPUTFOLDER Select the matched-image batch destination.
choice = callbackContext.chooseOutputFolder( ...
    applicationState.project.parameters.outputFolder);
if choice.Cancelled
    callbackContext.appendStatus("Export folder selection cancelled.");
    return;
end
applicationState.project.parameters.outputFolder = string(choice.Value);
applicationState = ...
    image_match.matchPipeline.invalidateResults(applicationState);
end
