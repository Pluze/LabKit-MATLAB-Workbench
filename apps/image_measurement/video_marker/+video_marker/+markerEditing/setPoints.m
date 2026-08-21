% App-owned implementation for video_marker.markerEditing.setPoints within the video_marker product workflow.
function applicationState = setPoints(applicationState, points, ~)
%SETPOINTS Store one frame's ordered points in the current App state.
total = numel(applicationState.project.annotations.skeleton.pointIds);
status = "draft";
if isempty(points)
    status = "empty";
elseif size(points, 1) == total
    status = "confirmed";
end
frame = applicationState.session.cache.frameIndex;
applicationState.project.annotations.frames = ...
    video_marker.frameAnnotations.setFramePoints( ...
        applicationState.project.annotations.frames, frame, points, status, ...
        "manual", ones(size(points, 1), 1));
applicationState = ...
    video_marker.resultFiles.clearExportState(applicationState);
end
