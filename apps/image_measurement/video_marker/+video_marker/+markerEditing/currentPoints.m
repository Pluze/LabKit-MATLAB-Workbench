% App-owned implementation for video_marker.markerEditing.currentPoints within the video_marker product workflow.
function points = currentPoints(state)
%CURRENTPOINTS Return finite placed points for the active frame.
points = zeros(0, 2);
frames = state.project.annotations.frames;
index = state.session.cache.frameIndex;
if ~isempty(frames.coords) && index >= 1 && index <= size(frames.coords, 1)
    points = video_marker.frameAnnotations.framePoints(frames, index);
end
end
