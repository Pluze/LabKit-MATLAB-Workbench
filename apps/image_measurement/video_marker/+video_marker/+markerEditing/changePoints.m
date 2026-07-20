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
frame = state.session.cache.frameIndex;
state = video_marker.markerEditing.setPoints(state, points);
context.appendStatus("Frame " + string(frame) + " points: " + ...
    string(size(points, 1)) + " / " + string(total) + ".");
end
