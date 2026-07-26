% App-owned implementation for video_marker.markerEditing.undo within the video_marker product workflow.
function state = undo(state, context)
%UNDO Remove the last point on the active frame.
points = video_marker.markerEditing.currentPoints(state);
if isempty(points)
    return
end
points(end, :) = [];
frame = state.session.cache.frameIndex;
state = video_marker.markerEditing.setPoints(state, points);
context.log("info", "video_marker.markerediting.undo.status", ...
    "Undid the last point on frame " + string(frame) + ".");
end
