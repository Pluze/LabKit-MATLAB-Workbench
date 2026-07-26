% App-owned implementation for figure_studio.resultFiles.chooseOutputFolder within the figure_studio product workflow.
function state = chooseOutputFolder(state, callbackContext)
%CHOOSEOUTPUTFOLDER Store the package destination selected by the user.
arguments
    state (1, 1) struct
    callbackContext (1, 1) labkit.app.CallbackContext
end
startPath = state.project.parameters.outputFolder;
if strlength(startPath) == 0
    startPath = pwd;
end
chosen = callbackContext.chooseOutputFolder(startPath);
if chosen.Cancelled
    return
end
state.project.parameters.outputFolder = string(chosen.Value);
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
callbackContext.log("info", "figure_studio.resultfiles.chooseoutputfolder.status",  ...
    "Selected the Figure Studio output folder.");
end
