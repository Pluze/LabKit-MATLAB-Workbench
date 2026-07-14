%OPENREFERENCEDVIDEO Open a project's video and offer relinking if missing.
% Expected caller: interactive project open. Existing annotations and skeleton
% state are preserved. Cancelled relinking returns OPENED false without error.
function [reader, state, opened] = openReferencedVideo(state, projectPath)
    videoPath = string(state.videoPath);
    if strlength(videoPath) == 0 || exist(videoPath, 'file') ~= 2
        if isfield(state, 'videoReference')
            reference = state.videoReference;
        else
            reference = labkit.ui.runtime.createPortableFileReference( ...
                projectPath, videoPath);
        end
        [videoPath, resolution] = ...
            labkit.ui.runtime.resolveOrPromptForFileReference( ...
            string(projectPath), reference, ...
            'Filter', {'*.mp4;*.avi;*.mov;*.m4v', 'Video files'}, ...
            'DialogTitle', "Locate project source", ...
            'ReferenceLabel', "source video");
        if resolution.cancelled || strlength(videoPath) == 0
            reader = [];
            opened = false;
            return;
        end
    end
    [reader, state.videoInfo] = video_marker.videoSource.openVideo(videoPath);
    state.videoPath = videoPath;
    state.videoInfo.path = videoPath;
    state.currentFrame = min(max(1, state.currentFrame), state.videoInfo.frameCount);
    state.currentImage = video_marker.videoSource.readFrame(reader, state.currentFrame);
    opened = true;
end
