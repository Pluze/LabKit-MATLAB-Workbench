function state = changePoints(state, points, context)
%CHANGEPOINTS Persist all keypoint slots for the active video frame.
if state.session.cache.videoInfo.frameCount <= 0
    return
end
if isstruct(points) && isscalar(points) && isfield(points, "points")
    points = points.points;
end
points = double(points);
if isempty(points)
    points = zeros(0, 2);
elseif size(points, 2) ~= 2
    return
end
points = points(all(isfinite(points), 2), :);
total = numel(state.project.annotations.skeleton.pointIds);
points = points(1:min(size(points, 1), total), :);
status = "draft";
if isempty(points)
    status = "empty";
elseif size(points, 1) == total
    status = "confirmed";
end
frame = state.session.cache.frameIndex;
state.project.annotations.frames = ...
    video_marker.frameAnnotations.setFramePoints( ...
    state.project.annotations.frames, frame, points, status, ...
    "manual", ones(size(points, 1), 1));
state = video_marker.resultFiles.clearExportState(state);
context.appendStatus("Frame " + string(frame) + " points: " + ...
    string(size(points, 1)) + " / " + string(total) + ".");
end
