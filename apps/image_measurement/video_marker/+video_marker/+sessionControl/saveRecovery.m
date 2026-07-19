function state = saveRecovery(state, context)
%SAVERECOVERY Write the deterministic adjacent recovery document.
videoPath = state.session.cache.videoPath;
if strlength(videoPath) == 0
    context.alert("Open a video before saving recovery state.", "No video");
    return
end
state.project.inputs.videoMetadata = ...
    video_marker.videoSource.metadataFromInfo(state.session.cache.videoInfo);
filepath = video_marker.autosave.filePath(videoPath);
[folder, ~, ~] = fileparts(filepath);
if ~isfolder(folder)
    mkdir(folder);
end
context.saveRecoveryDocument(state, filepath);
context.appendStatus("Recovery state updated: " + filepath);
end
