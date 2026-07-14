%RESTORESESSION Rehydrate saved state against its current source video.
% Expected caller: definitionActions recovery flow. Returns a transient reader
% and serializable state with the current frame image restored and validated.
function [reader, state] = restoreSession(saved, videoPath)
    [reader, info] = video_marker.videoSource.openVideo(videoPath);
    if size(saved.annotations.coords, 1) ~= info.frameCount || ...
            size(saved.annotations.coords, 2) ~= numel(saved.skeleton.pointIds)
        error('labkit_VideoMarker_app:AutosaveShapeMismatch', ...
            'Recovery annotation dimensions no longer match the selected video and skeleton.');
    end
    state = saved;
    state.videoInfo = info;
    state.selectedPointIndex = 0;
    state.selectedEdgeIndex = 0;
    state.currentFrame = min(max(1, state.currentFrame), info.frameCount);
    state.currentImage = video_marker.videoSource.readFrame(reader, state.currentFrame);
end
