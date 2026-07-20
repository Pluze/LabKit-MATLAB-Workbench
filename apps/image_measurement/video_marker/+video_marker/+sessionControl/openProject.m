function applicationState = openProject(applicationState, callbackContext)
%OPENPROJECT Restore a Video Marker MAT document through the active runtime.
choice = callbackContext.chooseInputFile( ...
    ["*.mat", "LabKit project files"], "");
if choice.Cancelled
    callbackContext.appendStatus("Project open cancelled.");
    return
end
filepath = string(choice.Value);
try
    applicationState = ...
        callbackContext.restoreProjectDocument(filepath);
catch cause
    callbackContext.reportError("Could not open Video Marker project", cause);
    callbackContext.alert(cause.message, "Could not open project");
    return
end
callbackContext.appendStatus("Opened project: " + filepath);
end
