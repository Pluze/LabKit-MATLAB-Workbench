% App-owned implementation for video_marker.sessionControl.openProject within the video_marker product workflow.
function applicationState = openProject(applicationState, callbackContext)
%OPENPROJECT Restore a Video Marker MAT document through the active runtime.
choice = callbackContext.chooseInputFile( ...
    ["*.mat", "LabKit project files"], "");
if choice.Cancelled
    callbackContext.log("info", ...
        "video_marker.sessioncontrol.openproject.cancelled", ...
        "Project open cancelled.");
    return
end
filepath = string(choice.Value);
try
    applicationState = ...
        callbackContext.restoreProjectDocument(filepath);
catch cause
    callbackContext.log("error", "video_marker.sessioncontrol.openproject.exception", "Could not open Video Marker project", ...
        Category="failure", Audience="developer", Exception=cause);
    callbackContext.alert(cause.message, "Could not open project");
    return
end
callbackContext.log("info", ...
    "video_marker.sessioncontrol.openproject.completed", ...
    "Opened a Video Marker project.");
end
