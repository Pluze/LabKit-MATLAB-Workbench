% App-owned implementation for video_marker.sessionControl.openProject within the video_marker product workflow.
function applicationState = openProject(applicationState, callbackContext)
%OPENPROJECT Restore a Video Marker MAT snapshot through the App contract.
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
    applicationState = video_marker.archive.readFile(filepath, callbackContext);
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
