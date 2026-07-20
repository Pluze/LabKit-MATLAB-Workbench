% App-owned implementation for video_marker.sessionControl.saveAutosave within the video_marker product workflow.
function applicationState = saveAutosave(applicationState, callbackContext)
%SAVEAUTOSAVE Write the deterministic source-adjacent autosave document.
videoPath = applicationState.session.cache.videoPath;
if strlength(videoPath) == 0
    callbackContext.appendStatus( ...
        "Autosave unavailable until a video is open.");
    return
end
try
    filepath = video_marker.autosave.filePath(videoPath);
    applicationState.project.inputs.videoMetadata = ...
        video_marker.videoSource.metadataFromInfo( ...
        applicationState.session.cache.videoInfo);
    [folder, ~, ~] = fileparts(filepath);
    if ~isfolder(folder)
        mkdir(folder);
    end
    callbackContext.saveRecoveryDocument(applicationState, filepath);
catch cause
    callbackContext.reportError( ...
        "Could not save Video Marker autosave", cause);
    callbackContext.alert(cause.message, "Could not save autosave");
    callbackContext.appendStatus("Autosave failed: " + cause.message);
    return
end
callbackContext.appendStatus("Autosave updated: " + filepath);
end
