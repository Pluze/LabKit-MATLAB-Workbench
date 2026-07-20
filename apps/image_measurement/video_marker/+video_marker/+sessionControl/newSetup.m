function applicationState = newSetup(applicationState, callbackContext)
%NEWSETUP Clear the current video, skeleton, and annotations after confirmation.
choice = callbackContext.chooseOption( ...
    "Starting a new setup clears the current video, skeleton, and " + ...
    "annotations. Saving the current project first is recommended.", ...
    ["Cancel", "Save and start new", "Discard and start new"], ...
    Title="Start a new setup?", ...
    DefaultChoice="Save and start new", CancelChoice="Cancel");
answer = string(choice.Value);
if choice.Cancelled || answer == "Cancel"
    callbackContext.appendStatus("New setup cancelled.");
    return
end
if answer == "Save and start new"
    destination = callbackContext.chooseOutputFile( ...
        ["*.mat", "LabKit project files"], "video-marker-project.mat");
    if destination.Cancelled
        callbackContext.appendStatus( ...
            "New setup cancelled because project save was cancelled.");
        return
    end
    saved = callbackContext.saveProjectDocument( ...
        applicationState, destination.Value);
    if saved.Cancelled
        callbackContext.appendStatus( ...
            "New setup cancelled because project save was cancelled.");
        return
    end
elseif answer ~= "Discard and start new"
    callbackContext.appendStatus("New setup cancelled.");
    return
end
callbackContext.clearResourceScope("document");
applicationState = callbackContext.newProjectDocument();
callbackContext.appendStatus( ...
    "Started a new skeleton setup and cleared the annotation session.");
end
